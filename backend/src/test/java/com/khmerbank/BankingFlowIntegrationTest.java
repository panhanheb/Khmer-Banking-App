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
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.dao.DataAccessException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

/**
 * End-to-end tests against a real PostgreSQL (Testcontainers). Skipped automatically when Docker
 * is not available. Uses the dev profile for SIMULATED deposits.
 *
 * <p>Firebase ID tokens are replaced by {@link TestFirebaseTokens}: the bearer token
 * {@code uid|phone|name|authTimeEpochSeconds} is decoded into the claims a real Firebase token
 * would carry, so the whole API (user provisioning, devices, PIN, transfers) runs unchanged.
 */
@SpringBootTest
@Import(BankingFlowIntegrationTest.TestFirebaseTokens.class)
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

    private static final String PIN = "246810";

    /** Decodes {@code uid|phone|name|authTime} test tokens; {@code "invalid"} is rejected. */
    @TestConfiguration
    static class TestFirebaseTokens {

        @Bean
        @Primary
        JwtDecoder testFirebaseJwtDecoder() {
            return token -> {
                String[] parts = token.split("\\|");
                if (parts.length != 4) {
                    throw new BadJwtException("Malformed test token");
                }
                Instant now = Instant.now();
                return Jwt.withTokenValue(token)
                        .header("alg", "RS256")
                        .subject(parts[0])
                        .claim("phone_number", parts[1])
                        .claim("name", parts[2])
                        .claim("email", parts[0] + "@example.com")
                        .claim("email_verified", true)
                        .claim("auth_time", Long.parseLong(parts[3]))
                        .issuedAt(now)
                        .expiresAt(now.plusSeconds(3600))
                        .build();
            };
        }
    }

    @Autowired
    MockMvc mvc;
    @Autowired
    ObjectMapper json;
    @Autowired
    JdbcTemplate jdbc;
    @Autowired
    TransferService transferService;

    record Customer(UUID userId, String uid, String phone, String token,
                    String usdAccountId, String usdAccountNumber) {
    }

    // ---------------------------------------------------------------- scenarios

    @Test
    void unauthenticatedRequestsAreRejected() throws Exception {
        call(get("/api/v1/accounts"), null, null, 401);
        JsonNode err = call(get("/api/v1/accounts"), null, "invalid", 401);
        assertThat(err.get("code").asText()).isEqualTo("TOKEN_INVALID");
    }

    @Test
    void firstRequestProvisionsUserFromFirebaseClaims() throws Exception {
        Customer alice = onboard("Alice Provisioned");
        JsonNode me = call(get("/api/v1/users/me"), null, alice.token(), 200);
        assertThat(me.get("phone").asText()).isEqualTo(alice.phone());
        assertThat(me.get("email").asText()).isEqualTo(alice.uid() + "@example.com");
        assertThat(me.get("fullNameEn").asText()).isEqualTo("Alice Provisioned");
        assertThat(me.get("pinSet").asBoolean()).isTrue();

        // Subsequent requests reuse the same user and do not open another account.
        JsonNode accounts = call(get("/api/v1/accounts"), null, alice.token(), 200);
        assertThat(accounts.size()).isEqualTo(1);
        Integer rows = jdbc.queryForObject("SELECT count(*) FROM users WHERE firebase_uid = ?", Integer.class,
                alice.uid());
        assertThat(rows).isEqualTo(1);
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
    void revokedDeviceIsBlockedUntilTheUserSignsInAgain() throws Exception {
        Customer alice = onboard("Alice Device");
        call(onDevice(get("/api/v1/accounts"), "phone-a", "ANDROID"), null, alice.token(), 200);
        call(onDevice(get("/api/v1/accounts"), "tablet-b", "IOS"), null, alice.token(), 200);

        JsonNode list = call(onDevice(get("/api/v1/auth/devices"), "phone-a", "ANDROID"), null, alice.token(), 200);
        assertThat(list.size()).isEqualTo(2);
        String tablet = null;
        for (JsonNode d : list) {
            if (!d.get("current").asBoolean()) {
                tablet = d.get("id").asText();
            }
        }
        assertThat(tablet).isNotNull();
        call(onDevice(delete("/api/v1/auth/devices/" + tablet), "phone-a", "ANDROID"), null, alice.token(), 204);

        JsonNode err = call(onDevice(get("/api/v1/accounts"), "tablet-b", "IOS"), null, alice.token(), 401);
        assertThat(err.get("code").asText()).isEqualTo("DEVICE_REVOKED");
        call(onDevice(get("/api/v1/accounts"), "phone-a", "ANDROID"), null, alice.token(), 200);

        // Signing in again on the tablet (newer auth_time) restores access.
        String fresh = token(alice.uid(), alice.phone(), "Alice Device", Instant.now().plusSeconds(5));
        call(onDevice(get("/api/v1/accounts"), "tablet-b", "IOS"), null, fresh, 200);
    }

    // ---------------------------------------------------------------- helpers

    /** Simulates a Firebase user that has signed in (email/password + verified phone). */
    private Customer onboard(String name) throws Exception {
        String uid = "uid-" + UUID.randomUUID();
        String phone = "+85512" + ThreadLocalRandom.current().nextInt(100_000, 999_999);
        String token = token(uid, phone, name, Instant.now().minusSeconds(60));

        call(put("/api/v1/auth/pin"), Map.of("newPin", PIN), token, 204);
        JsonNode me = call(get("/api/v1/users/me"), null, token, 200);
        JsonNode accounts = call(get("/api/v1/accounts"), null, token, 200);
        JsonNode usd = accounts.get(0);
        assertThat(usd.get("currency").asText()).isEqualTo("USD");
        return new Customer(UUID.fromString(me.get("id").asText()), uid, phone, token,
                usd.get("id").asText(), usd.get("accountNumber").asText());
    }

    private static String token(String uid, String phone, String name, Instant authTime) {
        return uid + "|" + phone + "|" + name + "|" + authTime.getEpochSecond();
    }

    private static MockHttpServletRequestBuilder onDevice(MockHttpServletRequestBuilder req, String deviceId,
                                                          String platform) {
        return req.header("X-Device-Id", deviceId).header("X-Device-Name", deviceId)
                .header("X-Device-Platform", platform);
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
