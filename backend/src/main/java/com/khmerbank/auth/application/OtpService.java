package com.khmerbank.auth.application;

import com.khmerbank.auth.domain.OtpChallenge;
import com.khmerbank.auth.infrastructure.OtpChallengeRepository;
import com.khmerbank.auth.infrastructure.OtpSender;
import com.khmerbank.common.config.AppProperties;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.Hashing;
import com.khmerbank.common.security.RateLimiter;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Service
public class OtpService {

    /** Issued challenge plus the raw code (returned to callers only when dev echo is enabled). */
    public record Issued(OtpChallenge challenge, String code) {
    }

    private static final int MAX_SENDS_PER_HOUR = 5;

    private final OtpChallengeRepository repository;
    private final OtpSender sender;
    private final SecurityCounterService counters;
    private final RateLimiter rateLimiter;
    private final SecureRandom random;
    private final AppProperties props;
    private final Clock clock;

    public OtpService(OtpChallengeRepository repository, OtpSender sender, SecurityCounterService counters,
                      RateLimiter rateLimiter, SecureRandom random, AppProperties props, Clock clock) {
        this.repository = repository;
        this.sender = sender;
        this.counters = counters;
        this.rateLimiter = rateLimiter;
        this.random = random;
        this.props = props;
        this.clock = clock;
    }

    @Transactional
    public Issued issue(UUID userId, String phone, OtpChallenge.Purpose purpose, String context) {
        if (!rateLimiter.tryAcquire("otp:" + phone, MAX_SENDS_PER_HOUR, Duration.ofHours(1))) {
            throw new ApiException(ErrorCode.RATE_LIMITED, "Too many verification codes requested");
        }
        String code = String.format("%06d", random.nextInt(1_000_000));
        Instant now = Instant.now(clock);

        OtpChallenge c = new OtpChallenge();
        c.setUserId(userId);
        c.setPurpose(purpose);
        c.setContext(context);
        c.setAttempts(0);
        c.setCreatedAt(now);
        c.setExpiresAt(now.plus(props.security().otpTtl()));
        c.setCodeHash("pending");
        repository.saveAndFlush(c);           // id is needed for the hash binding
        c.setCodeHash(hash(c.getId(), code));

        sender.send(phone, code, purpose.name());
        return new Issued(c, code);
    }

    /**
     * Verifies and consumes a challenge. Wrong codes are counted in a separate transaction;
     * after the maximum number of attempts the challenge is dead.
     */
    @Transactional
    public OtpChallenge verify(UUID challengeId, String code, OtpChallenge.Purpose purpose) {
        OtpChallenge c = repository.findById(challengeId)
                .orElseThrow(() -> new ApiException(ErrorCode.INVALID_OTP));
        Instant now = Instant.now(clock);
        if (c.getPurpose() != purpose || c.getConsumedAt() != null) {
            throw new ApiException(ErrorCode.INVALID_OTP);
        }
        if (c.getAttempts() >= props.security().otpMaxAttempts()) {
            throw new ApiException(ErrorCode.INVALID_OTP, "Too many attempts; request a new code");
        }
        if (c.getExpiresAt().isBefore(now)) {
            throw new ApiException(ErrorCode.OTP_EXPIRED);
        }
        if (code == null || !Hashing.constantTimeEquals(c.getCodeHash(), hash(c.getId(), code))) {
            counters.recordFailedOtp(c.getId());
            throw new ApiException(ErrorCode.INVALID_OTP);
        }
        c.setConsumedAt(now);
        return c;
    }

    public boolean exposeCodes() {
        return props.otp().exposeInResponse();
    }

    private String hash(UUID challengeId, String code) {
        return Hashing.hmacSha256Hex(props.security().otpPepper(), Objects.toString(challengeId) + ":" + code);
    }
}
