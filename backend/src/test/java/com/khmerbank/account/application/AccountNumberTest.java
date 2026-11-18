package com.khmerbank.account.application;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AccountNumberTest {

    @Test
    void luhnCheckDigit() {
        // Standard Luhn example: 7992739871 → check digit 3
        assertThat(AccountService.luhnCheckDigit("7992739871")).isEqualTo(3);
        assertThat(AccountService.luhnCheckDigit("00110000001")).isBetween(0, 9);
    }
}
