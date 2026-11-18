package com.khmerbank.ledger.application;

import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.ledger.domain.Posting;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LedgerValidationTest {

    private final UUID a = UUID.randomUUID();
    private final UUID b = UUID.randomUUID();
    private final UUID fxUsd = UUID.randomUUID();
    private final UUID fxKhr = UUID.randomUUID();

    @Test
    void balancedSameCurrencyJournalPasses() {
        assertThatCode(() -> LedgerService.validateBalanced(List.of(
                Posting.debit(a, new BigDecimal("10.00"), CurrencyCode.USD),
                Posting.credit(b, new BigDecimal("10.00"), CurrencyCode.USD)))).doesNotThrowAnyException();
    }

    @Test
    void crossCurrencyJournalMustBalancePerCurrency() {
        assertThatCode(() -> LedgerService.validateBalanced(List.of(
                Posting.debit(a, new BigDecimal("10.00"), CurrencyCode.USD),
                Posting.credit(fxUsd, new BigDecimal("10.00"), CurrencyCode.USD),
                Posting.debit(fxKhr, new BigDecimal("40800"), CurrencyCode.KHR),
                Posting.credit(b, new BigDecimal("40800"), CurrencyCode.KHR)))).doesNotThrowAnyException();

        assertThatThrownBy(() -> LedgerService.validateBalanced(List.of(
                Posting.debit(a, new BigDecimal("10.00"), CurrencyCode.USD),
                Posting.credit(b, new BigDecimal("41000"), CurrencyCode.KHR))))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void unbalancedOrNonPositiveJournalsFail() {
        assertThatThrownBy(() -> LedgerService.validateBalanced(List.of(
                Posting.debit(a, new BigDecimal("10.00"), CurrencyCode.USD),
                Posting.credit(b, new BigDecimal("9.99"), CurrencyCode.USD))))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> LedgerService.validateBalanced(List.of(
                Posting.debit(a, BigDecimal.ZERO, CurrencyCode.USD),
                Posting.credit(b, BigDecimal.ZERO, CurrencyCode.USD))))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> LedgerService.validateBalanced(List.of(
                Posting.debit(a, BigDecimal.ONE, CurrencyCode.USD))))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
