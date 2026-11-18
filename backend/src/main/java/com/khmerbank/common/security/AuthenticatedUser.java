package com.khmerbank.common.security;

import java.util.UUID;

/** Principal placed in the SecurityContext by {@link JwtAuthenticationFilter}. */
public record AuthenticatedUser(UUID userId, UUID deviceId) {
}
