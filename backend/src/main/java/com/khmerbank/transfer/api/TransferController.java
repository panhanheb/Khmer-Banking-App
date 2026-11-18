package com.khmerbank.transfer.api;

import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.common.web.ClientInfo;
import com.khmerbank.transfer.api.TransferDtos.LookupRequest;
import com.khmerbank.transfer.api.TransferDtos.LookupResponse;
import com.khmerbank.transfer.api.TransferDtos.QuoteRequest;
import com.khmerbank.transfer.api.TransferDtos.QuoteResponse;
import com.khmerbank.transfer.api.TransferDtos.TransferReceipt;
import com.khmerbank.transfer.api.TransferDtos.TransferRequest;
import com.khmerbank.transfer.application.TransferService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/transfers")
@Tag(name = "Transfers")
public class TransferController {

    private final TransferService transferService;

    public TransferController(TransferService transferService) {
        this.transferService = transferService;
    }

    @PostMapping("/lookup")
    public LookupResponse lookup(@AuthenticationPrincipal AuthenticatedUser me, @Valid @RequestBody LookupRequest req) {
        return transferService.lookup(me.userId(), req);
    }

    @PostMapping("/quote")
    public QuoteResponse quote(@AuthenticationPrincipal AuthenticatedUser me, @Valid @RequestBody QuoteRequest req) {
        return transferService.quote(me.userId(), req);
    }

    /** 201 on first execution, 200 when the same Idempotency-Key is replayed. */
    @PostMapping
    public ResponseEntity<TransferReceipt> transfer(@AuthenticationPrincipal AuthenticatedUser me,
                                                    @RequestHeader("Idempotency-Key") String idempotencyKey,
                                                    @Valid @RequestBody TransferRequest req,
                                                    HttpServletRequest http) {
        TransferService.Result result = transferService.execute(me.userId(), req, idempotencyKey, ClientInfo.from(http));
        return ResponseEntity.status(result.replayed() ? HttpStatus.OK : HttpStatus.CREATED).body(result.receipt());
    }
}
