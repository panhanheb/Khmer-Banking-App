package com.khmerbank.auth.api;

import com.khmerbank.auth.api.AuthDtos.ChangePasswordRequest;
import com.khmerbank.auth.api.AuthDtos.ChangePinRequest;
import com.khmerbank.auth.api.AuthDtos.DeviceResponse;
import com.khmerbank.auth.api.AuthDtos.ForgotPasswordRequest;
import com.khmerbank.auth.api.AuthDtos.ForgotPasswordResponse;
import com.khmerbank.auth.api.AuthDtos.LoginMfaRequest;
import com.khmerbank.auth.api.AuthDtos.LoginRequest;
import com.khmerbank.auth.api.AuthDtos.LoginResponse;
import com.khmerbank.auth.api.AuthDtos.RefreshRequest;
import com.khmerbank.auth.api.AuthDtos.RegisterRequest;
import com.khmerbank.auth.api.AuthDtos.RegisterResponse;
import com.khmerbank.auth.api.AuthDtos.ResetPasswordRequest;
import com.khmerbank.auth.api.AuthDtos.TokenPair;
import com.khmerbank.auth.api.AuthDtos.VerifyOtpRequest;
import com.khmerbank.auth.api.AuthDtos.VerifyOtpResponse;
import com.khmerbank.auth.application.AuthService;
import com.khmerbank.auth.application.PinService;
import com.khmerbank.auth.application.TokenService;
import com.khmerbank.auth.infrastructure.UserDeviceRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.security.AuthenticatedUser;
import com.khmerbank.common.web.ClientInfo;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication")
public class AuthController {

    private final AuthService authService;
    private final TokenService tokenService;
    private final PinService pinService;
    private final UserDeviceRepository devices;
    private final AuditService audit;

    public AuthController(AuthService authService, TokenService tokenService, PinService pinService,
                          UserDeviceRepository devices, AuditService audit) {
        this.authService = authService;
        this.tokenService = tokenService;
        this.pinService = pinService;
        this.devices = devices;
        this.audit = audit;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public RegisterResponse register(@Valid @RequestBody RegisterRequest req, HttpServletRequest http) {
        return authService.register(req, ClientInfo.from(http));
    }

    @PostMapping("/otp/verify")
    public VerifyOtpResponse verifyOtp(@Valid @RequestBody VerifyOtpRequest req, HttpServletRequest http) {
        authService.verifyRegistration(req.challengeId(), req.code(), ClientInfo.from(http));
        return new VerifyOtpResponse(true);
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        return authService.login(req, ClientInfo.from(http));
    }

    @PostMapping("/login/mfa")
    public TokenPair loginMfa(@Valid @RequestBody LoginMfaRequest req, HttpServletRequest http) {
        return authService.completeLoginMfa(req, ClientInfo.from(http));
    }

    @PostMapping("/refresh")
    public TokenPair refresh(@Valid @RequestBody RefreshRequest req, HttpServletRequest http) {
        return tokenService.refresh(req.refreshToken(), ClientInfo.from(http));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest req) {
        tokenService.revoke(req.refreshToken());
    }

    @PostMapping("/password/forgot")
    public ForgotPasswordResponse forgot(@Valid @RequestBody ForgotPasswordRequest req, HttpServletRequest http) {
        return authService.forgotPassword(req.phone(), ClientInfo.from(http));
    }

    @PostMapping("/password/reset")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reset(@Valid @RequestBody ResetPasswordRequest req, HttpServletRequest http) {
        authService.resetPassword(req.challengeId(), req.code(), req.newPassword(), ClientInfo.from(http));
    }

    @PutMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal AuthenticatedUser me,
                               @Valid @RequestBody ChangePasswordRequest req, HttpServletRequest http) {
        authService.changePassword(me.userId(), req.currentPassword(), req.newPassword(), ClientInfo.from(http));
    }

    @PutMapping("/pin")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePin(@AuthenticationPrincipal AuthenticatedUser me,
                          @Valid @RequestBody ChangePinRequest req, HttpServletRequest http) {
        pinService.change(me.userId(), req.currentPin(), req.newPin());
        audit.success(me.userId(), "PIN_CHANGED", "user", me.userId(), ClientInfo.from(http), Map.of());
    }

    @GetMapping("/devices")
    public List<DeviceResponse> devices(@AuthenticationPrincipal AuthenticatedUser me) {
        return devices.findByUserIdAndRevokedAtIsNullOrderByLastSeenAtDesc(me.userId()).stream()
                .map(d -> new DeviceResponse(d.getId(), d.getDeviceName(), d.getPlatform(), d.isTrusted(),
                        d.getLastSeenAt(), Objects.equals(d.getId(), me.deviceId())))
                .toList();
    }

    @DeleteMapping("/devices/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revokeDevice(@AuthenticationPrincipal AuthenticatedUser me, @PathVariable UUID id,
                             HttpServletRequest http) {
        authService.revokeDevice(me.userId(), id, ClientInfo.from(http));
    }
}
