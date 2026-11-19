package com.khmerbank.ledger.api;

import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.common.web.PageResponse;
import com.khmerbank.ledger.application.TransactionQueryService;
import com.khmerbank.ledger.domain.LedgerTransaction;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
@Tag(name = "Transactions")
public class TransactionController {

    private final TransactionQueryService queries;

    public TransactionController(TransactionQueryService queries) {
        this.queries = queries;
    }

    @GetMapping
    public PageResponse<TransactionView> search(@AuthenticationPrincipal AuthenticatedUser me,
                                                @RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "20") int size,
                                                @RequestParam(required = false) Instant from,
                                                @RequestParam(required = false) Instant to,
                                                @RequestParam(required = false) LedgerTransaction.Type type,
                                                @RequestParam(required = false) LedgerTransaction.Status status,
                                                @RequestParam(required = false) CurrencyCode currency,
                                                @RequestParam(required = false) String q) {
        return queries.search(me.userId(),
                new TransactionQueryService.Filter(null, null, from, to, type, status, currency, q), page, size);
    }

    @GetMapping("/{id}")
    public TransactionView get(@AuthenticationPrincipal AuthenticatedUser me, @PathVariable UUID id) {
        return queries.get(me.userId(), id);
    }
}
