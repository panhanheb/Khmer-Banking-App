package com.khmerbank.common.money;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class MaskingTest {

    @Test
    void masksAccountPhoneAndName() {
        assertThat(Masking.accountNumber("001234567890")).isEqualTo("****7890");
        assertThat(Masking.phone("+85512345678")).isEqualTo("+855****5678");
        assertThat(Masking.name("Chan Sopheap")).isEqualTo("C*** Sopheap");
        assertThat(Masking.name("Dara")).isEqualTo("D***");
        assertThat(Masking.name(null)).isEqualTo("***");
    }
}
