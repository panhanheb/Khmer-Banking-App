# Khmer Digital Bank — Database Design

PostgreSQL 16. Schema is owned by Flyway migrations in
[`backend/src/main/resources/db/migration`](../backend/src/main/resources/db/migration):

| Migration | Contents |
|---|---|
| `V1__init_schema.sql` | All tables, constraints, indexes, sequences |
| `V2__ledger_guards.sql` | Append-only triggers, double-entry balance trigger, currency trigger, reconciliation views |
| `V3__reference_data.sql` | Roles/permissions, system ledger accounts, USD/KHR rate, limits, fees, billers, telcos |
| `V4__firebase_auth.sql` | Auth moves to Firebase: `users.firebase_uid`, drops password/lockout columns, `refresh_tokens`, `otp_challenges` |

## ER diagram (core banking)

```mermaid
erDiagram
    users ||--|| user_profiles : has
    users ||--o{ user_roles : has
    roles ||--o{ user_roles : grants
    roles ||--o{ role_permissions : has
    permissions ||--o{ role_permissions : in
    users ||--o{ user_devices : registers
    users ||--o{ account_holders : owns
    bank_accounts ||--o{ account_holders : "owned by"
    bank_accounts ||--|| account_balances : "balance cache"
    users ||--o{ beneficiaries : saves
    users ||--o{ transactions : initiates
    transactions ||--|{ transaction_entries : "posted as (>=2, balanced)"
    bank_accounts ||--o{ transaction_entries : "debited/credited"
    transactions ||--o| transfers : details
    transactions ||--o| qr_payments : details
    transactions ||--o| bill_payments : details
    transactions ||--o| mobile_topups : details
    payment_requests ||--o{ qr_payments : "paid by"
    billers ||--o{ bill_payments : for
    mobile_operators ||--o{ mobile_topups : via
    bank_accounts ||--o{ bank_cards : "linked to"
    users ||--o{ kyc_documents : submits
    admin_users ||--o{ kyc_documents : reviews
    users ||--o{ notifications : receives
    admin_users ||--o{ exchange_rates : publishes

    users {
        uuid id PK
        varchar firebase_uid UK "Firebase Auth UID"
        varchar phone UK "nullable"
        varchar pin_hash "BCrypt"
        varchar status
        int failed_pin_attempts
        timestamptz pin_locked_until
        varchar kyc_status
    }
    bank_accounts {
        uuid id PK
        varchar account_number UK "branch+seq+Luhn"
        varchar owner_type "CUSTOMER|SYSTEM"
        varchar system_code UK "FEE_INCOME_USD, FX_POSITION_KHR..."
        varchar currency "USD|KHR"
        varchar status
    }
    account_balances {
        uuid account_id PK
        numeric ledger_balance "NUMERIC(19,4)"
        numeric available_balance
        boolean allow_negative "system accounts only"
    }
    transactions {
        uuid id PK
        varchar reference UK "KDByyMMdd########"
        varchar type
        varchar status
        uuid initiated_by FK
        varchar idempotency_key "UNIQUE(initiated_by, key)"
        varchar request_hash
        numeric amount
        numeric fee
        boolean simulated
    }
    transaction_entries {
        bigint id PK
        uuid transaction_id FK
        uuid account_id FK
        varchar direction "DEBIT|CREDIT"
        numeric amount "> 0"
        numeric balance_after
    }
```

## Accounting model

* **Sign convention:** for every account, `balance = Σ credits − Σ debits`. Customer deposits are
  liabilities of the bank, so a credit increases what the customer sees.
* **System accounts** (`owner_type = SYSTEM`) represent the bank's side: fee income, FX position per
  currency, and — in dev only — *simulated cash*. They may go negative.
* **Invariant:** the sum of all balances in each currency is always `0`
  (`v_ledger_trial_balance`). Any non-zero row means a bug or tampering.
* **Reconciliation:** `v_ledger_reconciliation.difference` must be `0` for every account. Run it
  nightly and alert on any non-zero row.
* **Corrections** are new `REVERSAL` transactions referencing `reversal_of`; entries are never
  updated or deleted (enforced by trigger, including `TRUNCATE`).

## Concurrency & idempotency

1. `pg_advisory_xact_lock(initiator)` serializes money movements started by the same user, so the
   idempotency lookup and daily-limit sum cannot race.
2. Each affected `account_balances` row is locked `FOR UPDATE` in ascending account-id order (no
   deadlocks between transfers in opposite directions), with a 5 s lock timeout.
3. The deferred constraint trigger re-checks that each transaction balances per currency at commit.
4. `UNIQUE (initiated_by, idempotency_key)` is the last line of defence against duplicates.

## Operational queries

```sql
-- accounts out of balance (must return 0 rows)
SELECT * FROM v_ledger_reconciliation WHERE difference <> 0;

-- trial balance (net must be 0 per currency)
SELECT * FROM v_ledger_trial_balance;

-- all simulated money (must be 0 rows in production)
SELECT count(*) FROM transactions WHERE simulated;
```
