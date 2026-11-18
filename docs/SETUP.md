# Installation, Development & Deployment

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.47+ (Dart 3.13+) |
| Java | 21 |
| Maven | 3.9+ (or use Docker to build) |
| Docker + Compose | for PostgreSQL / Redis / Testcontainers |

## 1. Run the backend

```bash
cp .env.example .env          # then put real random values in .env
docker compose up --build     # postgres + redis + backend on :8080
```

Or run the backend from your IDE / Maven against the compose databases:

```bash
docker compose up -d postgres redis
cd backend
mvn spring-boot:run           # profile "dev" by default
```

* Swagger UI: http://localhost:8080/swagger-ui.html
* Health: http://localhost:8080/actuator/health

In the **dev** profile:
* OTP codes are logged (`[MOCK SMS]`) and returned as `devOtp` in API responses.
* `POST /api/v1/dev/accounts/{id}/deposit` adds **SIMULATED** money (flagged `simulated=true`).

## 2. Run the mobile app

```bash
flutter pub get
# Android emulator → host machine is 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
# iOS simulator / desktop
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Quick manual test: register → enter `devOtp` → log in (new device ⇒ OTP again) → set PIN →
fund the account with the dev deposit endpoint (Swagger) → register a second user → transfer.

## 3. Tests

```bash
cd backend && mvn verify      # unit tests + PostgreSQL integration tests (needs Docker)
flutter analyze && flutter test
```

Integration tests (`BankingFlowIntegrationTest`) cover: insufficient balance, duplicate request /
idempotency conflict, invalid PIN + lockout, concurrent transfers, cross-currency, login lockout,
new-device MFA, refresh-token reuse detection, ledger immutability, reconciliation invariants.
They are skipped automatically when Docker is unavailable.

## 4. Environment variables

| Variable | Required | Notes |
|---|---|---|
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | yes | PostgreSQL |
| `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` | prod | rate limiting / OTP throttling |
| `JWT_SECRET` | yes | ≥ 32 random bytes; rotate via deploy |
| `OTP_PEPPER` | yes | HMAC key for OTP hashes |
| `SPRING_PROFILES_ACTIVE` | yes | `dev` locally, `prod` in production |
| `APP_ENV` | yes | `prod` makes the app refuse to start with the dev profile or OTP echo |
| `RATE_LIMIT_STORE` | no | `redis` (default) or `memory` |

**Never commit secrets.** `.env` is git-ignored; production secrets belong in a vault / secret
manager (e.g. AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault).

## 5. Staging & production

* Build: `docker build -t khmer-bank-api ./backend` (CI builds on every push, see
  `.github/workflows/ci.yml`).
* Run ≥ 2 backend replicas behind a TLS-terminating load balancer (TLS 1.2+, HSTS). Set
  `server.forward-headers-strategy=framework` so client IPs in audit logs are correct.
* PostgreSQL: managed instance with a streaming replica, PITR (WAL archiving), daily snapshots
  kept 35 days; test restores monthly. Run `v_ledger_reconciliation` checks nightly.
* Redis: managed, with replica; persistence on.
* Observability: `/actuator/prometheus` → Prometheus/Grafana; ECS JSON logs (prod profile) →
  Loki/ELK, correlated by `X-Request-Id`.
* Before go-live, the external integrations listed in `ARCHITECTURE.md §6` need real, authorized
  credentials (SMS gateway, Bakong/KHQR, billers, telcos, card processor, FCM/APNs).
