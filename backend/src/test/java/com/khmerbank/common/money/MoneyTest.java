package com.khmerbank.common.money;

import com.khmerbank.common.error.ApiException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MoneyTest {

    @Test
    void parsesUsdWithTwoDecimals() {
        assertThat(Money.parsePositive("10.5", CurrencyCode.USD)).isEqualByComparingTo("10.50");
        assertThat(Money.parsePositive("10.50", CurrencyCode.USD).scale()).isEqualTo(2);
    }

    @Test
    void rejectsSubCentAndFractionalRiel() {
        assertThatThrownBy(() -> Money.parsePositive("10.001", CurrencyCode.USD)).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> Money.parsePositive("100.5", CurrencyCode.KHR)).isInstanceOf(ApiException.class);
    }

    @Test
    void acceptsTrailingZerosBeyondScale() {
        assertThat(Money.parsePositive("100.00", CurrencyCode.KHR)).isEqualByComparingTo("100");
    }

    @Test
    void rejectsZeroNegativeAndGarbage() {
        for (String bad : new String[]{"0", "0.00", "-1", "1e3", "abc", "", " ", "1,000", null}) {
            assertThatThrownBy(() -> Money.parsePositive(bad, CurrencyCode.USD))
                    .as("input %s", bad).isInstanceOf(ApiException.class);
        }
    }

    @Test
    void formatsPerCurrency() {
        assertThat(Money.format(new BigDecimal("41000.0000"), CurrencyCode.KHR)).isEqualTo("41000");
        assertThat(Money.format(new BigDecimal("12.3000"), CurrencyCode.USD)).isEqualTo("12.30");
    }
}
