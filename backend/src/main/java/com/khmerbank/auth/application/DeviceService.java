package com.khmerbank.auth.application;

import com.khmerbank.auth.domain.UserDevice;
import com.khmerbank.auth.infrastructure.UserDeviceRepository;
import com.khmerbank.common.audit.AuditService;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.web.ClientInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Service
public class DeviceService {

    private final UserDeviceRepository devices;
    private final AuditService audit;
    private final Clock clock;

    public DeviceService(UserDeviceRepository devices, AuditService audit, Clock clock) {
        this.devices = devices;
        this.audit = audit;
        this.clock = clock;
    }

    /**
     * Blocks API access from that device until the user signs in on it again
     * (see {@link FirebaseUserService}).
     */
    @Transactional
    public void revoke(UUID userId, UUID deviceRowId, ClientInfo client) {
        UserDevice device = devices.findByIdAndUserId(deviceRowId, userId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND));
        device.setRevokedAt(Instant.now(clock));
        device.setTrusted(false);
        audit.success(userId, "DEVICE_REVOKED", "user_device", device.getId(), client, Map.of());
    }
}
