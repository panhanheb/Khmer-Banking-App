package com.khmerbank.common.money;

import java.math.BigDecimal;
import java.math.RoundingMode;

public enum CurrencyCode {
    USD(2),
    KHR(0);

    private final int scale;

    CurrencyCode(int scale) {
        this.scale = scale;
    }

    public int scale() {
        return scale;
    }

    public BigDecimal round(BigDecimal value, RoundingMode mode) {
        return value.setScale(scale, mode);
    }
}
