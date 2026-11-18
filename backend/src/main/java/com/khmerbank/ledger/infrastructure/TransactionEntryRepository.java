package com.khmerbank.ledger.infrastructure;

import com.khmerbank.ledger.domain.TransactionEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TransactionEntryRepository extends JpaRepository<TransactionEntry, Long> {

    List<TransactionEntry> findByTransactionIdOrderById(UUID transactionId);
}
