package com.khmerbank.account.api;

import com.khmerbank.account.api.AccountDtos.AccountResponse;
import com.khmerbank.account.api.AccountDtos.OpenAccountRequest;
import com.khmerbank.account.application.AccountService;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.common.web.ClientInfo;
import com.khmerbank.common.web.PageResponse;
import com.khmerbank.ledger.api.TransactionView;
import com.khmerbank.ledger.application.TransactionQueryService;
import com.khmerbank.ledger.domain.LedgerTransaction;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/accounts")
@Tag(name = "Accounts")
public class AccountController {

    private final AccountService accountService;
    private final TransactionQueryService queries;

    public AccountController(AccountService accountService, TransactionQueryService queries) {
        this.accountService = accountService;
        this.queries = queries;
    }

    @GetMapping
    public List<AccountResponse> list(@AuthenticationPrincipal AuthenticatedUser me) {
        return accountService.list(me.userId());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AccountResponse open(@AuthenticationPrincipal AuthenticatedUser me,
                                @Valid @RequestBody OpenAccountRequest req, HttpServletRequest http) {
        return accountService.open(me.userId(), req.type(), req.currency(), req.nickname(), ClientInfo.from(http));
    }

    @GetMapping("/{id}")
    public AccountResponse get(@AuthenticationPrincipal AuthenticatedUser me, @PathVariable UUID id) {
        return accountService.get(me.userId(), id);
    }

    @GetMapping("/{id}/transactions")
    public PageResponse<TransactionView> transactions(@AuthenticationPrincipal AuthenticatedUser me,
                                                      @PathVariable UUID id,
                                                      @RequestParam(defaultValue = "0") int page,
                                                      @RequestParam(defaultValue = "20") int size,
                                                      @RequestParam(required = false) Instant from,
                                                      @RequestParam(required = false) Instant to,
                                                      @RequestParam(required = false) LedgerTransaction.Type type,
                                                      @RequestParam(required = false) LedgerTransaction.Status status) {
        accountService.requireOwned(me.userId(), id);
        return queries.search(me.userId(),
                new TransactionQueryService.Filter(id, null, from, to, type, status, (CurrencyCode) null, null),
                page, size);
    }
}
