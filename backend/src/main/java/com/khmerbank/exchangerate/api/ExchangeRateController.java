package com.khmerbank.exchangerate.api;

import com.khmerbank.common.money.Money;
import com.khmerbank.exchangerate.application.ExchangeRateService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/exchange-rates")
@Tag(name = "Exchange rates")
public class ExchangeRateController {

    public record RateResponse(String baseCurrency, String quoteCurrency, String buyRate, String sellRate,
                               String midRate, Instant effectiveAt) {
    }

    private final ExchangeRateService service;

    public ExchangeRateController(ExchangeRateService service) {
        this.service = service;
    }

    @GetMapping
    public List<RateResponse> current() {
        return service.current().stream()
                .map(r -> new RateResponse(r.getBaseCurrency().name(), r.getQuoteCurrency().name(),
                        Money.formatRate(r.getBuyRate()), Money.formatRate(r.getSellRate()),
                        Money.formatRate(r.getMidRate()), r.getEffectiveAt()))
                .toList();
    }
}
