package com.khmerbank.auth.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.time.Instant;
import java.util.UUID;

/** Sign-in, registration and passwords are handled by Firebase Authentication. */
public final class AuthDtos {

    private AuthDtos() {
    }

    public record ChangePinRequest(@Pattern(regexp = "\\d{6}") String currentPin,
                                   @NotBlank @Pattern(regexp = "\\d{6}") String newPin) {

        @Override
        public String toString() {
            return "ChangePinRequest[***]";
        }
    }

    public record DeviceResponse(UUID id, String deviceName, String platform, boolean trusted,
                                 Instant lastSeenAt, boolean current) {
    }
}
