package com.khmerbank.auth.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

public final class AuthDtos {

    private AuthDtos() {
    }

    public record RegisterRequest(
            @NotBlank @Size(max = 20) String phone,
            @Email @Size(max = 255) String email,
            @NotBlank @Size(min = 8, max = 72) String password,
            @NotBlank @Size(max = 150) String fullNameEn,
            @Size(max = 150) String fullNameKm,
            @Pattern(regexp = "km|en") String language) {

        @Override
        public String toString() {
            return "RegisterRequest[phone=" + phone + ", password=***]";
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record RegisterResponse(UUID userId, UUID challengeId, Instant otpExpiresAt, String devOtp) {
    }

    public record VerifyOtpRequest(@NotNull UUID challengeId, @NotBlank @Pattern(regexp = "\\d{6}") String code) {
    }

    public record VerifyOtpResponse(boolean verified) {
    }

    public record LoginRequest(
            @NotBlank String phone,
            @NotBlank @Size(max = 72) String password,
            @NotBlank @Size(max = 128) String deviceId,
            @Size(max = 100) String deviceName,
            @NotBlank @Pattern(regexp = "ANDROID|IOS|WEB") String platform) {

        @Override
        public String toString() {
            return "LoginRequest[phone=" + phone + ", password=***, deviceId=" + deviceId + "]";
        }
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record LoginResponse(boolean mfaRequired, TokenPair tokens, UUID challengeId, String devOtp) {
    }

    public record LoginMfaRequest(
            @NotNull UUID challengeId,
            @NotBlank @Pattern(regexp = "\\d{6}") String code,
            @NotBlank @Size(max = 128) String deviceId,
            @Size(max = 100) String deviceName,
            @NotBlank @Pattern(regexp = "ANDROID|IOS|WEB") String platform) {
    }

    public record TokenPair(String accessToken, String refreshToken, String tokenType, long expiresIn) {
    }

    public record RefreshRequest(@NotBlank String refreshToken) {
    }

    public record ForgotPasswordRequest(@NotBlank String phone) {
    }

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ForgotPasswordResponse(UUID challengeId, String devOtp) {
    }

    public record ResetPasswordRequest(
            @NotNull UUID challengeId,
            @NotBlank @Pattern(regexp = "\\d{6}") String code,
            @NotBlank @Size(min = 8, max = 72) String newPassword) {
    }

    public record ChangePasswordRequest(@NotBlank String currentPassword, @NotBlank @Size(min = 8, max = 72) String newPassword) {
    }

    public record ChangePinRequest(@Pattern(regexp = "\\d{6}") String currentPin,
                                   @NotBlank @Pattern(regexp = "\\d{6}") String newPin) {
    }

    public record DeviceResponse(UUID id, String deviceName, String platform, boolean trusted,
                                 Instant lastSeenAt, boolean current) {
    }
}
