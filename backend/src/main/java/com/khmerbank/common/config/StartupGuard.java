package com.khmerbank.common.config;

import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

/**
 * Refuses to start with unsafe configuration: missing secrets, or the dev profile
 * (mock money, OTP echo) enabled in production.
 */
@Component
public class StartupGuard {

    public StartupGuard(AppProperties props, Environment env) {
        String secret = props.security().jwtSecret();
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SECRET must be set and at least 32 bytes long");
        }
        String pepper = props.security().otpPepper();
        if (pepper == null || pepper.isBlank()) {
            throw new IllegalStateException("OTP_PEPPER must be set");
        }
        if (props.isProduction()) {
            if (env.acceptsProfiles(Profiles.of("dev"))) {
                throw new IllegalStateException("The 'dev' profile must never be active when APP_ENV=prod");
            }
            if (props.otp().exposeInResponse()) {
                throw new IllegalStateException("app.otp.expose-in-response must be false in production");
            }
            if (secret.startsWith("dev-only")) {
                throw new IllegalStateException("Development JWT secret used in production");
            }
        }
    }
}
