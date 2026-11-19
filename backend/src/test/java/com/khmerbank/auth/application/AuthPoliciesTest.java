package com.khmerbank.auth.application;

import com.khmerbank.common.error.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AuthPoliciesTest {

    @Test
    void normalizesCambodianPhones() {
        assertThat(PhoneNumbers.normalize("012 345 678")).isEqualTo("+85512345678");
        assertThat(PhoneNumbers.normalize("85512345678")).isEqualTo("+85512345678");
        assertThat(PhoneNumbers.normalize("0085512345678")).isEqualTo("+85512345678");
        assertThat(PhoneNumbers.normalize("+855 97 123 4567")).isEqualTo("+855971234567");
    }

    @Test
    void rejectsInvalidPhones() {
        assertThatThrownBy(() -> PhoneNumbers.normalize("+14155550100")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> PhoneNumbers.normalize("123")).isInstanceOf(ApiException.class);
    }

    @Test
    void pinPolicy() {
        assertThatCode(() -> PasswordPolicy.validatePin("246810")).doesNotThrowAnyException();
        assertThatThrownBy(() -> PasswordPolicy.validatePin("123456")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> PasswordPolicy.validatePin("12345")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> PasswordPolicy.validatePin("12a456")).isInstanceOf(ApiException.class);
    }
}
