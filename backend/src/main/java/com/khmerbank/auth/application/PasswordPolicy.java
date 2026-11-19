package com.khmerbank.auth.application;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;

import java.util.Set;
import java.util.regex.Pattern;

/** Transaction PIN rules. Passwords are handled by Firebase Authentication. */
public final class PasswordPolicy {

    private static final Pattern PIN = Pattern.compile("^\\d{6}$");
    private static final Set<String> WEAK_PINS = Set.of(
            "000000", "111111", "222222", "333333", "444444", "555555", "666666", "777777",
            "888888", "999999", "123456", "654321", "123123", "112233");

    private PasswordPolicy() {
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
