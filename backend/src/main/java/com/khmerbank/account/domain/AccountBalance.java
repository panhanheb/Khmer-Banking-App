package com.khmerbank.account.domain;

import com.khmerbank.common.money.CurrencyCode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Balance snapshot. Modified only by the ledger, under a pessimistic row lock, in the same
 * database transaction that inserts the corresponding immutable entries.
 */
@Entity
@Table(name = "account_balances")
@Getter
@Setter
@NoArgsConstructor
public class AccountBalance {

    @Id
    @Column(name = "account_id")
    private UUID accountId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CurrencyCode currency;

    @Column(name = "ledger_balance", nullable = false, precision = 19, scale = 4)
    private BigDecimal ledgerBalance = BigDecimal.ZERO;

    @Column(name = "available_balance", nullable = false, precision = 19, scale = 4)
    private BigDecimal availableBalance = BigDecimal.ZERO;

    @Column(name = "hold_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal holdAmount = BigDecimal.ZERO;

    @Column(name = "allow_negative", nullable = false)
    private boolean allowNegative;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /**
     * Wrapper type on purpose: the id is assigned (= account id), so a null version is how
     * Spring Data recognises a new row and calls persist() instead of merge().
     */
    @Version
    private Long version;
}
