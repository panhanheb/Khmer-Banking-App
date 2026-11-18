package com.khmerbank.auth.application;

import com.khmerbank.account.application.AccountService;
import com.khmerbank.account.domain.AccountType;
import com.khmerbank.auth.api.AuthDtos.ForgotPasswordResponse;
import com.khmerbank.auth.api.AuthDtos.LoginMfaRequest;
import com.khmerbank.auth.api.AuthDtos.LoginRequest;
import com.khmerbank.auth.api.AuthDtos.LoginResponse;
import com.khmerbank.auth.api.AuthDtos.RegisterRequest;
import com.khmerbank.auth.api.AuthDtos.RegisterResponse;
import com.khmerbank.auth.api.AuthDtos.TokenPair;
import com.khmerbank.auth.domain.OtpChallenge;
import com.khmerbank.auth.domain.User;
import com.khmerbank.auth.domain.UserDevice;
import com.khmerbank.auth.domain.UserProfile;
import com.khmerbank.auth.domain.UserStatus;
import com.khmerbank.auth.infrastructure.UserDeviceRepository;
import com.khmerbank.auth.infrastructure.UserProfileRepository;
import com.khmerbank.auth.infrastructure.UserRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.web.ClientInfo;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Service
public class AuthService {

    /** Pre-computed hash used to equalize timing when the phone is unknown (prevents user enumeration). */
    private final String dummyHash;

    private final UserRepository users;
    private final UserProfileRepository profiles;
    private final UserDeviceRepository devices;
    private final PasswordEncoder encoder;
    private final OtpService otpService;
    private final TokenService tokenService;
    private final SecurityCounterService counters;
    private final AccountService accountService;
    private final AuditService audit;
    private final Clock clock;

    public AuthService(UserRepository users, UserProfileRepository profiles, UserDeviceRepository devices,
                       PasswordEncoder encoder, OtpService otpService, TokenService tokenService,
                       SecurityCounterService counters, AccountService accountService, AuditService audit,
                       Clock clock) {
        this.users = users;
        this.profiles = profiles;
        this.devices = devices;
        this.encoder = encoder;
        this.otpService = otpService;
        this.tokenService = tokenService;
        this.counters = counters;
        this.accountService = accountService;
        this.audit = audit;
        this.clock = clock;
        this.dummyHash = encoder.encode("timing-equalizer-" + UUID.randomUUID());
    }

    @Transactional
    public RegisterResponse register(RegisterRequest req, ClientInfo client) {
        String phone = PhoneNumbers.normalize(req.phone());
        PasswordPolicy.validatePassword(req.password(), phone);
        // An unverified registration (no accounts, no money) may be restarted, e.g. when the OTP was lost.
        User existing = users.findByPhone(phone).orElse(null);
        if (existing != null && existing.getStatus() != UserStatus.PENDING_VERIFICATION) {
            throw new ApiException(ErrorCode.PHONE_ALREADY_REGISTERED);
        }
        String email = req.email() == null || req.email().isBlank() ? null : req.email().trim().toLowerCase();
        if (email != null && (existing == null || !email.equalsIgnoreCase(existing.getEmail()))
                && users.existsByEmailIgnoreCase(email)) {
            throw new ApiException(ErrorCode.EMAIL_ALREADY_REGISTERED);
        }
        Instant now = Instant.now(clock);

        User user = existing != null ? existing : new User();
        user.setPhone(phone);
        user.setEmail(email);
        user.setPasswordHash(encoder.encode(req.password()));
        user.setStatus(UserStatus.PENDING_VERIFICATION);
        user.setLanguage(req.language() == null ? "km" : req.language());
        user.setPasswordChangedAt(now);
        if (existing == null) {
            user.setCreatedAt(now);
        }
        user.setUpdatedAt(now);
        users.saveAndFlush(user);
        if (existing == null) {
            users.assignRole(user.getId(), "CUSTOMER");
        }

        UserProfile profile = profiles.findById(user.getId()).orElseGet(UserProfile::new);
        profile.setUserId(user.getId());
        profile.setFullNameEn(req.fullNameEn().trim());
        profile.setFullNameKm(req.fullNameKm() == null ? null : req.fullNameKm().trim());
        profile.setUpdatedAt(now);
        profiles.save(profile);

        OtpService.Issued otp = otpService.issue(user.getId(), phone, OtpChallenge.Purpose.REGISTRATION, null);
        audit.success(user.getId(), "USER_REGISTERED", "user", user.getId(), client, Map.of());
        return new RegisterResponse(user.getId(), otp.challenge().getId(), otp.challenge().getExpiresAt(),
                otpService.exposeCodes() ? otp.code() : null);
    }

    /** Verifies the registration OTP, activates the user and opens a default USD current account. */
    @Transactional
    public void verifyRegistration(UUID challengeId, String code, ClientInfo client) {
        OtpChallenge challenge = otpService.verify(challengeId, code, OtpChallenge.Purpose.REGISTRATION);
        User user = users.findById(challenge.getUserId()).orElseThrow();
        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            user.setPhoneVerified(true);
            user.setStatus(UserStatus.ACTIVE);
            user.setUpdatedAt(Instant.now(clock));
            accountService.open(user.getId(), AccountType.CURRENT, CurrencyCode.USD, "Main USD", client);
            audit.success(user.getId(), "PHONE_VERIFIED", "user", user.getId(), client, Map.of());
        }
    }

    @Transactional
    public LoginResponse login(LoginRequest req, ClientInfo client) {
        String phone = PhoneNumbers.normalize(req.phone());
        User user = users.findByPhone(phone).orElse(null);
        Instant now = Instant.now(clock);

        if (user == null) {
            encoder.matches(req.password(), dummyHash);
            audit.failure(null, "LOGIN", "user", null, client, Map.of("reason", "UNKNOWN_PHONE"));
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS);
        }
        if (user.isLoginLocked(now)) {
            audit.failure(user.getId(), "LOGIN", "user", user.getId(), client, Map.of("reason", "LOCKED"));
            throw new ApiException(ErrorCode.ACCOUNT_LOCKED, "Too many failed attempts. Try again later.");
        }
        if (!encoder.matches(req.password(), user.getPasswordHash())) {
            boolean locked = counters.recordFailedLogin(user.getId());
            audit.failure(user.getId(), "LOGIN", "user", user.getId(), client,
                    Map.of("reason", "BAD_PASSWORD", "locked", locked));
            throw new ApiException(locked ? ErrorCode.ACCOUNT_LOCKED : ErrorCode.INVALID_CREDENTIALS);
        }
        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            throw new ApiException(ErrorCode.PHONE_NOT_VERIFIED);
        }
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ApiException(ErrorCode.USER_NOT_ACTIVE);
        }
        user.setFailedLoginAttempts(0);
        user.setLockedUntil(null);

        UserDevice device = upsertDevice(user.getId(), req.deviceId(), req.deviceName(), req.platform(), now);
        if (device.isActiveTrusted()) {
            audit.success(user.getId(), "LOGIN", "user_device", device.getId(), client, Map.of());
            return new LoginResponse(false, tokenService.issue(user.getId(), device.getId(), client), null, null);
        }

        // New or previously revoked device → step-up with SMS OTP bound to this device.
        OtpService.Issued otp = otpService.issue(user.getId(), phone, OtpChallenge.Purpose.LOGIN_MFA, req.deviceId());
        audit.success(user.getId(), "LOGIN_MFA_CHALLENGE", "user_device", device.getId(), client, Map.of());
        return new LoginResponse(true, null, otp.challenge().getId(), otpService.exposeCodes() ? otp.code() : null);
    }

    @Transactional
    public TokenPair completeLoginMfa(LoginMfaRequest req, ClientInfo client) {
        OtpChallenge challenge = otpService.verify(req.challengeId(), req.code(), OtpChallenge.Purpose.LOGIN_MFA);
        if (!req.deviceId().equals(challenge.getContext())) {
            throw new ApiException(ErrorCode.INVALID_OTP);
        }
        User user = users.findById(challenge.getUserId()).orElseThrow();
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ApiException(ErrorCode.USER_NOT_ACTIVE);
        }
        Instant now = Instant.now(clock);
        UserDevice device = upsertDevice(user.getId(), req.deviceId(), req.deviceName(), req.platform(), now);
        device.setTrusted(true);
        device.setRevokedAt(null);
        audit.success(user.getId(), "DEVICE_TRUSTED", "user_device", device.getId(), client, Map.of());
        return tokenService.issue(user.getId(), device.getId(), client);
    }

    /** Always succeeds from the caller's point of view to prevent phone-number enumeration. */
    @Transactional
    public ForgotPasswordResponse forgotPassword(String rawPhone, ClientInfo client) {
        String phone = PhoneNumbers.normalize(rawPhone);
        return users.findByPhone(phone)
                .filter(u -> u.getStatus() == UserStatus.ACTIVE)
                .map(u -> {
                    OtpService.Issued otp = otpService.issue(u.getId(), phone, OtpChallenge.Purpose.PASSWORD_RESET, null);
                    audit.success(u.getId(), "PASSWORD_RESET_REQUESTED", "user", u.getId(), client, Map.of());
                    return new ForgotPasswordResponse(otp.challenge().getId(),
                            otpService.exposeCodes() ? otp.code() : null);
                })
                .orElseGet(() -> new ForgotPasswordResponse(UUID.randomUUID(), null));
    }

    @Transactional
    public void resetPassword(UUID challengeId, String code, String newPassword, ClientInfo client) {
        OtpChallenge challenge = otpService.verify(challengeId, code, OtpChallenge.Purpose.PASSWORD_RESET);
        User user = users.findById(challenge.getUserId()).orElseThrow();
        PasswordPolicy.validatePassword(newPassword, user.getPhone());
        Instant now = Instant.now(clock);
        user.setPasswordHash(encoder.encode(newPassword));
        user.setPasswordChangedAt(now);
        user.setFailedLoginAttempts(0);
        user.setLockedUntil(null);
        user.setUpdatedAt(now);
        tokenService.revokeAllForUser(user.getId());
        audit.success(user.getId(), "PASSWORD_RESET", "user", user.getId(), client, Map.of());
    }

    @Transactional
    public void changePassword(UUID userId, String currentPassword, String newPassword, ClientInfo client) {
        User user = users.findById(userId).orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED));
        if (!encoder.matches(currentPassword, user.getPasswordHash())) {
            audit.failure(userId, "PASSWORD_CHANGE", "user", userId, client, Map.of());
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS, "Current password is incorrect");
        }
        PasswordPolicy.validatePassword(newPassword, user.getPhone());
        Instant now = Instant.now(clock);
        user.setPasswordHash(encoder.encode(newPassword));
        user.setPasswordChangedAt(now);
        user.setUpdatedAt(now);
        audit.success(userId, "PASSWORD_CHANGE", "user", userId, client, Map.of());
    }

    @Transactional
    public void revokeDevice(UUID userId, UUID deviceRowId, ClientInfo client) {
        UserDevice device = devices.findByIdAndUserId(deviceRowId, userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND));
        device.setRevokedAt(Instant.now(clock));
        device.setTrusted(false);
        tokenService.revokeAllForDevice(device.getId());
        audit.success(userId, "DEVICE_REVOKED", "user_device", device.getId(), client, Map.of());
    }

    private UserDevice upsertDevice(UUID userId, String deviceId, String deviceName, String platform, Instant now) {
        UserDevice device = devices.findByUserIdAndDeviceId(userId, deviceId).orElseGet(() -> {
            UserDevice d = new UserDevice();
            d.setUserId(userId);
            d.setDeviceId(deviceId);
            d.setTrusted(false);
            d.setCreatedAt(now);
            return d;
        });
        device.setDeviceName(deviceName);
        device.setPlatform(platform);
        device.setLastSeenAt(now);
        return devices.save(device);
    }
}
