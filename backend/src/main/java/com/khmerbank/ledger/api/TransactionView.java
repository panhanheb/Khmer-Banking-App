package com.khmerbank.ledger.api;

import java.time.Instant;
import java.util.UUID;

/** A transaction as seen from one of the requesting user's accounts. */
public record TransactionView(
        UUID id,
        String reference,
        String type,
        String status,
        String direction,
        String amount,
        String fee,
        String currency,
        String description,
        String counterpartyName,
        String counterpartyAccount,
        UUID accountId,
        boolean simulated,
        Instant createdAt) {
}
