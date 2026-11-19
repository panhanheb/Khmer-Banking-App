package com.khmerbank.auth.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * A bank customer. Identity (email/password, phone/SMS) lives in Firebase Authentication;
 * this row is created on the first authenticated API call and keyed by {@link #firebaseUid}.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Firebase Authentication UID (the {@code sub} of the Firebase ID token). */
    @Column(name = "firebase_uid", unique = true)
    private String firebaseUid;

    /** E.164; {@code null} until a phone number is linked in Firebase. */
    @Column(unique = true)
    private String phone;

    private String email;

    @Column(name = "pin_hash")
    private String pinHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status = UserStatus.ACTIVE;

    @Column(name = "phone_verified", nullable = false)
    private boolean phoneVerified;

    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified;

    @Column(name = "failed_pin_attempts", nullable = false)
    private int failedPinAttempts;

    @Column(name = "pin_locked_until")
    private Instant pinLockedUntil;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false)
    private KycStatus kycStatus = KycStatus.NOT_STARTED;

    @Column(nullable = false)
    private String language = "km";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    public boolean isPinLocked(Instant now) {
        return pinLockedUntil != null && pinLockedUntil.isAfter(now);
    }
}
