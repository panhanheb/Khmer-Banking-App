# Khmer Digital Bank — REST API (v1)

Base URL: `/api/v1` · Live OpenAPI/Swagger UI: `http://localhost:8080/swagger-ui.html`

## Conventions

- JSON, UTF-8. **All money amounts are decimal strings** (`"125.50"`, `"41000"`), never numbers.
- Currencies: `USD` (2 decimals), `KHR` (0 decimals).
- Auth: `Authorization: Bearer <accessToken>` on every endpoint except `/auth/register`,
  `/auth/otp/verify`, `/auth/login`, `/auth/login/mfa`, `/auth/refresh`, `/auth/password/*`,
  `/exchange-rates`.
- Money-moving POSTs require header `Idempotency-Key: <uuid>`. Re-sending the same key with
  the same body returns the original result (HTTP 200); same key with a different body → 409.
- Timestamps: ISO-8601 UTC (`2026-11-18T08:30:00Z`).
- Pagination: `?page=0&size=20` → `{ "content": [...], "page": 0, "size": 20, "totalElements": 57, "totalPages": 3 }`

### Errors (RFC 7807)

```json
{ "type": "about:blank", "title": "Insufficient balance", "status": 422,
  "detail": "Available balance is lower than the debit amount",
  "code": "INSUFFICIENT_BALANCE", "traceId": "6f1c…" ,
  "errors": { "amount": "must be greater than 0" } }
```

| code | status |
|---|---|
| `VALIDATION_ERROR` | 400 |
| `INVALID_CREDENTIALS` | 401 |
| `TOKEN_EXPIRED`, `TOKEN_INVALID` | 401 |
| `ACCOUNT_LOCKED`, `PIN_LOCKED` | 423 |
| `INVALID_OTP`, `OTP_EXPIRED`, `INVALID_PIN`, `PIN_NOT_SET` | 400 |
| `FORBIDDEN` | 403 |
| `NOT_FOUND`, `RECIPIENT_NOT_FOUND` | 404 |
| `DUPLICATE`, `IDEMPOTENCY_CONFLICT`, `PHONE_ALREADY_REGISTERED` | 409 |
| `INSUFFICIENT_BALANCE`, `LIMIT_EXCEEDED`, `ACCOUNT_NOT_ACTIVE`, `SAME_ACCOUNT` | 422 |
| `RATE_LIMITED` | 429 |

---

## Auth

### POST /auth/register
```json
{ "phone": "+85512345678", "email": "dara@example.com", "password": "Str0ng!Pass",
  "fullNameEn": "Sok Dara", "fullNameKm": "សុខ ដារ៉ា", "language": "km" }
```
Password policy: ≥8 chars, upper, lower, digit, symbol. Phone: Cambodian E.164 `+855…`.
→ `201 { "userId": "uuid", "challengeId": "uuid", "otpExpiresAt": "…" }` (SMS OTP sent; dev profile logs it and returns `"devOtp"`).

### POST /auth/otp/verify
`{ "challengeId": "uuid", "code": "123456" }` → `200 { "verified": true }` (activates phone)

### POST /auth/login
```json
{ "phone": "+85512345678", "password": "…", "deviceId": "stable-device-uuid",
  "deviceName": "Pixel 9", "platform": "ANDROID" }
```
→ trusted device: `200 { "mfaRequired": false, "tokens": TokenPair }`
→ new device:     `200 { "mfaRequired": true, "challengeId": "uuid", "devOtp": "123456"? }`

### POST /auth/login/mfa
`{ "challengeId": "uuid", "code": "123456", "deviceId": "…", "deviceName": "…", "platform": "ANDROID" }` → `200 TokenPair` (device becomes trusted)

`TokenPair` = `{ "accessToken": "jwt", "refreshToken": "opaque", "tokenType": "Bearer", "expiresIn": 900 }`

### POST /auth/refresh
`{ "refreshToken": "…" }` → `200 TokenPair` (old refresh token is revoked; reuse revokes the family)

### POST /auth/logout
`{ "refreshToken": "…" }` → `204`

### POST /auth/password/forgot
`{ "phone": "+855…" }` → `200 { "challengeId": "uuid" }` (always 200 to avoid user enumeration)

### POST /auth/password/reset
`{ "challengeId": "uuid", "code": "123456", "newPassword": "…" }` → `204` (revokes all sessions)

### PUT /auth/password  🔒
`{ "currentPassword": "…", "newPassword": "…" }` → `204`

### PUT /auth/pin  🔒
Set or change the 6-digit transaction PIN. `{ "currentPin": "123456" | null, "newPin": "654321" }` → `204`

### GET /auth/devices  🔒
→ `[ { "id": "uuid", "deviceName": "Pixel 9", "platform": "ANDROID", "trusted": true, "lastSeenAt": "…", "current": true } ]`

### DELETE /auth/devices/{id}  🔒 → `204`

---

## User

### GET /users/me  🔒
```json
{ "id": "uuid", "phone": "+85512345678", "email": "…", "fullNameEn": "Sok Dara",
  "fullNameKm": "សុខ ដារ៉ា", "language": "km", "kycStatus": "PENDING",
  "pinSet": true, "createdAt": "…" }
```

---

## Accounts

`Account` =
```json
{ "id": "uuid", "accountNumber": "001234567890", "type": "CURRENT", "currency": "USD",
  "status": "ACTIVE", "nickname": "Main USD", "balance": "1250.00",
  "availableBalance": "1250.00", "openedAt": "…" }
```
`type`: `CURRENT` | `SAVINGS`; `status`: `ACTIVE` | `FROZEN` | `CLOSED`

- `GET /accounts` 🔒 → `[Account]`
- `POST /accounts` 🔒 `{ "type": "SAVINGS", "currency": "KHR", "nickname": "Savings" }` → `201 Account`
- `GET /accounts/{id}` 🔒 → `Account`
- `GET /accounts/{id}/transactions?page&size&from&to&type&status` 🔒 → `Page<Transaction>`

---

## Transactions

`Transaction` (from the perspective of the requesting user's account):
```json
{ "id": "uuid", "reference": "KDB2611180000123", "type": "TRANSFER",
  "status": "COMPLETED", "direction": "DEBIT", "amount": "10.00", "fee": "0.00",
  "currency": "USD", "description": "Lunch", "counterpartyName": "C*** Sopheap",
  "counterpartyAccount": "****7890", "accountId": "uuid", "simulated": false,
  "createdAt": "…" }
```
`type`: `TRANSFER` | `DEPOSIT` | `WITHDRAWAL` | `FEE` | `REVERSAL` | `QR_PAYMENT` | `BILL_PAYMENT` | `TOPUP`
`status`: `PENDING` | `COMPLETED` | `FAILED` | `REVERSED`

- `GET /transactions?page&size&from&to&type&status&currency&q` 🔒 → `Page<Transaction>` (all own accounts)
- `GET /transactions/{id}` 🔒 → `Transaction`

---

## Transfers

### POST /transfers/lookup 🔒
`{ "accountNumber": "001234567890" }` **or** `{ "phone": "+85512345678" }`
→ `{ "accountNumber": "001234567890", "accountName": "C*** Sopheap", "currency": "USD", "bankName": "Khmer Digital Bank" }`
(Phone lookup resolves the recipient's primary account in the requested currency if `currency` is passed, else their first active account.)

### POST /transfers/quote 🔒
`{ "sourceAccountId": "uuid", "destinationAccountNumber": "…", "amount": "10.00", "currency": "USD" }`
`currency` is the currency of `amount` (must equal source or destination currency).
```json
{ "debitAmount": "10.00", "debitCurrency": "USD", "creditAmount": "41000",
  "creditCurrency": "KHR", "fee": "0.00", "feeCurrency": "USD", "exchangeRate": "4100.0000",
  "totalDebit": "10.00", "destinationName": "C*** Sopheap",
  "dailyLimitRemaining": "4990.00" }
```

### POST /transfers 🔒 (requires `Idempotency-Key`)
`{ "sourceAccountId": "uuid", "destinationAccountNumber": "…", "amount": "10.00", "currency": "USD", "description": "Lunch", "pin": "123456" }`
→ `201 TransferReceipt` (or `200` on idempotent replay)
```json
{ "transactionId": "uuid", "reference": "KDB2611180000123", "status": "COMPLETED",
  "debitAmount": "10.00", "debitCurrency": "USD", "creditAmount": "41000",
  "creditCurrency": "KHR", "fee": "0.00", "exchangeRate": "4100.0000",
  "sourceAccountNumber": "****1234", "destinationAccountNumber": "****7890",
  "destinationName": "C*** Sopheap", "description": "Lunch", "createdAt": "…" }
```

Default limits (configurable in `transaction_limits`): per transaction USD 5,000 / KHR 20,000,000;
daily USD 10,000 / KHR 40,000,000. Fee: internal transfers free (configurable).

---

## Beneficiaries (saved recipients)

- `GET /beneficiaries` 🔒 → `[ { "id", "nickname", "accountNumber", "accountName", "currency", "bankName" } ]`
- `POST /beneficiaries` 🔒 `{ "accountNumber": "…", "nickname": "Mom" }` → `201` (name resolved server-side, masked)
- `DELETE /beneficiaries/{id}` 🔒 → `204`

---

## Exchange rates

- `GET /exchange-rates` → `[ { "baseCurrency": "USD", "quoteCurrency": "KHR", "buyRate": "4080.0000", "sellRate": "4120.0000", "midRate": "4100.0000", "effectiveAt": "…" } ]`
  Customer USD→KHR uses `buyRate` (bank buys USD); KHR→USD uses `sellRate`.

---

## Dev-only (profile `dev`, **SIMULATED money**)

- `POST /dev/accounts/{id}/deposit` 🔒 `{ "amount": "500.00" }` + `Idempotency-Key` → `201 Transaction` with `simulated: true`.
  Posts against the "Simulated cash" system account. Disabled outside `dev`.
