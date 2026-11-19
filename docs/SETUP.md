# Installation & Development

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.47+ (Dart 3.13+) |
| Java | 21 |
| Maven | 3.9+ (or use Docker to build) |
| PostgreSQL 16+ | native install, or Docker + Compose (also for Redis / Testcontainers) |

## 1. Run the backend

```bash
cp .env.example .env          # then put real random values in .env
```

**With Docker** (Postgres + Redis + backend on :8080):

```bash
docker compose up --build
# or only the databases, and run the backend from VS Code (F5 → KhmerBankApplication):
docker compose up -d postgres redis
```

**Without Docker (Windows, native PostgreSQL)**: create the `khmerbank` role and database with
`DB_PASSWORD` from `.env` (asks for the `postgres` superuser password), then press F5 →
`KhmerBankApplication`:

```powershell
powershell -ExecutionPolicy Bypass -File backend\scripts\setup-local-db.ps1
```

The `dev` profile keeps rate limits in memory, so Redis is optional locally.

* Swagger UI: http://localhost:8080/swagger-ui.html
* Health: http://localhost:8080/actuator/health
* In the **dev** profile, `POST /api/v1/dev/accounts/{id}/deposit` adds **SIMULATED** money
  (flagged `simulated=true`).

## 2. Run the mobile app

```bash
flutter pub get
flutter run --flavor dev --dart-define-from-file=config/env/dev.json
```

Or press F5 in VS Code and pick a flavor/mode (e.g. `dev · debug`).

Each flavor reads its API address from `API_BASE_URL` in `config/env/<flavor>.json`
(`dev` → `http://10.0.2.2:8080/api/v1`, i.e. the host machine as seen from the Android emulator).

## 3. Firebase Authentication

Sign-in uses Firebase Auth (project `khmer-flutter-bank`, one Firebase app per flavor):

* **Email + password**: main login. "Forgot password" sends Firebase's reset email.
* **Phone + SMS code**: registration sends a code to the phone number and links it to
  the new account; afterwards the same account can also sign in by phone.

The backend trusts the Firebase **ID token** (`Authorization: Bearer …`), verifying it against
Google's public keys for `FIREBASE_PROJECT_ID` (no service-account key needed). The customer
record and a USD account are created on the first API call; the transaction PIN and the
device list live on the backend. See [REST API → Auth](API.md#auth).

One-time setup in the [Firebase console](https://console.firebase.google.com/) →
Authentication → Sign-in method:

1. Enable **Email/Password** and **Phone**.
2. Phone SMS needs the **Blaze** (pay-as-you-go) plan. For testing without SMS, add
   numbers under *Phone numbers for testing* (e.g. `+855 12 345 678` → code `123456`).
3. **Android**: add the SHA-1 and SHA-256 of your signing key to each Android app
   (Project settings → Your apps). Debug key:
   `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android`
4. **iOS**: upload an APNs auth key (Project settings → Cloud Messaging) for silent
   verification; without it Firebase falls back to reCAPTCHA, which uses the
   `FIREBASE_ENCODED_APP_ID` URL scheme already configured per flavor.

## 4. Tests

```bash
cd backend && mvn verify      # unit tests + PostgreSQL integration tests (needs Docker)
flutter analyze && flutter test
```

The integration tests (`BankingFlowIntegrationTest`) replace Firebase with a test token decoder
and cover: user provisioning from token claims, device revocation, insufficient balance,
idempotency, invalid PIN + lockout, concurrent transfers, cross-currency, ledger immutability
and reconciliation. They are skipped automatically when Docker is unavailable.

## 5. Environment variables (backend)

| Variable | Required | Notes |
|---|---|---|
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | yes | PostgreSQL |
| `FIREBASE_PROJECT_ID` | yes | Firebase project whose ID tokens are accepted (default `khmer-flutter-bank`) |
| `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` | prod | rate limiting |
| `SPRING_PROFILES_ACTIVE` | yes | `dev` locally, `prod` in production |
| `APP_ENV` | yes | `prod` makes the app refuse to start with the dev profile |
| `RATE_LIMIT_STORE` | no | `redis` (default) or `memory` |

**Never commit secrets.** `.env` is git-ignored.
