package com.khmerbank.dev;

import com.khmerbank.account.application.AccountService;
import com.khmerbank.account.domain.BankAccount;
import com.khmerbank.account.infrastructure.BankAccountRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.Hashing;
import com.khmerbank.common.money.Money;
import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.common.web.ClientInfo;
import com.khmerbank.ledger.api.TransactionView;
import com.khmerbank.ledger.application.LedgerService;
import com.khmerbank.ledger.application.TransactionQueryService;
import com.khmerbank.ledger.domain.LedgerTransaction;
import com.khmerbank.ledger.domain.Posting;
import com.khmerbank.ledger.infrastructure.LedgerTransactionRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.NotBlank;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * DEV ONLY. Funds an account with SIMULATED money so flows can be tested end to end.
 * Exists only under the "dev" profile; {@code StartupGuard} forbids that profile in production.
 * Every resulting transaction is flagged {@code simulated = true}.
 */
@RestController
@Profile("dev")
@RequestMapping("/api/v1/dev")
@Tag(name = "Dev (simulated money)")
public class DevFundingController {

    public record DepositRequest(@NotBlank String amount) {
    }

    private final AccountService accountService;
    private final BankAccountRepository accounts;
    private final LedgerService ledger;
    private final LedgerTransactionRepository transactions;
    private final TransactionQueryService queries;
    private final AuditService audit;

    public DevFundingController(AccountService accountService, BankAccountRepository accounts, LedgerService ledger,
                                LedgerTransactionRepository transactions, TransactionQueryService queries,
                                AuditService audit) {
        this.accountService = accountService;
        this.accounts = accounts;
        this.ledger = ledger;
        this.transactions = transactions;
        this.queries = queries;
        this.audit = audit;
    }

    @Operation(summary = "SIMULATED cash deposit (dev profile only)")
    @PostMapping("/accounts/{id}/deposit")
    @Transactional
    public ResponseEntity<TransactionView> deposit(@AuthenticationPrincipal AuthenticatedUser me,
                                                   @PathVariable UUID id,
                                                   @RequestHeader("Idempotency-Key") String idempotencyKey,
                                                   @RequestBody DepositRequest req,
                                                   HttpServletRequest http) {
        BankAccount account = accountService.requireOwned(me.userId(), id);
        BigDecimal amount = Money.parsePositive(req.amount(), account.getCurrency());
        ledger.lockInitiator(me.userId());

        String hash = Hashing.sha256Hex("deposit|" + id + "|" + amount.stripTrailingZeros().toPlainString());
        var previous = transactions.findByInitiatedByAndIdempotencyKey(me.userId(), idempotencyKey);
        if (previous.isPresent()) {
            if (!hash.equals(previous.get().getRequestHash())) {
                throw new ApiException(ErrorCode.IDEMPOTENCY_CONFLICT);
            }
            return ResponseEntity.ok(queries.get(me.userId(), previous.get().getId()));
        }

        UUID cash = accounts.findBySystemCode("SIMULATED_CASH_" + account.getCurrency())
                .orElseThrow().getId();
        LedgerTransaction txn = new LedgerTransaction();
        txn.setReference(ledger.nextReference());
        txn.setType(LedgerTransaction.Type.DEPOSIT);
        txn.setInitiatedBy(me.userId());
        txn.setIdempotencyKey(idempotencyKey);
        txn.setRequestHash(hash);
        txn.setDescription("SIMULATED deposit (development only)");
        txn.setAmount(amount);
        txn.setCurrency(account.getCurrency());
        txn.setSimulated(true);
        ledger.post(txn, List.of(
                Posting.debit(cash, amount, account.getCurrency()),
                Posting.credit(account.getId(), amount, account.getCurrency())));

        audit.success(me.userId(), "SIMULATED_DEPOSIT", "transaction", txn.getId(), ClientInfo.from(http),
                Map.of("amount", Money.format(amount, account.getCurrency())));
        return ResponseEntity.status(HttpStatus.CREATED).body(queries.get(me.userId(), txn.getId()));
    }
}
