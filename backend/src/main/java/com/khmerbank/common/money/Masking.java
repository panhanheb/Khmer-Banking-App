package com.khmerbank.common.money;

/** Sensitive-data masking for anything shown to a counterparty or written to logs. */
public final class Masking {

    private Masking() {
    }

    /** "001234567890" → "****7890" */
    public static String accountNumber(String accountNumber) {
        if (accountNumber == null || accountNumber.length() <= 4) {
            return "****";
        }
        return "****" + accountNumber.substring(accountNumber.length() - 4);
    }

    /** "+85512345678" → "+855****5678" */
    public static String phone(String phone) {
        if (phone == null || phone.length() < 8) {
            return "****";
        }
        return phone.substring(0, 4) + "****" + phone.substring(phone.length() - 4);
    }

    /** "Chan Sopheap" → "C*** Sopheap"; single names keep only the first letter. */
    public static String name(String fullName) {
        if (fullName == null || fullName.isBlank()) {
            return "***";
        }
        String[] parts = fullName.trim().split("\\s+");
        StringBuilder sb = new StringBuilder();
        sb.append(parts[0].charAt(0)).append("***");
        for (int i = 1; i < parts.length; i++) {
            sb.append(' ').append(parts[i]);
        }
        return sb.toString();
    }
}
