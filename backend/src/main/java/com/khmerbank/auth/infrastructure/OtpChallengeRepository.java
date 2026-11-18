package com.khmerbank.auth.infrastructure;

import com.khmerbank.auth.domain.OtpChallenge;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface OtpChallengeRepository extends JpaRepository<OtpChallenge, UUID> {
}
