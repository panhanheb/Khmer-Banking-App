package com.khmerbank.exchangerate.infrastructure;

import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.exchangerate.domain.ExchangeRate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Optional;

public interface ExchangeRateRepository extends JpaRepository<ExchangeRate, Long> {

    Optional<ExchangeRate> findFirstByBaseCurrencyAndQuoteCurrencyAndEffectiveAtLessThanEqualOrderByEffectiveAtDesc(
            CurrencyCode base, CurrencyCode quote, Instant at);
}
