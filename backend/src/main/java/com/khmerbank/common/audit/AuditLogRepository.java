package com.khmerbank.common.audit;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    List<AuditLog> findByActorIdAndActionOrderByCreatedAtDesc(UUID actorId, String action);
}
