package com.khmerbank.exchangerate.domain;

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

/**
 * Rates quoted as units of {@code quote} per 1 {@code base} (USD/KHR 4100 = 1 USD buys 4,100 KHR).
 * buyRate: bank buys base from customer. sellRate: bank sells base to customer.
 */
@Entity
@Table(name = "exchange_rates")
@Getter
@Setter
@NoArgsConstructor
public class ExchangeRate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "base_currency", nullable = false)
    private CurrencyCode baseCurrency;

    @Enumerated(EnumType.STRING)
    @Column(name = "quote_currency", nullable = false)
    private CurrencyCode quoteCurrency;

    @Column(name = "buy_rate", nullable = false, precision = 19, scale = 8)
    private BigDecimal buyRate;

    @Column(name = "sell_rate", nullable = false, precision = 19, scale = 8)
    private BigDecimal sellRate;

    @Column(name = "mid_rate", nullable = false, precision = 19, scale = 8)
    private BigDecimal midRate;

    @Column(name = "effective_at", nullable = false)
    private Instant effectiveAt;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
