package com.khmerbank.ledger.application;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.common.money.Masking;
import com.khmerbank.common.money.Money;
import com.khmerbank.common.web.PageResponse;
import com.khmerbank.ledger.api.TransactionView;
import com.khmerbank.ledger.domain.LedgerTransaction;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Read model over the immutable ledger. One row per (transaction, own account), so a transfer
 * between two of the user's own accounts shows up on both accounts.
 */
@Service
public class TransactionQueryService {

    public record Filter(UUID accountId, UUID transactionId, Instant from, Instant to,
                         LedgerTransaction.Type type, LedgerTransaction.Status status,
                         CurrencyCode currency, String q) {
    }

    private static final String CTE = """
            WITH mine AS (
                SELECT e.transaction_id, e.account_id,
                       SUM(CASE WHEN e.direction = 'DEBIT'  THEN e.amount ELSE 0 END) AS debit_total,
                       SUM(CASE WHEN e.direction = 'CREDIT' THEN e.amount ELSE 0 END) AS credit_total,
                       MAX(e.currency) AS entry_currency
                FROM transaction_entries e
                JOIN account_holders h ON h.account_id = e.account_id AND h.user_id = :userId
                %s
                GROUP BY e.transaction_id, e.account_id
            )
            """;

    private static final String FROM = """
            FROM mine m
            JOIN transactions t ON t.id = m.transaction_id
            LEFT JOIN transfers tr ON tr.transaction_id = t.id
            LEFT JOIN bank_accounts sa ON sa.id = tr.source_account_id
            LEFT JOIN user_profiles sp ON sp.user_id = sa.primary_holder_id
            WHERE 1 = 1 %s
            """;

    private final NamedParameterJdbcTemplate jdbc;

    public TransactionQueryService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionView> search(UUID userId, Filter f, int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), 100);
        int safePage = Math.max(page, 0);
        MapSqlParameterSource params = new MapSqlParameterSource("userId", userId);

        String entryFilter = "";
        if (f.accountId() != null) {
            entryFilter = "WHERE e.account_id = :accountId";
            params.addValue("accountId", f.accountId());
        }
        StringBuilder where = new StringBuilder();
        if (f.transactionId() != null) {
            where.append(" AND t.id = :txnId");
            params.addValue("txnId", f.transactionId());
        }
        if (f.from() != null) {
            where.append(" AND t.created_at >= :from");
            params.addValue("from", Timestamp.from(f.from()));
        }
        if (f.to() != null) {
            where.append(" AND t.created_at < :to");
            params.addValue("to", Timestamp.from(f.to()));
        }
        if (f.type() != null) {
            where.append(" AND t.type = :type");
            params.addValue("type", f.type().name());
        }
        if (f.status() != null) {
            where.append(" AND t.status = :status");
            params.addValue("status", f.status().name());
        }
        if (f.currency() != null) {
            where.append(" AND m.entry_currency = :currency");
            params.addValue("currency", f.currency().name());
        }
        if (f.q() != null && !f.q().isBlank()) {
            where.append(" AND (t.reference ILIKE :q OR t.description ILIKE :q OR tr.destination_name ILIKE :q)");
            params.addValue("q", "%" + f.q().trim().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%");
        }
        String cte = CTE.formatted(entryFilter);
        String rest = FROM.formatted(where);

        Long total = jdbc.queryForObject(cte + " SELECT COUNT(*) " + rest, params, Long.class);

        params.addValue("limit", safeSize).addValue("offset", (long) safePage * safeSize);
        List<TransactionView> rows = jdbc.query(cte + """
                 SELECT t.id, t.reference, t.type, t.status, t.description, t.amount, t.fee,
                        t.currency AS txn_currency, t.simulated, t.created_at,
                        m.account_id, m.debit_total, m.credit_total, m.entry_currency,
                        tr.destination_name, tr.destination_account_number,
                        sa.account_number AS source_account_number, sp.full_name_en AS source_name
                """ + rest + " ORDER BY t.created_at DESC, t.id LIMIT :limit OFFSET :offset",
                params, (rs, i) -> map(rs));
        return PageResponse.of(rows, safePage, safeSize, total == null ? 0 : total);
    }

    @Transactional(readOnly = true)
    public TransactionView get(UUID userId, UUID transactionId) {
        Filter f = new Filter(null, transactionId, null, null, null, null, null, null);
        List<TransactionView> rows = search(userId, f, 0, 2).content();
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.NOT_FOUND, "Transaction not found");
        }
        // For an own-account transfer prefer the debit side.
        return rows.stream().filter(r -> "DEBIT".equals(r.direction())).findFirst().orElse(rows.getFirst());
    }

    private static TransactionView map(ResultSet rs) throws SQLException {
        BigDecimal debit = rs.getBigDecimal("debit_total");
        BigDecimal credit = rs.getBigDecimal("credit_total");
        boolean isDebit = debit.compareTo(credit) > 0;
        CurrencyCode entryCurrency = CurrencyCode.valueOf(rs.getString("entry_currency"));
        CurrencyCode txnCurrency = CurrencyCode.valueOf(rs.getString("txn_currency"));

        String amount;
        String fee;
        CurrencyCode currency;
        String counterpartyName;
        String counterpartyAccount;
        if (isDebit) {
            currency = txnCurrency;
            amount = Money.format(rs.getBigDecimal("amount"), txnCurrency);
            fee = Money.format(rs.getBigDecimal("fee"), txnCurrency);
            counterpartyName = rs.getString("destination_name");
            String dest = rs.getString("destination_account_number");
            counterpartyAccount = dest == null ? null : Masking.accountNumber(dest);
        } else {
            currency = entryCurrency;
            amount = Money.format(credit.subtract(debit), entryCurrency);
            fee = Money.format(BigDecimal.ZERO, entryCurrency);
            String srcName = rs.getString("source_name");
            counterpartyName = srcName == null ? null : Masking.name(srcName);
            String src = rs.getString("source_account_number");
            counterpartyAccount = src == null ? null : Masking.accountNumber(src);
        }
        if ("DEPOSIT".equals(rs.getString("type")) && counterpartyName == null) {
            counterpartyName = rs.getBoolean("simulated") ? "Simulated cash deposit" : "Cash deposit";
        }
        return new TransactionView(
                rs.getObject("id", UUID.class),
                rs.getString("reference"),
                rs.getString("type"),
                rs.getString("status"),
                isDebit ? "DEBIT" : "CREDIT",
                amount,
                fee,
                currency.name(),
                rs.getString("description"),
                counterpartyName,
                counterpartyAccount,
                rs.getObject("account_id", UUID.class),
                rs.getBoolean("simulated"),
                rs.getTimestamp("created_at").toInstant());
    }
}
