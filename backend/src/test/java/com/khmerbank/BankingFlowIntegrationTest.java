package com.khmerbank;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.khmerbank.common.error.ApiException;
import com.khmerbank.common.money.CurrencyCode;
import com.khmerbank.transfer.api.TransferDtos.TransferRequest;
import com.khmerbank.transfer.application.TransferService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DataAccessException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadLocalRandom;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

/**
 * End-to-end tests against a real PostgreSQL (Testcontainers). Skipped automatically when Docker
 * is not available. Uses the dev profile for OTP echo and SIMULATED deposits.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@Testcontainers(disabledWithoutDocker = true)
@TestPropertySource(properties = {
        "app.rate-limit.store=memory",
        "app.rate-limit.auth-requests-per-minute=100000"
})
class BankingFlowIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    private static final String PASSWORD = "Str0ng!Pass";
    private static final String PIN = "246810";

    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;
    @Autowired
    JdbcTemplate jdbc;
    @Autowired
    TransferService transferService;

    record Customer(UUID userId, String phone, String token, String refreshToken,
                    String usdAccountId, String usdAccountNumber) {
    }

    // ---------------------------------------------------------------- scenarios

    @Test
    void unauthenticatedRequestsAreRejected() throws Exception {
        call(get("/api/v1/accounts"), null, null, 401);
    }

    @Test
    void transferMovesMoneyAndLedgerStaysBalanced() throws Exception {
        Customer alice = onboard("Alice Sok");
        Customer bob = onboard("Bob Chan");
        deposit(alice, "100.00");

        JsonNode receipt = transfer(alice, bob.usdAccountNumber(), "25.50", "USD", PIN, UUID.randomUUID().toString(), 201);
        assertThat(receipt.get("status").asText()).isEqualTo("COMPLETED");
        assertThat(receipt.get("reference").asText()).startsWith("KDB");
        assertThat(receipt.get("destinationName").asText()).isEqualTo("B*** Chan");

        assertThat(balance(alice)).isEqualByComparingTo("74.50");
        assertThat(balance(bob)).isEqualByComparingTo("25.50");

        JsonNode history = call(get("/api/v1/transactions?size=10"), null, bob.token(), 200);
        assertThat(history.get("content").get(0).get("direction").asText()).isEqualTo("CREDIT");
        assertThat(history.get("content").get(0).get("amount").asText()).isEqualTo("25.50");

        assertLedgerConsistent();
    }

    @Test
    void insufficientBalanceIsRejectedWithoutSideEffects() throws Exception {
        Customer alice = onboard("Alice Insufficient");
        Customer bob = onboard("Bob Insufficient");
        deposit(alice, "10.00");

        JsonNode err = transfer(alice, bob.usdAccountNumber(), "10.01", "USD", PIN, UUID.randomUUID().toString(), 422);
        assertThat(err.get("code").asText()).isEqualTo("INSUFFICIENT_BALANCE");
        assertThat(balance(alice)).isEqualByComparingTo("10.00");
        assertThat(balance(bob)).isEqualByComparingTo("0");
        assertLedgerConsistent();
    }

    @Test
    void duplicateRequestWithSameIdempotencyKeyExecutesOnce() throws Exception {
        Customer alice = onboard("Alice Idem");
        Customer bob = onboard("Bob Idem");
        deposit(alice, "50.00");
        String key = UUID.randomUUID().toString();

        JsonNode first = transfer(alice, bob.usdAccountNumber(), "20.00", "USD", PIN, key, 201);
        JsonNode replay = transfer(alice, bob.usdAccountNumber(), "20.00", "USD", PIN, key, 200);
        assertThat(replay.get("transactionId").asText()).isEqualTo(first.get("transactionId").asText());
        assertThat(balance(alice)).isEqualByComparingTo("30.00");

        JsonNode conflict = transfer(alice, bob.usdAccountNumber(), "21.00", "USD", PIN, key, 409);
        assertThat(conflict.get("code").asText()).isEqualTo("IDEMPOTENCY_CONFLICT");
        assertThat(balance(alice)).isEqualByComparingTo("30.00");
    }

    @Test
    void missingIdempotencyKeyIsRejected() throws Exception {
        Customer alice = onboard("Alice NoKey");
        Customer bob = onboard("Bob NoKey");
        JsonNode err = call(post("/api/v1/transfers"), transferBody(alice, bob.usdAccountNumber(), "1.00", "USD", PIN),
                alice.token(), 400);
        assertThat(err.get("code").asText()).isEqualTo("IDEMPOTENCY_KEY_REQUIRED");
    }

    @Test
    void invalidPinIsRejectedAndLocksAfterFiveAttempts() throws Exception {
        Customer alice = onboard("Alice Pin");
        Customer bob = onboard("Bob Pin");
        deposit(alice, "10.00");

        for (int i = 1; i <= 4; i++) {
            JsonNode err = transfer(alice, bob.usdAccountNumber(), "1.00", "USD", "135790",
                    UUID.randomUUID().toString(), 400);
            assertThat(err.get("code").asText()).isEqualTo("INVALID_PIN");
        }
        transfer(alice, bob.usdAccountNumber(), "1.00", "USD", "135790", UUID.randomUUID().toString(), 423);
        // Even the correct PIN is refused while locked.
        transfer(alice, bob.usdAccountNumber(), "1.00", "USD", PIN, UUID.randomUUID().toString(), 423);
        assertThat(balance(alice)).isEqualByComparingTo("10.00");
    }

    @Test
    void crossCurrencyTransferUsesBuyRate() throws Exception {
        Customer alice = onboard("Alice Fx");
        Customer bob = onboard("Bob Fx");
        JsonNode khr = call(post("/api/v1/accounts"), Map.of("type", "SAVINGS", "currency", "KHR"), bob.token(), 201);
        deposit(alice, "20.00");

        JsonNode receipt = transfer(alice, khr.get("accountNumber").asText(), "10.00", "USD", PIN,
                UUID.randomUUID().toString(), 201);
        assertThat(receipt.get("creditAmount").asText()).isEqualTo("40800");
        assertThat(receipt.get("creditCurrency").asText()).isEqualTo("KHR");
        assertThat(balance(alice)).isEqualByComparingTo("10.00");
        assertLedgerConsistent();
    }

    @Test
    void concurrentTransfersNeverOverdraw() throws Exception {
        Customer alice = onboard("Alice Concurrent");
        Customer bob = onboard("Bob Concurrent");
        deposit(alice, "100.00");

        ExecutorService pool = Executors.newFixedThreadPool(8);
        List<Callable<Boolean>> jobs = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            jobs.add(() -> {
                try {
                    transferService.execute(alice.userId(), new TransferRequest(UUID.fromString(alice.usdAccountId()),
                            bob.usdAccountNumber(), "10.00", CurrencyCode.USD, null, PIN),
                            UUID.randomUUID().toString(), null);
                    return true;
                } catch (ApiException e) {
                    return false;
                }
            });
        }
        int ok = 0;
        for (Future<Boolean> f : pool.invokeAll(jobs)) {
            if (f.get()) {
                ok++;
            }
        }
        pool.shutdown();

        assertThat(ok).isEqualTo(10);
        assertThat(balance(alice)).isEqualByComparingTo("0");
        assertThat(balance(bob)).isEqualByComparingTo("100.00");
        assertLedgerConsistent();
    }

    @Test
    void ledgerEntriesAndAuditLogsAreImmutable() throws Exception {
        Customer alice = onboard("Alice Immutable");
        deposit(alice, "5.00");
        assertThatThrownBy(() -> jdbc.update("UPDATE transaction_entries SET amount = amount + 1"))
                .isInstanceOf(DataAccessException.class);
        assertThatThrownBy(() -> jdbc.update("DELETE FROM transaction_entries"))
                .isInstanceOf(DataAccessException.class);
        assertThatThrownBy(() -> jdbc.update("DELETE FROM audit_logs"))
                .isInstanceOf(DataAccessException.class);
    }

    @Test
    void refreshTokenRotationDetectsReuse() throws Exception {
        Customer alice = onboard("Alice Refresh");
        JsonNode rotated = call(post("/api/v1/auth/refresh"), Map.of("refreshToken", alice.refreshToken()), null, 200);
        String second = rotated.get("refreshToken").asText();
        assertThat(second).isNotEqualTo(alice.refreshToken());

        // Re-using the first token revokes the whole family, including the second one.
        call(post("/api/v1/auth/refresh"), Map.of("refreshToken", alice.refreshToken()), null, 401);
        call(post("/api/v1/auth/refresh"), Map.of("refreshToken", second), null, 401);
    }

    @Test
    void repeatedWrongPasswordsLockTheAccount() throws Exception {
        Customer alice = onboard("Alice Lockout");
        Map<String, Object> bad = Map.of("phone", alice.phone(), "password", "Wr0ng!Pass",
                "deviceId", "device-" + alice.phone(), "platform", "ANDROID");
        for (int i = 0; i < 4; i++) {
            call(post("/api/v1/auth/login"), bad, null, 401);
        }
        call(post("/api/v1/auth/login"), bad, null, 423);
        Map<String, Object> good = new HashMap<>(bad);
        good.put("password", PASSWORD);
        call(post("/api/v1/auth/login"), good, null, 423);
    }

    @Test
    void newDeviceRequiresOtpButTrustedDeviceDoesNot() throws Exception {
        Customer alice = onboard("Alice Device");
        JsonNode trusted = call(post("/api/v1/auth/login"), Map.of("phone", alice.phone(), "password", PASSWORD,
                "deviceId", "device-" + alice.phone(), "platform", "ANDROID"), null, 200);
        assertThat(trusted.get("mfaRequired").asBoolean()).isFalse();

        JsonNode fresh = call(post("/api/v1/auth/login"), Map.of("phone", alice.phone(), "password", PASSWORD,
                "deviceId", "another-device", "platform", "IOS"), null, 200);
        assertThat(fresh.get("mfaRequired").asBoolean()).isTrue();
        assertThat(fresh.has("tokens")).isFalse();
    }

    // ---------------------------------------------------------------- helpers

    private Customer onboard(String name) throws Exception {
        String phone = "+85512" + ThreadLocalRandom.current().nextInt(100_000, 999_999);
        JsonNode reg = call(post("/api/v1/auth/register"),
                Map.of("phone", phone, "password", PASSWORD, "fullNameEn", name), null, 201);
        call(post("/api/v1/auth/otp/verify"),
                Map.of("challengeId", reg.get("challengeId").asText(), "code", reg.get("devOtp").asText()), null, 200);

        String deviceId = "device-" + phone;
        JsonNode login = call(post("/api/v1/auth/login"),
                Map.of("phone", phone, "password", PASSWORD, "deviceId", deviceId, "platform", "ANDROID"), null, 200);
        assertThat(login.get("mfaRequired").asBoolean()).isTrue();
        JsonNode tokens = call(post("/api/v1/auth/login/mfa"), Map.of(
                "challengeId", login.get("challengeId").asText(), "code", login.get("devOtp").asText(),
                "deviceId", deviceId, "platform", "ANDROID"), null, 200);
        String token = tokens.get("accessToken").asText();

        call(put("/api/v1/auth/pin"), Map.of("newPin", PIN), token, 204);
        JsonNode me = call(get("/api/v1/users/me"), null, token, 200);
        JsonNode accounts = call(get("/api/v1/accounts"), null, token, 200);
        JsonNode usd = accounts.get(0);
        assertThat(usd.get("currency").asText()).isEqualTo("USD");
        return new Customer(UUID.fromString(me.get("id").asText()), phone, token,
                tokens.get("refreshToken").asText(), usd.get("id").asText(), usd.get("accountNumber").asText());
    }

    private void deposit(Customer c, String amount) throws Exception {
        call(post("/api/v1/dev/accounts/" + c.usdAccountId() + "/deposit")
                        .header("Idempotency-Key", UUID.randomUUID().toString()),
                Map.of("amount", amount), c.token(), 201);
    }

    private BigDecimal balance(Customer c) throws Exception {
        JsonNode acc = call(get("/api/v1/accounts/" + c.usdAccountId()), null, c.token(), 200);
        return new BigDecimal(acc.get("balance").asText());
    }

    private Map<String, Object> transferBody(Customer from, String to, String amount, String currency, String pin) {
        return Map.of("sourceAccountId", from.usdAccountId(), "destinationAccountNumber", to,
                "amount", amount, "currency", currency, "pin", pin);
    }

    private JsonNode transfer(Customer from, String to, String amount, String currency, String pin, String key,
                              int expectedStatus) throws Exception {
        return call(post("/api/v1/transfers").header("Idempotency-Key", key),
                transferBody(from, to, amount, currency, pin), from.token(), expectedStatus);
    }

    private JsonNode call(MockHttpServletRequestBuilder req, Object body, String token, int expectedStatus)
            throws Exception {
        if (body != null) {
            req.contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(body));
        }
        if (token != null) {
            req.header("Authorization", "Bearer " + token);
        }
        MvcResult result = mvc.perform(req).andReturn();
        String content = result.getResponse().getContentAsString();
        assertThat(result.getResponse().getStatus()).as("HTTP status, body: %s", content).isEqualTo(expectedStatus);
        return content.isEmpty() ? json.nullNode() : json.readTree(content);
    }

    private void assertLedgerConsistent() {
        Integer mismatched = jdbc.queryForObject(
                "SELECT count(*) FROM v_ledger_reconciliation WHERE difference <> 0", Integer.class);
        assertThat(mismatched).as("accounts whose balance differs from their entries").isZero();
        List<BigDecimal> nets = jdbc.queryForList("SELECT net_balance FROM v_ledger_trial_balance", BigDecimal.class);
        assertThat(nets).allSatisfy(n -> assertThat(n).isEqualByComparingTo("0"));
        Integer negatives = jdbc.queryForObject(
                "SELECT count(*) FROM account_balances WHERE NOT allow_negative AND ledger_balance < 0", Integer.class);
        assertThat(negatives).isZero();
    }
}
