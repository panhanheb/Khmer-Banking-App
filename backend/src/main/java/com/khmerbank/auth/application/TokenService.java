package com.khmerbank.auth.application;

import com.khmerbank.auth.api.AuthDtos.TokenPair;
import com.khmerbank.auth.domain.RefreshToken;
import com.khmerbank.auth.infrastructure.RefreshTokenRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.config.AppProperties;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.Hashing;
import com.khmerbank.common.security.JwtService;
import com.khmerbank.common.web.ClientInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

/** Access tokens (JWT) + opaque refresh tokens with rotation and reuse detection. */
@Service
public class TokenService {

    private final RefreshTokenRepository repository;
    private final JwtService jwtService;
    private final AuditService audit;
    private final SecureRandom random;
    private final AppProperties props;
    private final Clock clock;

    public TokenService(RefreshTokenRepository repository, JwtService jwtService, AuditService audit,
                        SecureRandom random, AppProperties props, Clock clock) {
        this.repository = repository;
        this.jwtService = jwtService;
        this.audit = audit;
        this.random = random;
        this.props = props;
        this.clock = clock;
    }

    @Transactional
    public TokenPair issue(UUID userId, UUID deviceRowId, ClientInfo client) {
        return issueInFamily(userId, deviceRowId, UUID.randomUUID(), client).pair();
    }

    /**
     * Rotates a refresh token. If a token that was already rotated is presented again, it has
     * probably been stolen: the whole family is revoked and the caller must log in again.
     */
    @Transactional(noRollbackFor = ApiException.class)
    public TokenPair refresh(String rawRefreshToken, ClientInfo client) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            throw new ApiException(ErrorCode.TOKEN_INVALID);
        }
        RefreshToken current = repository.findByTokenHashForUpdate(Hashing.sha256Hex(rawRefreshToken))
                .orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID));
        Instant now = Instant.now(clock);

        if (current.getRevokedAt() != null) {
            if (current.getReplacedBy() != null) {
                repository.revokeFamily(current.getFamilyId(), now);
                audit.success(current.getUserId(), "REFRESH_TOKEN_REUSE_DETECTED", "refresh_token_family",
                        current.getFamilyId(), client, Map.of());
            }
            throw new ApiException(ErrorCode.TOKEN_INVALID);
        }
        if (current.getExpiresAt().isBefore(now)) {
            current.setRevokedAt(now);
            throw new ApiException(ErrorCode.TOKEN_EXPIRED);
        }

        Issued next = issueInFamily(current.getUserId(), current.getDeviceId(), current.getFamilyId(), client);
        current.setRevokedAt(now);
        current.setReplacedBy(next.entity().getId());
        return next.pair();
    }

    @Transactional
    public void revoke(String rawRefreshToken) {
        if (rawRefreshToken == null) {
            return;
        }
        repository.findByTokenHash(Hashing.sha256Hex(rawRefreshToken))
                .ifPresent(t -> repository.revokeFamily(t.getFamilyId(), Instant.now(clock)));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void revokeAllForUser(UUID userId) {
        repository.revokeAllForUser(userId, Instant.now(clock));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void revokeAllForDevice(UUID deviceRowId) {
        repository.revokeAllForDevice(deviceRowId, Instant.now(clock));
    }

    private record Issued(TokenPair pair, RefreshToken entity) {
    }

    private Issued issueInFamily(UUID userId, UUID deviceRowId, UUID familyId, ClientInfo client) {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        Instant now = Instant.now(clock);

        RefreshToken token = new RefreshToken();
        token.setUserId(userId);
        token.setDeviceId(deviceRowId);
        token.setFamilyId(familyId);
        token.setTokenHash(Hashing.sha256Hex(raw));
        token.setCreatedAt(now);
        token.setExpiresAt(now.plus(props.security().refreshTokenTtl()));
        token.setCreatedIp(client == null ? null : client.ip());
        repository.save(token);

        String access = jwtService.issueAccessToken(userId, deviceRowId);
        return new Issued(new TokenPair(access, raw, "Bearer", jwtService.accessTokenTtlSeconds()), token);
    }
}
