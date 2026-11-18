package com.khmerbank.auth.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "user_profiles")
@Getter
@Setter
@NoArgsConstructor
public class UserProfile {

    /** Same value as users.id (shared primary key). */
    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "full_name_en", nullable = false)
    private String fullNameEn;

    @Column(name = "full_name_km")
    private String fullNameKm;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    private String gender;

    @Column(nullable = false)
    private String nationality = "KH";

    @Column(name = "address_line")
    private String addressLine;

    private String city;

    private String province;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
