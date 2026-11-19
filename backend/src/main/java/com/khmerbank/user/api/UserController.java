package com.khmerbank.user.api;

import com.khmerbank.auth.domain.User;
import com.khmerbank.auth.domain.UserProfile;
import com.khmerbank.auth.infrastructure.UserProfileRepository;
import com.khmerbank.auth.infrastructure.UserRepository;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.security.AuthenticatedUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Users")
public class UserController {

    public record MeResponse(UUID id, String phone, String email, String fullNameEn, String fullNameKm,
                             String language, String kycStatus, boolean pinSet, Instant createdAt) {
    }

    private final UserRepository users;
    private final UserProfileRepository profiles;

    public UserController(UserRepository users, UserProfileRepository profiles) {
        this.users = users;
        this.profiles = profiles;
    }

    @GetMapping("/me")
    @Transactional(readOnly = true)
    public MeResponse me(@AuthenticationPrincipal AuthenticatedUser me) {
        User user = users.findById(me.userId()).orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED));
        UserProfile profile = profiles.findById(me.userId()).orElse(null);
        return new MeResponse(user.getId(), user.getPhone(), user.getEmail(),
                profile == null ? null : profile.getFullNameEn(),
                profile == null ? null : profile.getFullNameKm(),
                user.getLanguage(), user.getKycStatus().name(), user.getPinHash() != null, user.getCreatedAt());
    }
}
