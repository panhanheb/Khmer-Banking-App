package com.khmerbank.account.api;

import com.khmerbank.account.domain.AccountBalance;
import com.khmerbank.account.domain.AccountType;
import com.khmerbank.account.domain.BankAccount;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.money.Money;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

public final class AccountDtos {

    private AccountDtos() {
    }

    public record OpenAccountRequest(@NotNull AccountType type, @NotNull CurrencyCode currency,
                                     @Size(max = 60) String nickname) {
    }

    public record AccountResponse(UUID id, String accountNumber, String type, String currency, String status,
                                  String nickname, String balance, String availableBalance, Instant openedAt) {

        public static AccountResponse of(BankAccount a, AccountBalance b) {
            return new AccountResponse(a.getId(), a.getAccountNumber(), a.getAccountType().name(),
                    a.getCurrency().name(), a.getStatus().name(), a.getNickname(),
                    Money.format(b.getLedgerBalance(), a.getCurrency()),
                    Money.format(b.getAvailableBalance(), a.getCurrency()),
                    a.getOpenedAt());
        }
    }
}
