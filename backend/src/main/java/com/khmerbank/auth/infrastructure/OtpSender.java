package com.khmerbank.auth.infrastructure;

/**
 * Delivery channel for one-time passwords.
 *
 * <p><b>External authorization required for production:</b> a contract with a Cambodian SMS
 * aggregator (registered sender ID, API credentials supplied via environment/vault).
 * Implement this interface with that provider's adapter and activate it under the prod profile.
 */
public interface OtpSender {

    void send(String phone, String code, String purpose);
}
