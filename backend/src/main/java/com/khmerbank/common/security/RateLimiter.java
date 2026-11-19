package com.khmerbank.common.security;

import java.time.Duration;

public interface RateLimiter {

    /** @return true if the call identified by {@code key} is allowed within the window. */
    boolean tryAcquire(String key, int limit, Duration window);
}
