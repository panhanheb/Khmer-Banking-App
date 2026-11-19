package com.khmerbank.auth.application;

import com.khmerbank.auth.domain.User;
import com.khmerbank.auth.infrastructure.UserRepository;
import com.khmerbank.common.config.AppProperties;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/**
 * PIN failure counters are committed in their OWN transaction: the business transaction that
 * detected the failure is rolled back, but the attempt must still count, otherwise brute-force
 * protection could be bypassed.
 */
@Service
public class SecurityCounterService {

    private final UserRepository users;
    private final AppProperties props;
    private final Clock clock;

    public SecurityCounterService(UserRepository users, AppProperties props, Clock clock) {
        this.users = users;
        this.props = props;
        this.clock = clock;
    }

    /** @return true if this failure locked the PIN. */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean recordFailedPin(UUID userId) {
        User user = users.findById(userId).orElseThrow();
        int attempts = user.getFailedPinAttempts() + 1;
        boolean locked = attempts >= props.security().maxFailedPins();
        if (locked) {
            user.setPinLockedUntil(Instant.now(clock).plus(props.security().pinLockDuration()));
            attempts = 0;
        }
        user.setFailedPinAttempts(attempts);
        user.setUpdatedAt(Instant.now(clock));
        return locked;
    }
}
