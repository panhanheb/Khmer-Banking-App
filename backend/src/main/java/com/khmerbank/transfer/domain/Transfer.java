package com.khmerbank.transfer.domain;

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

@Entity
@Table(name = "transfers")
@Getter
@Setter
@NoArgsConstructor
public class Transfer {

    public enum Type { OWN, INTERNAL, INTERBANK }

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "transaction_id", nullable = false, unique = true)
    private UUID transactionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "transfer_type", nullable = false)
    private Type transferType;

    @Column(name = "source_account_id", nullable = false)
    private UUID sourceAccountId;

    @Column(name = "destination_account_id")
    private UUID destinationAccountId;

    @Column(name = "destination_account_number", nullable = false)
    private String destinationAccountNumber;

    @Column(name = "destination_bank_code", nullable = false)
    private String destinationBankCode = "KDB";

    @Column(name = "destination_name")
    private String destinationName;

    @Column(name = "debit_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal debitAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "debit_currency", nullable = false)
    private CurrencyCode debitCurrency;

    @Column(name = "credit_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal creditAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "credit_currency", nullable = false)
    private CurrencyCode creditCurrency;

    @Column(name = "exchange_rate", nullable = false, precision = 19, scale = 8)
    private BigDecimal exchangeRate;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal fee;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
