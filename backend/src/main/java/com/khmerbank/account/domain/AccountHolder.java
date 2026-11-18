package com.khmerbank.account.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.util.UUID;

/** Read model of account ownership (supports joint accounts). Rows are inserted via the repository. */
@Entity
@Table(name = "account_holders")
@IdClass(AccountHolder.Key.class)
@Getter
@Setter
@NoArgsConstructor
public class AccountHolder {

    @Getter
    @Setter
    @NoArgsConstructor
    @lombok.AllArgsConstructor
    @lombok.EqualsAndHashCode
    public static class Key implements Serializable {
        private UUID accountId;
        private UUID userId;
    }

    @Id
    @Column(name = "account_id")
    private UUID accountId;

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "holder_role", nullable = false)
    private String holderRole;
}
