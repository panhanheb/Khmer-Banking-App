package com.khmerbank.ledger.domain;

import com.khmerbank.common.money.CurrencyCode;

import java.math.BigDecimal;
import java.util.UUID;

/** One requested ledger line. A balanced list of postings forms a journal entry. */
public record Posting(UUID accountId, TransactionEntry.Direction direction, BigDecimal amount, CurrencyCode currency) {

    public static Posting debit(UUID accountId, BigDecimal amount, CurrencyCode currency) {
        return new Posting(accountId, TransactionEntry.Direction.DEBIT, amount, currency);
    }

    public static Posting credit(UUID accountId, BigDecimal amount, CurrencyCode currency) {
        return new Posting(accountId, TransactionEntry.Direction.CREDIT, amount, currency);
    }
}
