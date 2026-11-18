package com.khmerbank.common.security;

import com.khmerbank.common.error.ApiException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/** Not a @Component: registered only inside the security filter chain. */
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final ProblemWriter problemWriter;
    private final java.util.Set<String> publicPostPaths;

    public JwtAuthenticationFilter(JwtService jwtService, ProblemWriter problemWriter, String... publicPostPaths) {
        this.jwtService = jwtService;
        this.problemWriter = problemWriter;
        this.publicPostPaths = java.util.Set.of(publicPostPaths);
    }

    /** Public endpoints (login, refresh, …) must work even if the client still sends an expired token. */
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return "POST".equals(request.getMethod()) && publicPostPaths.contains(request.getRequestURI());
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
            AuthenticatedUser principal = jwtService.parse(header.substring(7).trim());
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
}
