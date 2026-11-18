package com.khmerbank.auth.infrastructure;

import com.khmerbank.auth.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByPhone(String phone);

    boolean existsByPhone(String phone);

    boolean existsByEmailIgnoreCase(String email);

    @Modifying
    @Query(value = "INSERT INTO user_roles (user_id, role_id) SELECT :userId, id FROM roles WHERE code = :role",
            nativeQuery = true)
    void assignRole(@Param("userId") UUID userId, @Param("role") String role);
}
