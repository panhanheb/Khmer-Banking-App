package com.khmerbank.auth.application;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;

import java.util.regex.Pattern;

/** Normalizes Cambodian mobile numbers to E.164 (+855XXXXXXXX). */
public final class PhoneNumbers {

    private static final Pattern E164_KH = Pattern.compile("^\\+855[1-9]\\d{7,8}$");

    private PhoneNumbers() {
    }

    public static String normalize(String raw) {
        if (raw == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Phone number is required");
        }
        String s = raw.replaceAll("[\\s()-]", "");
        if (s.startsWith("00855")) {
            s = "+" + s.substring(2);
        } else if (s.startsWith("855")) {
            s = "+" + s;
        } else if (s.startsWith("0")) {
            s = "+855" + s.substring(1);
        }
        if (!E164_KH.matcher(s).matches()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Invalid Cambodian phone number");
        }
        return s;
    }
}
