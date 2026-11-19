package com.khmerbank.common.security;

import java.util.UUID;

/** Principal placed in the SecurityContext by {@link FirebaseAuthenticationFilter}; {@code deviceId} is the user_devices row id (or null). */
public record AuthenticatedUser(UUID userId, UUID deviceId) {
}
