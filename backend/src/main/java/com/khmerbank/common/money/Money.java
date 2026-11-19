package com.khmerbank.common.money;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.regex.Pattern;

/** Parsing and formatting of monetary amounts. All amounts travel as decimal strings. */
public final class Money {

    private static final Pattern AMOUNT = Pattern.compile("^\\d{1,15}(\\.\\d{1,4})?$");
    private static final BigDecimal MAX = new BigDecimal("999999999999999");

    private Money() {
    }

    /** Parses a positive amount and checks it fits the currency's minor units. */
    public static BigDecimal parsePositive(String raw, CurrencyCode currency) {
        if (raw == null || !AMOUNT.matcher(raw.trim()).matches()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Amount must be a positive decimal string");
        }
        BigDecimal value = new BigDecimal(raw.trim());
        if (value.signum() <= 0) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Amount must be greater than zero");
        }
        if (value.compareTo(MAX) > 0) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Amount too large");
        }
        if (value.stripTrailingZeros().scale() > currency.scale()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    currency + " amounts allow at most " + currency.scale() + " decimal places");
        }
        return value.setScale(currency.scale(), RoundingMode.UNNECESSARY);
    }

    /** Formats an amount using the currency's minor units, e.g. "10.50" or "41000". */
    public static String format(BigDecimal value, CurrencyCode currency) {
        if (value == null) {
            return null;
        }
        return value.setScale(currency.scale(), RoundingMode.HALF_EVEN).toPlainString();
    }

    public static String formatRate(BigDecimal rate) {
        return rate == null ? null : rate.setScale(4, RoundingMode.HALF_EVEN).toPlainString();
    }
}
