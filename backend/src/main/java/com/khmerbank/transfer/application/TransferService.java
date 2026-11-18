package com.khmerbank.transfer.application;

import com.khmerbank.account.application.AccountService;
import com.khmerbank.account.domain.AccountStatus;
import com.khmerbank.account.domain.BankAccount;
import com.khmerbank.account.infrastructure.BankAccountRepository;
import com.khmerbank.auth.application.PhoneNumbers;
import com.khmerbank.auth.application.PinService;
import com.khmerbank.auth.domain.UserStatus;
import com.khmerbank.auth.infrastructure.UserProfileRepository;
import com.khmerbank.auth.infrastructure.UserRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.money.Hashing;
import com.khmerbank.common.money.Masking;
import com.khmerbank.common.money.Money;
import com.khmerbank.common.web.ClientInfo;
import com.khmerbank.exchangerate.application.ExchangeRateService;
import com.khmerbank.ledger.application.LedgerService;
import com.khmerbank.ledger.domain.LedgerTransaction;
import com.khmerbank.ledger.domain.Posting;
import com.khmerbank.ledger.infrastructure.LedgerTransactionRepository;
import com.khmerbank.transfer.api.TransferDtos.LookupRequest;
import com.khmerbank.transfer.api.TransferDtos.LookupResponse;
import com.khmerbank.transfer.api.TransferDtos.QuoteRequest;
import com.khmerbank.transfer.api.TransferDtos.QuoteResponse;
import com.khmerbank.transfer.api.TransferDtos.TransferReceipt;
import com.khmerbank.transfer.api.TransferDtos.TransferRequest;
import com.khmerbank.transfer.domain.Transfer;
import com.khmerbank.transfer.infrastructure.TransferRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Internal (same-bank) transfers. Interbank transfers will go through an {@code InterbankGateway}
 * (Bakong / CSS membership required) in Phase 7.
 */
@Service
public class TransferService {

    public static final String BANK_NAME = "Khmer Digital Bank";
    private static final Pattern IDEMPOTENCY_KEY = Pattern.compile("^[A-Za-z0-9_-]{8,100}$");

    /** Pre-computed transfer, shared by quote and execution so both use identical numbers. */
    record Plan(BankAccount source, BankAccount destination, Transfer.Type type, String destinationName,
                ExchangeRateService.Conversion conversion, BigDecimal fee) {

        BigDecimal totalDebit() {
            return conversion.debitAmount().add(fee);
        }
    }

    public record Result(TransferReceipt receipt, boolean replayed) {
    }

    private final BankAccountRepository accounts;
    private final AccountService accountService;
    private final UserRepository users;
    private final UserProfileRepository profiles;
    private final ExchangeRateService fx;
    private final PricingService pricing;
    private final PinService pinService;
    private final LedgerService ledger;
    private final LedgerTransactionRepository transactions;
    private final TransferRepository transfers;
    private final AuditService audit;
    private final Clock clock;

    public TransferService(BankAccountRepository accounts, AccountService accountService, UserRepository users,
                           UserProfileRepository profiles, ExchangeRateService fx, PricingService pricing,
                           PinService pinService, LedgerService ledger, LedgerTransactionRepository transactions,
                           TransferRepository transfers, AuditService audit, Clock clock) {
        this.accounts = accounts;
        this.accountService = accountService;
        this.users = users;
        this.profiles = profiles;
        this.fx = fx;
        this.pricing = pricing;
        this.pinService = pinService;
        this.ledger = ledger;
        this.transactions = transactions;
        this.transfers = transfers;
        this.audit = audit;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public LookupResponse lookup(UUID userId, LookupRequest req) {
        BankAccount account;
        if (req.accountNumber() != null && !req.accountNumber().isBlank()) {
            account = accounts.findByAccountNumber(req.accountNumber())
                    .filter(a -> a.isCustomer() && a.getStatus() == AccountStatus.ACTIVE)
                    .orElseThrow(() -> new ApiException(ErrorCode.RECIPIENT_NOT_FOUND));
        } else if (req.phone() != null && !req.phone().isBlank()) {
            String phone = PhoneNumbers.normalize(req.phone());
            var recipient = users.findByPhone(phone)
                    .filter(u -> u.getStatus() == UserStatus.ACTIVE)
                    .orElseThrow(() -> new ApiException(ErrorCode.RECIPIENT_NOT_FOUND));
            List<BankAccount> candidates =
                    accounts.findByPrimaryHolderIdAndStatusOrderByOpenedAt(recipient.getId(), AccountStatus.ACTIVE);
            account = candidates.stream()
                    .filter(a -> req.currency() == null || a.getCurrency() == req.currency())
                    .findFirst()
                    .or(() -> candidates.stream().findFirst())
                    .orElseThrow(() -> new ApiException(ErrorCode.RECIPIENT_NOT_FOUND));
        } else {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "accountNumber or phone is required");
        }
        return new LookupResponse(account.getAccountNumber(), maskedHolderName(account),
                account.getCurrency().name(), BANK_NAME);
    }

    @Transactional(readOnly = true)
    public QuoteResponse quote(UUID userId, QuoteRequest req) {
        Plan plan = plan(userId, req.sourceAccountId(), req.destinationAccountNumber(), req.amount(), req.currency());
        CurrencyCode debitCur = plan.source().getCurrency();
        PricingService.Limits limits = pricing.transferLimits(userId, debitCur);
        BigDecimal remaining = limits.dailyMax().subtract(pricing.usedToday(userId, debitCur)).max(BigDecimal.ZERO);
        return new QuoteResponse(
                Money.format(plan.conversion().debitAmount(), debitCur), debitCur.name(),
                Money.format(plan.conversion().creditAmount(), plan.destination().getCurrency()),
                plan.destination().getCurrency().name(),
                Money.format(plan.fee(), debitCur), debitCur.name(),
                Money.formatRate(plan.conversion().rate()),
                Money.format(plan.totalDebit(), debitCur),
                plan.destinationName(),
                Money.format(remaining, debitCur));
    }

    /**
     * Executes a transfer exactly once per (user, Idempotency-Key).
     * Order: per-user lock → idempotency → PIN → plan → limits → balanced ledger posting.
     */
    @Transactional
    public Result execute(UUID userId, TransferRequest req, String idempotencyKey, ClientInfo client) {
        if (idempotencyKey == null || !IDEMPOTENCY_KEY.matcher(idempotencyKey).matches()) {
            throw new ApiException(ErrorCode.IDEMPOTENCY_KEY_REQUIRED,
                    "Idempotency-Key must be 8-100 characters [A-Za-z0-9_-]");
        }
        ledger.lockInitiator(userId);

        String requestHash = requestHash(req);
        var previous = transactions.findByInitiatedByAndIdempotencyKey(userId, idempotencyKey);
        if (previous.isPresent()) {
            if (!Objects.equals(previous.get().getRequestHash(), requestHash)) {
                throw new ApiException(ErrorCode.IDEMPOTENCY_CONFLICT);
            }
            return new Result(receipt(previous.get()), true);
        }

        pinService.verify(userId, req.pin());

        Plan plan = plan(userId, req.sourceAccountId(), req.destinationAccountNumber(), req.amount(), req.currency());
        enforceLimits(userId, plan);

        CurrencyCode debitCur = plan.source().getCurrency();
        CurrencyCode creditCur = plan.destination().getCurrency();
        BigDecimal debit = plan.conversion().debitAmount();
        BigDecimal credit = plan.conversion().creditAmount();

        LedgerTransaction txn = new LedgerTransaction();
        txn.setReference(ledger.nextReference());
        txn.setType(LedgerTransaction.Type.TRANSFER);
        txn.setInitiatedBy(userId);
        txn.setIdempotencyKey(idempotencyKey);
        txn.setRequestHash(requestHash);
        txn.setDescription(req.description() == null ? null : req.description().trim());
        txn.setAmount(debit);
        txn.setCurrency(debitCur);
        txn.setFee(plan.fee());
        txn.setSimulated(false);

        List<Posting> postings = new ArrayList<>();
        postings.add(Posting.debit(plan.source().getId(), debit, debitCur));
        if (debitCur == creditCur) {
            postings.add(Posting.credit(plan.destination().getId(), credit, creditCur));
        } else {
            postings.add(Posting.credit(systemAccount("FX_POSITION_" + debitCur), debit, debitCur));
            postings.add(Posting.debit(systemAccount("FX_POSITION_" + creditCur), credit, creditCur));
            postings.add(Posting.credit(plan.destination().getId(), credit, creditCur));
        }
        if (plan.fee().signum() > 0) {
            postings.add(Posting.debit(plan.source().getId(), plan.fee(), debitCur));
            postings.add(Posting.credit(systemAccount("FEE_INCOME_" + debitCur), plan.fee(), debitCur));
        }
        ledger.post(txn, postings);

        Transfer transfer = new Transfer();
        transfer.setTransactionId(txn.getId());
        transfer.setTransferType(plan.type());
        transfer.setSourceAccountId(plan.source().getId());
        transfer.setDestinationAccountId(plan.destination().getId());
        transfer.setDestinationAccountNumber(plan.destination().getAccountNumber());
        transfer.setDestinationName(plan.destinationName());
        transfer.setDebitAmount(debit);
        transfer.setDebitCurrency(debitCur);
        transfer.setCreditAmount(credit);
        transfer.setCreditCurrency(creditCur);
        transfer.setExchangeRate(plan.conversion().rate());
        transfer.setFee(plan.fee());
        transfer.setCreatedAt(Instant.now(clock));
        transfers.save(transfer);

        audit.success(userId, "TRANSFER", "transaction", txn.getId(), client, Map.of(
                "reference", txn.getReference(),
                "amount", Money.format(debit, debitCur),
                "currency", debitCur.name(),
                "type", plan.type().name()));
        return new Result(buildReceipt(txn, transfer, plan.source().getAccountNumber()), false);
    }

    Plan plan(UUID userId, UUID sourceAccountId, String destinationAccountNumber, String rawAmount,
              CurrencyCode amountCurrency) {
        BankAccount source = accountService.requireOwned(userId, sourceAccountId);
        if (!source.isCustomer() || source.getStatus() != AccountStatus.ACTIVE) {
            throw new ApiException(ErrorCode.ACCOUNT_NOT_ACTIVE, "Source account is not active");
        }
        BankAccount destination = accounts.findByAccountNumber(destinationAccountNumber)
                .filter(BankAccount::isCustomer)
                .orElseThrow(() -> new ApiException(ErrorCode.RECIPIENT_NOT_FOUND));
        if (destination.getStatus() != AccountStatus.ACTIVE) {
            throw new ApiException(ErrorCode.ACCOUNT_NOT_ACTIVE, "Destination account is not active");
        }
        if (destination.getId().equals(source.getId())) {
            throw new ApiException(ErrorCode.SAME_ACCOUNT);
        }
        BigDecimal amount = Money.parsePositive(rawAmount, amountCurrency);
        ExchangeRateService.Conversion conversion =
                fx.convert(source.getCurrency(), destination.getCurrency(), amount, amountCurrency);
        Transfer.Type type = Objects.equals(destination.getPrimaryHolderId(), userId)
                ? Transfer.Type.OWN : Transfer.Type.INTERNAL;
        BigDecimal fee = pricing.transferFee(type, source.getCurrency(), conversion.debitAmount());
        return new Plan(source, destination, type, maskedHolderName(destination), conversion, fee);
    }

    private void enforceLimits(UUID userId, Plan plan) {
        CurrencyCode cur = plan.source().getCurrency();
        PricingService.Limits limits = pricing.transferLimits(userId, cur);
        BigDecimal debit = plan.conversion().debitAmount();
        if (debit.compareTo(limits.perTransactionMax()) > 0) {
            throw new ApiException(ErrorCode.LIMIT_EXCEEDED,
                    "Per-transaction limit is " + Money.format(limits.perTransactionMax(), cur) + " " + cur);
        }
        BigDecimal used = pricing.usedToday(userId, cur);
        if (used.add(debit).compareTo(limits.dailyMax()) > 0) {
            throw new ApiException(ErrorCode.LIMIT_EXCEEDED,
                    "Daily limit is " + Money.format(limits.dailyMax(), cur) + " " + cur);
        }
    }

    private UUID systemAccount(String code) {
        return accounts.findBySystemCode(code)
                .orElseThrow(() -> new IllegalStateException("Missing system account " + code))
                .getId();
    }

    private String maskedHolderName(BankAccount account) {
        return profiles.findById(account.getPrimaryHolderId())
                .map(p -> Masking.name(p.getFullNameEn()))
                .orElse("***");
    }

    private TransferReceipt receipt(LedgerTransaction txn) {
        Transfer transfer = transfers.findByTransactionId(txn.getId()).orElseThrow();
        String sourceNumber = accounts.findById(transfer.getSourceAccountId())
                .map(BankAccount::getAccountNumber).orElse(null);
        return buildReceipt(txn, transfer, sourceNumber);
    }

    private static TransferReceipt buildReceipt(LedgerTransaction txn, Transfer t, String sourceAccountNumber) {
        return new TransferReceipt(
                txn.getId(), txn.getReference(), txn.getStatus().name(),
                Money.format(t.getDebitAmount(), t.getDebitCurrency()), t.getDebitCurrency().name(),
                Money.format(t.getCreditAmount(), t.getCreditCurrency()), t.getCreditCurrency().name(),
                Money.format(t.getFee(), t.getDebitCurrency()),
                Money.formatRate(t.getExchangeRate()),
                Masking.accountNumber(sourceAccountNumber),
                Masking.accountNumber(t.getDestinationAccountNumber()),
                t.getDestinationName(), txn.getDescription(), txn.getCreatedAt());
    }

    /** Hash of the business payload (PIN excluded) used to detect Idempotency-Key reuse with different data. */
    static String requestHash(TransferRequest req) {
        String amount = Money.parsePositive(req.amount(), req.currency()).stripTrailingZeros().toPlainString();
        return Hashing.sha256Hex(String.join("|",
                String.valueOf(req.sourceAccountId()),
                String.valueOf(req.destinationAccountNumber()),
                amount,
                String.valueOf(req.currency()),
                req.description() == null ? "" : req.description().trim()));
    }
}
