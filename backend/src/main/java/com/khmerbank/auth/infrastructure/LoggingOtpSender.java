package com.khmerbank.auth.infrastructure;

import com.khmerbank.common.money.Masking;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * MOCK sender for dev/test: logs the code instead of sending an SMS. Never active in prod —
 * without a real {@link OtpSender} bean the prod profile fails fast at startup.
 */
@Component
@Profile("!prod")
public class LoggingOtpSender implements OtpSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingOtpSender.class);

    @Override
    public void send(String phone, String code, String purpose) {
        log.info("[MOCK SMS] OTP for {} ({}): {}", Masking.phone(phone), purpose, code);
    }
}
