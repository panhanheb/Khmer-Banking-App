package com.khmerbank.common.config;

import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

/**
 * Refuses to start with unsafe configuration: no Firebase project configured, or the dev
 * profile (mock money) enabled in production.
 */
@Component
public class StartupGuard {

    public StartupGuard(AppProperties props, Environment env) {
        String projectId = props.firebase() == null ? null : props.firebase().projectId();
        if (projectId == null || projectId.isBlank()) {
            throw new IllegalStateException("FIREBASE_PROJECT_ID must be set");
        }
        if (props.isProduction() && env.acceptsProfiles(Profiles.of("dev"))) {
            throw new IllegalStateException("The 'dev' profile must never be active when APP_ENV=prod");
        }
    }
}
