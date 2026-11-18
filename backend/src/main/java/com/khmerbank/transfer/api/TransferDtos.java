package com.khmerbank.transfer.api;

import com.khmerbank.common.money.CurrencyCode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

public final class TransferDtos {

    private TransferDtos() {
    }

    public record LookupRequest(@Pattern(regexp = "\\d{6,20}") String accountNumber,
                                @Size(max = 20) String phone,
                                CurrencyCode currency) {
    }

    public record LookupResponse(String accountNumber, String accountName, String currency, String bankName) {
    }

    public record QuoteRequest(@NotNull UUID sourceAccountId,
                               @NotBlank @Pattern(regexp = "\\d{6,20}") String destinationAccountNumber,
                               @NotBlank String amount,
                               @NotNull CurrencyCode currency) {
    }

    public record QuoteResponse(String debitAmount, String debitCurrency, String creditAmount, String creditCurrency,
                                String fee, String feeCurrency, String exchangeRate, String totalDebit,
                                String destinationName, String dailyLimitRemaining) {
    }

    public record TransferRequest(@NotNull UUID sourceAccountId,
                                  @NotBlank @Pattern(regexp = "\\d{6,20}") String destinationAccountNumber,
                                  @NotBlank String amount,
                                  @NotNull CurrencyCode currency,
                                  @Size(max = 140) String description,
                                  @NotBlank @Pattern(regexp = "\\d{6}") String pin) {

        @Override
        public String toString() {
            return "TransferRequest[source=" + sourceAccountId + ", amount=" + amount + " " + currency + ", pin=***]";
        }
    }

    public record TransferReceipt(UUID transactionId, String reference, String status,
                                  String debitAmount, String debitCurrency, String creditAmount, String creditCurrency,
                                  String fee, String exchangeRate, String sourceAccountNumber,
                                  String destinationAccountNumber, String destinationName, String description,
                                  Instant createdAt) {
    }
}
