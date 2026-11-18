package com.khmerbank.auth.infrastructure;

import com.khmerbank.auth.domain.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserDeviceRepository extends JpaRepository<UserDevice, UUID> {

    Optional<UserDevice> findByUserIdAndDeviceId(UUID userId, String deviceId);

    List<UserDevice> findByUserIdAndRevokedAtIsNullOrderByLastSeenAtDesc(UUID userId);

    Optional<UserDevice> findByIdAndUserId(UUID id, UUID userId);
}
