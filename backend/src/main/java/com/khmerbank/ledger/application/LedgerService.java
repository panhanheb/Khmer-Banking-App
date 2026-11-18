package com.khmerbank.ledger.application;

import com.khmerbank.account.domain.AccountBalance;
import com.khmerbank.account.domain.AccountStatus;
import com.khmerbank.account.domain.BankAccount;
import com.khmerbank.account.infrastructure.AccountBalanceRepository;
import com.khmerbank.account.infrastructure.BankAccountRepository;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.ledger.domain.LedgerTransaction;
import com.khmerbank.ledger.domain.Posting;
import com.khmerbank.ledger.domain.TransactionEntry;
import com.khmerbank.ledger.infrastructure.LedgerTransactionRepository;
import com.khmerbank.ledger.infrastructure.TransactionEntryRepository;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.UUID;

/**
 * The only component allowed to change balances.
 *
 * <p>Guarantees, all within the caller's database transaction:
 * <ol>
 *   <li>postings balance per currency (debits == credits) — also re-checked by a DB constraint trigger;</li>
 *   <li>every involved balance row is locked {@code FOR UPDATE} in a globally consistent order
 *       (sorted account id), so concurrent journals cannot deadlock;</li>
 *   <li>customer accounts can never go negative and must be ACTIVE;</li>
 *   <li>each posting writes an immutable entry with the resulting running balance.</li>
 * </ol>
 */
@Service
public class LedgerService {

    private static final DateTimeFormatter REF_DATE = DateTimeFormatter.ofPattern("yyMMdd");

    private final LedgerTransactionRepository transactions;
    private final TransactionEntryRepository entries;
    private final AccountBalanceRepository balances;
    private final BankAccountRepository accounts;
    private final EntityManager entityManager;
    private final Clock clock;
    private final ZoneId zone;

    public LedgerService(LedgerTransactionRepository transactions, TransactionEntryRepository entries,
                         AccountBalanceRepository balances, BankAccountRepository accounts,
                         EntityManager entityManager, Clock clock,
                         com.khmerbank.common.config.AppProperties props) {
        this.transactions = transactions;
        this.entries = entries;
        this.balances = balances;
        this.accounts = accounts;
        this.entityManager = entityManager;
        this.clock = clock;
        this.zone = props.zone();
    }

    /** Serializes money movements initiated by one user (idempotency + limit checks become race-free). */
    @Transactional(propagation = Propagation.MANDATORY)
    public void lockInitiator(UUID userId) {
        // pg_advisory_xact_lock returns void; selecting a constant keeps the JDBC result type mappable.
        entityManager.createNativeQuery("SELECT 1 FROM pg_advisory_xact_lock(hashtextextended(:k, 0))")
                .setParameter("k", "initiator:" + userId)
                .getSingleResult();
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public String nextReference() {
        String date = LocalDate.now(clock.withZone(zone)).format(REF_DATE);
        return "KDB" + date + String.format("%08d", transactions.nextReferenceSequence() % 100_000_000L);
    }

    /** Persists the transaction header and its balanced postings. */
    @Transactional(propagation = Propagation.MANDATORY)
    public LedgerTransaction post(LedgerTransaction txn, List<Posting> postings) {
        validateBalanced(postings);
        Instant now = Instant.now(clock);
        if (txn.getCreatedAt() == null) {
            txn.setCreatedAt(now);
        }
        txn.setStatus(LedgerTransaction.Status.COMPLETED);
        txn.setCompletedAt(now);
        transactions.save(txn);

        // Lock all affected balances in deterministic order.
        TreeSet<UUID> ids = new TreeSet<>();
        postings.forEach(p -> ids.add(p.accountId()));
        Map<UUID, AccountBalance> locked = new HashMap<>();
        for (UUID id : ids) {
            AccountBalance b = balances.findByIdForUpdate(id)
                    .orElseThrow(() -> new IllegalStateException("No balance row for account " + id));
            locked.put(id, b);
        }
        Map<UUID, BankAccount> accountById = new HashMap<>();
        accounts.findAllById(ids).forEach(a -> accountById.put(a.getId(), a));

        List<TransactionEntry> lines = new ArrayList<>(postings.size());
        for (Posting p : postings) {
            AccountBalance b = locked.get(p.accountId());
            BankAccount account = accountById.get(p.accountId());
            if (b.getCurrency() != p.currency()) {
                throw new ApiException(ErrorCode.CURRENCY_MISMATCH,
                        "Posting currency " + p.currency() + " does not match account currency " + b.getCurrency());
            }
            if (account.isCustomer() && account.getStatus() != AccountStatus.ACTIVE) {
                throw new ApiException(ErrorCode.ACCOUNT_NOT_ACTIVE);
            }
            BigDecimal delta = p.direction() == TransactionEntry.Direction.CREDIT ? p.amount() : p.amount().negate();
            BigDecimal newLedger = b.getLedgerBalance().add(delta);
            BigDecimal newAvailable = b.getAvailableBalance().add(delta);
            if (!b.isAllowNegative() && newAvailable.signum() < 0) {
                throw new ApiException(ErrorCode.INSUFFICIENT_BALANCE,
                        "Available balance is lower than the debit amount");
            }
            b.setLedgerBalance(newLedger);
            b.setAvailableBalance(newAvailable);
            b.setUpdatedAt(now);
            lines.add(new TransactionEntry(txn.getId(), p.accountId(), p.direction(), p.amount(), p.currency(),
                    newLedger, now));
        }
        entries.saveAll(lines);
        // Flush now so CHECK constraints fail inside this call and JDBC read models see the rows.
        entries.flush();
        return txn;
    }

    static void validateBalanced(List<Posting> postings) {
        if (postings == null || postings.size() < 2) {
            throw new IllegalArgumentException("A journal needs at least two postings");
        }
        Map<CurrencyCode, BigDecimal> net = new EnumMap<>(CurrencyCode.class);
        for (Posting p : postings) {
            if (p.amount() == null || p.amount().signum() <= 0) {
                throw new IllegalArgumentException("Posting amounts must be positive");
            }
            BigDecimal signed = p.direction() == TransactionEntry.Direction.DEBIT ? p.amount() : p.amount().negate();
            net.merge(p.currency(), signed, BigDecimal::add);
        }
        net.forEach((currency, sum) -> {
            if (sum.signum() != 0) {
                throw new IllegalStateException("Unbalanced journal in " + currency + ": " + sum);
            }
        });
    }
}
