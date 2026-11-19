package com.khmerbank.account.infrastructure;

import com.khmerbank.account.domain.AccountBalance;
import jakarta.persistence.LockModeType;
import jakarta.persistence.QueryHint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.QueryHints;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AccountBalanceRepository extends JpaRepository<AccountBalance, UUID> {

    /** SELECT ... FOR UPDATE with a 5 s lock timeout. Callers must lock in a deterministic order. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints(@QueryHint(name = "jakarta.persistence.lock.timeout", value = "5000"))
    @Query("select b from AccountBalance b where b.accountId = :id")
    Optional<AccountBalance> findByIdForUpdate(@Param("id") UUID id);

    List<AccountBalance> findByAccountIdIn(Collection<UUID> ids);
}
