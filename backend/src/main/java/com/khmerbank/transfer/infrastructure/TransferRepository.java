package com.khmerbank.transfer.infrastructure;

import com.khmerbank.transfer.domain.Transfer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface TransferRepository extends JpaRepository<Transfer, UUID> {

    Optional<Transfer> findByTransactionId(UUID transactionId);
}
