package com.khmerbank.auth.api;

import com.khmerbank.auth.api.AuthDtos.ChangePinRequest;
import com.khmerbank.auth.api.AuthDtos.DeviceResponse;
import com.khmerbank.auth.application.DeviceService;
import com.khmerbank.auth.application.PinService;
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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Transaction PIN and device management. Sign-in, registration and passwords are handled by
 * Firebase Authentication; every endpoint here requires a Firebase ID token.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication")
public class AuthController {

    private final PinService pinService;
    private final DeviceService deviceService;
    private final UserDeviceRepository devices;
    private final AuditService audit;

    public AuthController(PinService pinService, DeviceService deviceService, UserDeviceRepository devices,
                          AuditService audit) {
        this.pinService = pinService;
        this.deviceService = deviceService;
        this.devices = devices;
        this.audit = audit;
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
        deviceService.revoke(me.userId(), id, ClientInfo.from(http));
    }
}
