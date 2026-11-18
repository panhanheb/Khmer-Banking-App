package com.khmerbank.account.infrastructure;

import com.khmerbank.account.domain.AccountStatus;
import com.khmerbank.account.domain.BankAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BankAccountRepository extends JpaRepository<BankAccount, UUID> {

    @Query("""
            select a from BankAccount a
            where a.id in (select h.accountId from AccountHolder h where h.userId = :userId)
              and a.status <> :excluded
            order by a.openedAt
            """)
    List<BankAccount> findByHolderExcludingStatus(@Param("userId") UUID userId,
                                                  @Param("excluded") AccountStatus excluded);

    /** System accounts never have holders, so this returns customer accounts only. */
    default List<BankAccount> findOpenByHolder(UUID userId) {
        return findByHolderExcludingStatus(userId, AccountStatus.CLOSED);
    }

    @Query("""
            select a from BankAccount a
            where a.id = :id
              and a.id in (select h.accountId from AccountHolder h where h.userId = :userId)
            """)
    Optional<BankAccount> findByIdAndHolder(@Param("id") UUID id, @Param("userId") UUID userId);

    Optional<BankAccount> findByAccountNumber(String accountNumber);

    Optional<BankAccount> findBySystemCode(String systemCode);

    List<BankAccount> findByPrimaryHolderIdAndStatusOrderByOpenedAt(UUID holderId, AccountStatus status);

    long countByPrimaryHolderIdAndStatusNot(UUID holderId, AccountStatus status);

    @Query(value = "SELECT nextval('account_number_seq')", nativeQuery = true)
    long nextAccountSequence();

    @Modifying
    @Query(value = "INSERT INTO account_holders (account_id, user_id, holder_role) VALUES (:accountId, :userId, 'PRIMARY')",
            nativeQuery = true)
    void addPrimaryHolder(@Param("accountId") UUID accountId, @Param("userId") UUID userId);
}
