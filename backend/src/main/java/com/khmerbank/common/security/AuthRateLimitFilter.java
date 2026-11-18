package com.khmerbank.common.security;

import com.khmerbank.common.error.ErrorCode;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;

/** Per-IP throttling of unauthenticated auth endpoints (brute-force / OTP-spam protection). */
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private final RateLimiter rateLimiter;
    private final ProblemWriter problemWriter;
    private final int perMinute;

    public AuthRateLimitFilter(RateLimiter rateLimiter, ProblemWriter problemWriter, int perMinute) {
        this.rateLimiter = rateLimiter;
        this.problemWriter = problemWriter;
        this.perMinute = perMinute;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String key = "auth:" + request.getRemoteAddr() + ":" + request.getRequestURI();
        if (!rateLimiter.tryAcquire(key, perMinute, Duration.ofMinutes(1))) {
            response.setHeader("Retry-After", "60");
            problemWriter.write(response, ErrorCode.RATE_LIMITED, "Too many requests, try again later");
            return;
        }
        chain.doFilter(request, response);
    }
}
