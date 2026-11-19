package com.khmerbank.auth.application;

import com.khmerbank.auth.domain.User;
import com.khmerbank.auth.infrastructure.UserRepository;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/** Transaction PIN: BCrypt-hashed, verified server-side for every money movement, lockout after N failures. */
@Service
public class PinService {

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final SecurityCounterService counters;
    private final Clock clock;

    public PinService(UserRepository users, PasswordEncoder encoder, SecurityCounterService counters, Clock clock) {
        this.users = users;
        this.encoder = encoder;
        this.counters = counters;
        this.clock = clock;
    }

    /** Must be called inside the business transaction that the PIN authorizes. */
    @Transactional
    public void verify(UUID userId, String pin) {
        User user = users.findById(userId).orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED));
        Instant now = Instant.now(clock);
        if (user.getPinHash() == null) {
            throw new ApiException(ErrorCode.PIN_NOT_SET);
        }
        if (user.isPinLocked(now)) {
            throw new ApiException(ErrorCode.PIN_LOCKED);
        }
        if (pin == null || !encoder.matches(pin, user.getPinHash())) {
            boolean locked = counters.recordFailedPin(userId);
            throw new ApiException(locked ? ErrorCode.PIN_LOCKED : ErrorCode.INVALID_PIN);
        }
        if (user.getFailedPinAttempts() > 0) {
            user.setFailedPinAttempts(0);
        }
    }

    @Transactional
    public void change(UUID userId, String currentPin, String newPin) {
        PasswordPolicy.validatePin(newPin);
        User user = users.findById(userId).orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED));
        if (user.getPinHash() != null) {
            verify(userId, currentPin);
        }
        user.setPinHash(encoder.encode(newPin));
        user.setFailedPinAttempts(0);
        user.setPinLockedUntil(null);
        user.setUpdatedAt(Instant.now(clock));
    }
}
