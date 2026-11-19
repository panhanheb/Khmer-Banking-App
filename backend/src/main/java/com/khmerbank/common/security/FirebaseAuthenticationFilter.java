package com.khmerbank.common.security;

import com.khmerbank.auth.application.FirebaseUserService;
import com.khmerbank.auth.application.FirebaseUserService.DeviceHeaders;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.web.ClientInfo;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidationException;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Authenticates {@code Authorization: Bearer <Firebase ID token>} and maps the Firebase user to
 * the local {@code users} row (created on first use). Not a @Component: registered only inside
 * the security filter chain.
 */
public class FirebaseAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(FirebaseAuthenticationFilter.class);

    private final JwtDecoder decoder;
    private final FirebaseUserService users;
    private final ProblemWriter problemWriter;

    public FirebaseAuthenticationFilter(JwtDecoder decoder, FirebaseUserService users, ProblemWriter problemWriter) {
        this.decoder = decoder;
        this.users = users;
        this.problemWriter = problemWriter;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }
        try {
            Jwt jwt = decode(header.substring(7).trim());
            AuthenticatedUser principal = resolveUser(jwt, request);
            var auth = new UsernamePasswordAuthenticationToken(principal, null,
                    List.of(new SimpleGrantedAuthority("ROLE_CUSTOMER")));
            SecurityContextHolder.getContext().setAuthentication(auth);
        } catch (ApiException ex) {
            SecurityContextHolder.clearContext();
            problemWriter.write(response, ex.code(), ex.getMessage());
            return;
        }
        chain.doFilter(request, response);
    }

    private Jwt decode(String token) {
        try {
            return decoder.decode(token);
        } catch (JwtValidationException e) {
            boolean expired = e.getErrors().stream()
                    .anyMatch(err -> err.getDescription() != null && err.getDescription().contains("expired"));
            throw new ApiException(expired ? ErrorCode.TOKEN_EXPIRED : ErrorCode.TOKEN_INVALID);
        } catch (BadJwtException e) {
            throw new ApiException(ErrorCode.TOKEN_INVALID);
        } catch (JwtException e) {
            // e.g. Google's public keys could not be fetched: not the client's fault.
            log.warn("Firebase token verification unavailable: {}", e.getMessage());
            throw new ApiException(ErrorCode.AUTH_UNAVAILABLE);
        }
    }

    private AuthenticatedUser resolveUser(Jwt jwt, HttpServletRequest request) {
        DeviceHeaders device = DeviceHeaders.from(request);
        ClientInfo client = ClientInfo.from(request);
        try {
            return users.authenticate(jwt, device, client);
        } catch (DataIntegrityViolationException raced) {
            // Two first requests of a new user raced to create the row; the other one won.
            return users.authenticate(jwt, device, client);
        }
    }
}
