package com.khmerbank.ledger.domain;

import com.khmerbank.common.money.CurrencyCode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Header of a financial transaction; the money movement itself lives in {@link TransactionEntry}. */
@Entity
@Table(name = "transactions")
@Getter
@Setter
@NoArgsConstructor
public class LedgerTransaction {

    public enum Type { TRANSFER, DEPOSIT, WITHDRAWAL, FEE, REVERSAL, QR_PAYMENT, BILL_PAYMENT, TOPUP }

    public enum Status { PENDING, COMPLETED, FAILED, REVERSED }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String reference;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Type type;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    @Column(name = "initiated_by")
    private UUID initiatedBy;

    @Column(name = "idempotency_key")
    private String idempotencyKey;

    @Column(name = "request_hash")
    private String requestHash;

    private String description;

    /** Principal amount debited from the initiator, in {@link #currency}. */
    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CurrencyCode currency;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal fee = BigDecimal.ZERO;

    /** true = created by a mock/dev integration; never real money. */
    @Column(nullable = false)
    private boolean simulated;

    @Column(name = "reversal_of")
    private UUID reversalOf;

    @Column(name = "failure_reason")
    private String failureReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "completed_at")
    private Instant completedAt;
}
