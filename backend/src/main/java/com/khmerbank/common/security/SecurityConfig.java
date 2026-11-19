package com.khmerbank.common.security;

import com.khmerbank.auth.application.FirebaseUserService;
import com.khmerbank.common.config.AppProperties;
import com.khmerbank.common.error.ErrorCode;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;

/**
 * Stateless API secured by Firebase Authentication ID tokens
 * ({@code Authorization: Bearer <idToken>}), see {@link FirebaseAuthenticationFilter}.
 */
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, JwtDecoder firebaseJwtDecoder,
                                                   FirebaseUserService firebaseUsers,
                                                   ProblemWriter problemWriter, RateLimiter rateLimiter,
                                                   AppProperties props) throws Exception {
        http
                // Stateless bearer-token API: no cookies, so CSRF does not apply.
                .csrf(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .headers(h -> h
                        .contentSecurityPolicy(c -> c.policyDirectives("default-src 'none'; frame-ancestors 'none'"))
                        .referrerPolicy(r -> r.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER)))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, "/api/v1/exchange-rates").permitAll()
                        .requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
                        .requestMatchers("/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/api/**").authenticated()
                        .anyRequest().denyAll())
                .exceptionHandling(e -> e
                        .authenticationEntryPoint((req, res, ex) ->
                                problemWriter.write(res, ErrorCode.UNAUTHORIZED, "Authentication required"))
                        .accessDeniedHandler((req, res, ex) ->
                                problemWriter.write(res, ErrorCode.FORBIDDEN, "Access denied")))
                .addFilterBefore(new FirebaseAuthenticationFilter(firebaseJwtDecoder, firebaseUsers, problemWriter),
                        UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(new AuthRateLimitFilter(rateLimiter, problemWriter,
                                props.rateLimit().authRequestsPerMinute()),
                        FirebaseAuthenticationFilter.class);
        return http.build();
    }
}
