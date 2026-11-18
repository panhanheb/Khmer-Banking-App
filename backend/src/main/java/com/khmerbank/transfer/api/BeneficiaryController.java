package com.khmerbank.transfer.api;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.transfer.api.TransferDtos.LookupRequest;
import com.khmerbank.transfer.api.TransferDtos.LookupResponse;
import com.khmerbank.transfer.application.TransferService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/** Saved recipients. The account name is resolved server-side; clients cannot set it. */
@RestController
@RequestMapping("/api/v1/beneficiaries")
@Tag(name = "Beneficiaries")
public class BeneficiaryController {

    public record CreateBeneficiaryRequest(@NotBlank @Pattern(regexp = "\\d{6,20}") String accountNumber,
                                           @Size(max = 60) String nickname) {
    }

    public record BeneficiaryResponse(UUID id, String nickname, String accountNumber, String accountName,
                                      String currency, String bankName) {
    }

    private final NamedParameterJdbcTemplate jdbc;
    private final TransferService transferService;

    public BeneficiaryController(NamedParameterJdbcTemplate jdbc, TransferService transferService) {
        this.jdbc = jdbc;
        this.transferService = transferService;
    }

    @GetMapping
    public List<BeneficiaryResponse> list(@AuthenticationPrincipal AuthenticatedUser me) {
        return jdbc.query("""
                        SELECT id, nickname, account_number, account_name, currency FROM beneficiaries
                        WHERE user_id = :u ORDER BY created_at DESC
                        """, new MapSqlParameterSource("u", me.userId()),
                (rs, i) -> new BeneficiaryResponse(rs.getObject("id", UUID.class), rs.getString("nickname"),
                        rs.getString("account_number"), rs.getString("account_name"), rs.getString("currency"),
                        TransferService.BANK_NAME));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public BeneficiaryResponse create(@AuthenticationPrincipal AuthenticatedUser me,
                                      @Valid @RequestBody CreateBeneficiaryRequest req) {
        LookupResponse found = transferService.lookup(me.userId(), new LookupRequest(req.accountNumber(), null, null));
        UUID id = UUID.randomUUID();
        try {
            jdbc.update("""
                    INSERT INTO beneficiaries (id, user_id, nickname, account_number, bank_code, account_name, currency)
                    VALUES (:id, :u, :n, :a, 'KDB', :name, :c)
                    """, new MapSqlParameterSource()
                    .addValue("id", id).addValue("u", me.userId()).addValue("n", req.nickname())
                    .addValue("a", found.accountNumber()).addValue("name", found.accountName())
                    .addValue("c", found.currency()));
        } catch (DuplicateKeyException e) {
            throw new ApiException(ErrorCode.DUPLICATE, "Beneficiary already saved");
        }
        return new BeneficiaryResponse(id, req.nickname(), found.accountNumber(), found.accountName(),
                found.currency(), found.bankName());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal AuthenticatedUser me, @PathVariable UUID id) {
        int n = jdbc.update("DELETE FROM beneficiaries WHERE id = :id AND user_id = :u",
                new MapSqlParameterSource().addValue("id", id).addValue("u", me.userId()));
        if (n == 0) {
            throw new ApiException(ErrorCode.NOT_FOUND);
        }
    }
}
