package com.khmerbank.common.audit;

import com.khmerbank.common.web.ClientInfo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Writes immutable audit records.
 * <ul>
 *   <li>{@link #success} joins the caller's transaction, so it commits atomically with the operation.</li>
 *   <li>{@link #failure} uses its own transaction so failed attempts are recorded even though
 *       the business transaction rolls back.</li>
 * </ul>
 */
@Service
public class AuditService {

    private final AuditLogRepository repository;
    private final Clock clock;

    public AuditService(AuditLogRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public void success(UUID userId, String action, String entityType, Object entityId,
                        ClientInfo client, Map<String, Object> details) {
        repository.save(build(userId, action, "SUCCESS", entityType, entityId, client, details));
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void failure(UUID userId, String action, String entityType, Object entityId,
                        ClientInfo client, Map<String, Object> details) {
        repository.save(build(userId, action, "FAILURE", entityType, entityId, client, details));
    }

    private AuditLog build(UUID userId, String action, String outcome, String entityType, Object entityId,
                           ClientInfo client, Map<String, Object> details) {
        AuditLog log = new AuditLog();
        log.setActorType(userId == null ? "ANONYMOUS" : "USER");
        log.setActorId(userId);
        log.setAction(action);
        log.setOutcome(outcome);
        log.setEntityType(entityType);
        log.setEntityId(entityId == null ? null : entityId.toString());
        if (client != null) {
            log.setIpAddress(client.ip());
            log.setUserAgent(client.userAgent());
        }
        log.setDetails(details);
        log.setCreatedAt(Instant.now(clock));
        return log;
    }
}
