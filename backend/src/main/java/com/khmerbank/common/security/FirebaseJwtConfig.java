package com.khmerbank.common.security;

import com.khmerbank.common.config.AppProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/**
 * Verifies Firebase Authentication ID tokens, as described in
 * "Verify ID tokens using a third-party JWT library" (Firebase docs):
 * RS256 signature by Google's {@code securetoken} keys, {@code iss} =
 * {@code https://securetoken.google.com/<projectId>}, {@code aud} = project id,
 * non-empty {@code sub} (the Firebase UID), and a valid {@code exp}/{@code iat}.
 */
@Configuration
public class FirebaseJwtConfig {

    static final String JWK_SET_URI =
            "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";

    @Bean
    public JwtDecoder firebaseJwtDecoder(AppProperties props) {
        String projectId = props.firebase().projectId();
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(JWK_SET_URI)
                .jwsAlgorithm(SignatureAlgorithm.RS256)
                .build();
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(props.firebase().issuer()),
                audience(projectId),
                subject()));
        return decoder;
    }

    private static OAuth2TokenValidator<Jwt> audience(String projectId) {
        return jwt -> jwt.getAudience() != null && jwt.getAudience().contains(projectId)
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(
                        new OAuth2Error("invalid_token", "Token audience is not " + projectId, null));
    }

    private static OAuth2TokenValidator<Jwt> subject() {
        return jwt -> {
            String sub = jwt.getSubject();
            return sub != null && !sub.isBlank() && sub.length() <= 128
                    ? OAuth2TokenValidatorResult.success()
                    : OAuth2TokenValidatorResult.failure(
                            new OAuth2Error("invalid_token", "Token subject (uid) is invalid", null));
        };
    }
}
