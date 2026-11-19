package com.khmerbank.common.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;
import java.time.ZoneId;

@ConfigurationProperties(prefix = "app")
public record AppProperties(
        String env,
        String timezone,
        Security security,
        Firebase firebase,
        RateLimit rateLimit,
        Accounts accounts) {

    public record Security(
            int maxFailedPins,
            Duration pinLockDuration) {
    }

    /** Firebase Authentication: the API accepts ID tokens issued for this project. */
    public record Firebase(String projectId) {

        public String issuer() {
            return "https://securetoken.google.com/" + projectId;
        }
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
