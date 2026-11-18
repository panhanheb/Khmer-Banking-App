package com.khmerbank.auth.application;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;

import java.util.Set;
import java.util.regex.Pattern;

public final class PasswordPolicy {

    private static final Pattern UPPER = Pattern.compile("[A-Z]");
    private static final Pattern LOWER = Pattern.compile("[a-z]");
    private static final Pattern DIGIT = Pattern.compile("\\d");
    private static final Pattern SYMBOL = Pattern.compile("[^A-Za-z0-9]");
    private static final Pattern PIN = Pattern.compile("^\\d{6}$");
    private static final Set<String> WEAK_PINS = Set.of(
            "000000", "111111", "222222", "333333", "444444", "555555", "666666", "777777",
            "888888", "999999", "123456", "654321", "123123", "112233");

    private PasswordPolicy() {
    }

    public static void validatePassword(String password, String phone) {
        if (password == null || password.length() < 8 || password.length() > 72
                || !UPPER.matcher(password).find() || !LOWER.matcher(password).find()
                || !DIGIT.matcher(password).find() || !SYMBOL.matcher(password).find()) {
            throw new ApiException(ErrorCode.WEAK_PASSWORD,
                    "Password must be 8-72 characters and include upper case, lower case, a digit and a symbol");
        }
        String digits = phone == null ? "" : phone.replaceAll("\\D", "");
        if (digits.length() >= 6 && password.contains(digits.substring(digits.length() - 6))) {
            throw new ApiException(ErrorCode.WEAK_PASSWORD, "Password must not contain your phone number");
        }
    }

    public static void validatePin(String pin) {
        if (pin == null || !PIN.matcher(pin).matches()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "PIN must be exactly 6 digits");
        }
        if (WEAK_PINS.contains(pin)) {
            throw new ApiException(ErrorCode.WEAK_PASSWORD, "PIN is too easy to guess");
        }
    }
}
