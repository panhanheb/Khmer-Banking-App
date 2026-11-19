package com.khmerbank.ledger.infrastructure;

import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.ledger.domain.LedgerTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface LedgerTransactionRepository extends JpaRepository<LedgerTransaction, UUID> {

    Optional<LedgerTransaction> findByInitiatedByAndIdempotencyKey(UUID initiatedBy, String idempotencyKey);

    @Query("""
            select sum(t.amount) from LedgerTransaction t
            where t.initiatedBy = :userId and t.type = :type and t.currency = :currency
              and t.status = :status and t.createdAt >= :since
            """)
    BigDecimal sumByStatusSince(@Param("userId") UUID userId, @Param("type") LedgerTransaction.Type type,
                                @Param("currency") CurrencyCode currency,
                                @Param("status") LedgerTransaction.Status status, @Param("since") Instant since);

    default BigDecimal sumCompletedSince(UUID userId, LedgerTransaction.Type type, CurrencyCode currency, Instant since) {
        BigDecimal sum = sumByStatusSince(userId, type, currency, LedgerTransaction.Status.COMPLETED, since);
        return sum == null ? BigDecimal.ZERO : sum;
    }

    @Query(value = "SELECT nextval('txn_reference_seq')", nativeQuery = true)
    long nextReferenceSequence();
}
