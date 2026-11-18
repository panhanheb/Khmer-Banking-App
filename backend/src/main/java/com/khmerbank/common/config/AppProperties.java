package com.khmerbank.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;
import java.time.ZoneId;

@ConfigurationProperties(prefix = "app")
public record AppProperties(
        String env,
        String timezone,
        Security security,
        Otp otp,
        RateLimit rateLimit,
        Accounts accounts) {

    public record Security(
            String jwtSecret,
            Duration accessTokenTtl,
            Duration refreshTokenTtl,
            String otpPepper,
            int maxFailedLogins,
            Duration loginLockDuration,
            int maxFailedPins,
            Duration pinLockDuration,
            Duration otpTtl,
            int otpMaxAttempts) {
    }

    public record Otp(boolean exposeInResponse) {
    }

    public record RateLimit(String store, int authRequestsPerMinute) {
    }

    public record Accounts(int maxPerUser, String branchCode) {
    }

    public ZoneId zone() {
        return ZoneId.of(timezone);
    }

    public boolean isProduction() {
        return "prod".equalsIgnoreCase(env);
    }
}
