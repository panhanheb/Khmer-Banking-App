package com.khmerbank.common.security;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Clock;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** Fixed-window rate limiters: Redis (shared across instances) or in-memory (single node / dev / tests). */
@Configuration
public class RateLimiters {

    @Bean
    @ConditionalOnProperty(name = "app.rate-limit.store", havingValue = "redis", matchIfMissing = true)
    public RateLimiter redisRateLimiter(StringRedisTemplate redis) {
        return (key, limit, window) -> {
            String redisKey = "rl:" + key;
            Long count = redis.opsForValue().increment(redisKey);
            if (count != null && count == 1L) {
                redis.expire(redisKey, window);
            }
            return count != null && count <= limit;
        };
    }

    @Bean
    @ConditionalOnProperty(name = "app.rate-limit.store", havingValue = "memory")
    public RateLimiter inMemoryRateLimiter(Clock clock) {
        return new InMemoryRateLimiter(clock);
    }

    static final class InMemoryRateLimiter implements RateLimiter {
        private record Window(long startMillis, int count) {
        }

        private final Map<String, Window> windows = new ConcurrentHashMap<>();
        private final Clock clock;

        InMemoryRateLimiter(Clock clock) {
            this.clock = clock;
        }

        @Override
        public boolean tryAcquire(String key, int limit, Duration window) {
            long now = clock.millis();
            Window w = windows.compute(key, (k, existing) -> {
                if (existing == null || now - existing.startMillis() >= window.toMillis()) {
                    return new Window(now, 1);
                }
                return new Window(existing.startMillis(), existing.count() + 1);
            });
            if (windows.size() > 100_000) {
                windows.entrySet().removeIf(e -> now - e.getValue().startMillis() >= window.toMillis());
            }
            return w.count() <= limit;
        }
    }
}
