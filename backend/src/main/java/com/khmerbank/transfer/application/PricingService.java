package com.khmerbank.transfer.application;

import com.khmerbank.common.config.AppProperties;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.ledger.domain.LedgerTransaction;
import com.khmerbank.ledger.infrastructure.LedgerTransactionRepository;
import com.khmerbank.transfer.domain.Transfer;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Fees (fee_rules) and limits (transaction_limits), both configurable in the database. */
@Service
public class PricingService {

    public record Limits(BigDecimal perTransactionMax, BigDecimal dailyMax) {
    }

    private final NamedParameterJdbcTemplate jdbc;
    private final LedgerTransactionRepository transactions;
    private final AppProperties props;
    private final Clock clock;

    public PricingService(NamedParameterJdbcTemplate jdbc, LedgerTransactionRepository transactions,
                          AppProperties props, Clock clock) {
        this.jdbc = jdbc;
        this.transactions = transactions;
        this.props = props;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public BigDecimal transferFee(Transfer.Type type, CurrencyCode currency, BigDecimal amount) {
        var params = new MapSqlParameterSource()
                .addValue("tt", type.name())
                .addValue("c", currency.name());
        List<BigDecimal> fees = jdbc.query("""
                SELECT flat_fee, percent_fee, min_fee, max_fee FROM fee_rules
                WHERE active AND transaction_type = 'TRANSFER' AND currency = :c AND transfer_type IN (:tt, 'ANY')
                ORDER BY (transfer_type = :tt) DESC LIMIT 1
                """, params, (rs, i) -> {
            BigDecimal fee = rs.getBigDecimal("flat_fee").add(amount.multiply(rs.getBigDecimal("percent_fee")));
            fee = fee.max(rs.getBigDecimal("min_fee"));
            BigDecimal max = rs.getBigDecimal("max_fee");
            if (max != null) {
                fee = fee.min(max);
            }
            return currency.round(fee, RoundingMode.HALF_UP);
        });
        return fees.isEmpty() ? currency.round(BigDecimal.ZERO, RoundingMode.UNNECESSARY) : fees.getFirst();
    }

    @Transactional(readOnly = true)
    public Limits transferLimits(UUID userId, CurrencyCode currency) {
        var params = new MapSqlParameterSource().addValue("u", userId).addValue("c", currency.name());
        List<Limits> limits = jdbc.query("""
                SELECT per_transaction_max, daily_max FROM transaction_limits
                WHERE active AND transaction_type = 'TRANSFER' AND currency = :c
                  AND (scope = 'DEFAULT' OR (scope = 'USER' AND user_id = :u))
                ORDER BY (scope = 'USER') DESC LIMIT 1
                """, params, (rs, i) -> new Limits(rs.getBigDecimal(1), rs.getBigDecimal(2)));
        if (limits.isEmpty()) {
            // Fail closed: never allow unlimited transfers because of missing configuration.
            throw new ApiException(ErrorCode.LIMIT_EXCEEDED, "No transfer limit configured for " + currency);
        }
        return limits.getFirst();
    }

    /** Amount already transferred today (Asia/Phnom_Penh calendar day). */
    @Transactional(readOnly = true)
    public BigDecimal usedToday(UUID userId, CurrencyCode currency) {
        var startOfDay = LocalDate.now(clock.withZone(props.zone())).atStartOfDay(props.zone()).toInstant();
        return transactions.sumCompletedSince(userId, LedgerTransaction.Type.TRANSFER, currency, startOfDay);
    }
}
