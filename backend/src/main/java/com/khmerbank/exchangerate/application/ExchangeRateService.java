package com.khmerbank.exchangerate.application;

import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.error.ErrorCode;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.exchangerate.domain.ExchangeRate;
import com.khmerbank.exchangerate.infrastructure.ExchangeRateRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.Instant;
import java.util.List;

@Service
public class ExchangeRateService {

    /** Result of converting between currencies. {@code rate} is quote-per-base as applied. */
    public record Conversion(BigDecimal debitAmount, BigDecimal creditAmount, BigDecimal rate) {
    }

    private final ExchangeRateRepository repository;
    private final Clock clock;

    public ExchangeRateService(ExchangeRateRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<ExchangeRate> current() {
        return repository
                .findFirstByBaseCurrencyAndQuoteCurrencyAndEffectiveAtLessThanEqualOrderByEffectiveAtDesc(
                        CurrencyCode.USD, CurrencyCode.KHR, Instant.now(clock))
                .map(List::of).orElse(List.of());
    }

    /**
     * Converts for a customer moving money from {@code from} to {@code to}.
     * {@code amount} is expressed in {@code amountCurrency}, which must be {@code from} or {@code to}.
     * Rounding always favours neither side unfairly: credits round down, debits round up, to the
     * currency's minor unit.
     */
    @Transactional(readOnly = true)
    public Conversion convert(CurrencyCode from, CurrencyCode to, BigDecimal amount, CurrencyCode amountCurrency) {
        if (amountCurrency != from && amountCurrency != to) {
            throw new ApiException(ErrorCode.CURRENCY_MISMATCH,
                    "Amount currency must match the source or destination account currency");
        }
        if (from == to) {
            return new Conversion(amount, amount, BigDecimal.ONE);
        }
        ExchangeRate r = repository
                .findFirstByBaseCurrencyAndQuoteCurrencyAndEffectiveAtLessThanEqualOrderByEffectiveAtDesc(
                        CurrencyCode.USD, CurrencyCode.KHR, Instant.now(clock))
                .orElseThrow(() -> new ApiException(ErrorCode.CURRENCY_MISMATCH, "No exchange rate available"));

        BigDecimal debit;
        BigDecimal credit;
        BigDecimal rate;
        if (from == CurrencyCode.USD) {
            // Customer sells USD → bank buys USD at buyRate.
            rate = r.getBuyRate();
            if (amountCurrency == from) {
                debit = amount;
                credit = to.round(amount.multiply(rate), RoundingMode.DOWN);
            } else {
                credit = amount;
                debit = from.round(amount.divide(rate, MathContext.DECIMAL128), RoundingMode.UP);
            }
        } else {
            // Customer buys USD with KHR → bank sells USD at sellRate.
            rate = r.getSellRate();
            if (amountCurrency == from) {
                debit = amount;
                credit = to.round(amount.divide(rate, MathContext.DECIMAL128), RoundingMode.DOWN);
            } else {
                credit = amount;
                debit = from.round(amount.multiply(rate), RoundingMode.UP);
            }
        }
        if (debit.signum() <= 0 || credit.signum() <= 0) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Amount is too small to convert");
        }
        return new Conversion(debit, credit, rate);
    }
}
