-- =====================================================================
-- Khmer Digital Bank — core schema
-- Money: NUMERIC(19,4) only. Never floating point.
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------- Access control ----------
CREATE TABLE roles (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(50)  NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE permissions (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE role_permissions (
    role_id       SMALLINT NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    permission_id SMALLINT NOT NULL REFERENCES permissions (id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- ---------- Customers ----------
CREATE TABLE users (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone                 VARCHAR(20)  NOT NULL UNIQUE,
    email                 VARCHAR(255) UNIQUE,
    password_hash         VARCHAR(100) NOT NULL,
    pin_hash              VARCHAR(100),
    status                VARCHAR(30)  NOT NULL DEFAULT 'PENDING_VERIFICATION'
        CHECK (status IN ('PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'CLOSED')),
    phone_verified        BOOLEAN      NOT NULL DEFAULT FALSE,
    email_verified        BOOLEAN      NOT NULL DEFAULT FALSE,
    failed_login_attempts INT          NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    failed_pin_attempts   INT          NOT NULL DEFAULT 0,
    pin_locked_until      TIMESTAMPTZ,
    kyc_status            VARCHAR(20)  NOT NULL DEFAULT 'NOT_STARTED'
        CHECK (kyc_status IN ('NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED')),
    language              VARCHAR(5)   NOT NULL DEFAULT 'km',
    password_changed_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version               BIGINT       NOT NULL DEFAULT 0
);

CREATE TABLE user_profiles (
    user_id       UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    full_name_en  VARCHAR(150) NOT NULL,
    full_name_km  VARCHAR(150),
    date_of_birth DATE,
    gender        VARCHAR(10),
    nationality   VARCHAR(2)   NOT NULL DEFAULT 'KH',
    address_line  VARCHAR(255),
    city          VARCHAR(100),
    province      VARCHAR(100),
    avatar_url    VARCHAR(500),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE user_roles (
    user_id UUID     NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id SMALLINT NOT NULL REFERENCES roles (id),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE user_devices (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    device_id    VARCHAR(128) NOT NULL,
    device_name  VARCHAR(100),
    platform     VARCHAR(20)  NOT NULL CHECK (platform IN ('ANDROID', 'IOS', 'WEB')),
    trusted      BOOLEAN      NOT NULL DEFAULT FALSE,
    push_token   VARCHAR(500),
    last_seen_at TIMESTAMPTZ,
    revoked_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (user_id, device_id)
);

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    device_id   UUID REFERENCES user_devices (id) ON DELETE CASCADE,
    token_hash  VARCHAR(64) NOT NULL UNIQUE,
    family_id   UUID        NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    replaced_by UUID,
    created_ip  VARCHAR(45),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens (family_id);

CREATE TABLE otp_challenges (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    purpose     VARCHAR(30) NOT NULL
        CHECK (purpose IN ('REGISTRATION', 'LOGIN_MFA', 'PASSWORD_RESET', 'TRANSACTION')),
    code_hash   VARCHAR(64) NOT NULL,
    context     VARCHAR(255),
    attempts    INT         NOT NULL DEFAULT 0,
    expires_at  TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_otp_user ON otp_challenges (user_id, created_at DESC);

-- ---------- Staff ----------
CREATE TABLE admin_users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username       VARCHAR(60)  NOT NULL UNIQUE,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(100) NOT NULL,
    full_name      VARCHAR(150) NOT NULL,
    role_id        SMALLINT     NOT NULL REFERENCES roles (id),
    status         VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'DISABLED')),
    mfa_secret_enc VARCHAR(255),
    last_login_at  TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- Accounts ----------
CREATE SEQUENCE account_number_seq START 10000001;
CREATE SEQUENCE txn_reference_seq START 1;

CREATE TABLE bank_accounts (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_number    VARCHAR(20) NOT NULL UNIQUE,
    owner_type        VARCHAR(10) NOT NULL CHECK (owner_type IN ('CUSTOMER', 'SYSTEM')),
    system_code       VARCHAR(40) UNIQUE,
    account_type      VARCHAR(20) NOT NULL CHECK (account_type IN ('CURRENT', 'SAVINGS', 'SYSTEM')),
    currency          VARCHAR(3)  NOT NULL CHECK (currency IN ('USD', 'KHR')),
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    nickname          VARCHAR(60),
    primary_holder_id UUID REFERENCES users (id),
    opened_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at         TIMESTAMPTZ,
    version           BIGINT      NOT NULL DEFAULT 0,
    CHECK ((owner_type = 'SYSTEM') = (system_code IS NOT NULL)),
    CHECK (owner_type = 'SYSTEM' OR primary_holder_id IS NOT NULL)
);
CREATE INDEX idx_bank_accounts_holder ON bank_accounts (primary_holder_id);

CREATE TABLE account_holders (
    account_id  UUID        NOT NULL REFERENCES bank_accounts (id),
    user_id     UUID        NOT NULL REFERENCES users (id),
    holder_role VARCHAR(20) NOT NULL DEFAULT 'PRIMARY' CHECK (holder_role IN ('PRIMARY', 'JOINT')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, user_id)
);
CREATE INDEX idx_account_holders_user ON account_holders (user_id);

-- Current balance cache, always updated in the same DB transaction as the ledger entries.
-- Convention for every account: balance = SUM(credits) - SUM(debits).
CREATE TABLE account_balances (
    account_id        UUID PRIMARY KEY REFERENCES bank_accounts (id),
    currency          VARCHAR(3)     NOT NULL CHECK (currency IN ('USD', 'KHR')),
    ledger_balance    NUMERIC(19, 4) NOT NULL DEFAULT 0,
    available_balance NUMERIC(19, 4) NOT NULL DEFAULT 0,
    hold_amount       NUMERIC(19, 4) NOT NULL DEFAULT 0 CHECK (hold_amount >= 0),
    allow_negative    BOOLEAN        NOT NULL DEFAULT FALSE,
    updated_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
    version           BIGINT         NOT NULL DEFAULT 0,
    CHECK (allow_negative OR ledger_balance >= 0),
    CHECK (allow_negative OR available_balance >= 0)
);

CREATE TABLE beneficiaries (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    nickname       VARCHAR(60),
    account_number VARCHAR(34) NOT NULL,
    bank_code      VARCHAR(20) NOT NULL DEFAULT 'KDB',
    account_name   VARCHAR(150),
    currency       VARCHAR(3)  CHECK (currency IN ('USD', 'KHR')),
    phone          VARCHAR(20),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, bank_code, account_number)
);

-- ---------- Ledger ----------
CREATE TABLE transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference       VARCHAR(20)    NOT NULL UNIQUE,
    type            VARCHAR(20)    NOT NULL
        CHECK (type IN ('TRANSFER', 'DEPOSIT', 'WITHDRAWAL', 'FEE', 'REVERSAL', 'QR_PAYMENT', 'BILL_PAYMENT', 'TOPUP')),
    status          VARCHAR(20)    NOT NULL CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
    initiated_by    UUID REFERENCES users (id),
    idempotency_key VARCHAR(100),
    request_hash    VARCHAR(64),
    description     VARCHAR(255),
    amount          NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
    currency        VARCHAR(3)     NOT NULL CHECK (currency IN ('USD', 'KHR')),
    fee             NUMERIC(19, 4) NOT NULL DEFAULT 0 CHECK (fee >= 0),
    simulated       BOOLEAN        NOT NULL DEFAULT FALSE,
    reversal_of     UUID REFERENCES transactions (id),
    failure_reason  VARCHAR(255),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    UNIQUE (initiated_by, idempotency_key)
);
CREATE INDEX idx_transactions_initiator_day ON transactions (initiated_by, type, currency, created_at);

CREATE TABLE transaction_entries (
    id             BIGSERIAL PRIMARY KEY,
    transaction_id UUID           NOT NULL REFERENCES transactions (id),
    account_id     UUID           NOT NULL REFERENCES bank_accounts (id),
    direction      VARCHAR(6)     NOT NULL CHECK (direction IN ('DEBIT', 'CREDIT')),
    amount         NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
    currency       VARCHAR(3)     NOT NULL CHECK (currency IN ('USD', 'KHR')),
    balance_after  NUMERIC(19, 4) NOT NULL,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_entries_account_time ON transaction_entries (account_id, created_at DESC);
CREATE INDEX idx_entries_transaction ON transaction_entries (transaction_id);

CREATE TABLE transfers (
    id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id             UUID           NOT NULL UNIQUE REFERENCES transactions (id),
    transfer_type              VARCHAR(20)    NOT NULL CHECK (transfer_type IN ('OWN', 'INTERNAL', 'INTERBANK')),
    source_account_id          UUID           NOT NULL REFERENCES bank_accounts (id),
    destination_account_id     UUID REFERENCES bank_accounts (id),
    destination_account_number VARCHAR(34)    NOT NULL,
    destination_bank_code      VARCHAR(20)    NOT NULL DEFAULT 'KDB',
    destination_name           VARCHAR(150),
    debit_amount               NUMERIC(19, 4) NOT NULL,
    debit_currency             VARCHAR(3)     NOT NULL,
    credit_amount              NUMERIC(19, 4) NOT NULL,
    credit_currency            VARCHAR(3)     NOT NULL,
    exchange_rate              NUMERIC(19, 8) NOT NULL DEFAULT 1,
    fee                        NUMERIC(19, 4) NOT NULL DEFAULT 0,
    created_at                 TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ---------- Payments (Phase 7 — gateway interfaces) ----------
CREATE TABLE payment_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_user_id UUID        NOT NULL REFERENCES users (id),
    account_id        UUID        NOT NULL REFERENCES bank_accounts (id),
    amount            NUMERIC(19, 4) CHECK (amount IS NULL OR amount > 0),
    currency          VARCHAR(3)  NOT NULL,
    description       VARCHAR(255),
    qr_type           VARCHAR(10) NOT NULL CHECK (qr_type IN ('STATIC', 'DYNAMIC')),
    qr_payload        TEXT        NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'PAID', 'EXPIRED', 'CANCELLED')),
    expires_at        TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE qr_payments (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id     UUID        NOT NULL UNIQUE REFERENCES transactions (id),
    payment_request_id UUID REFERENCES payment_requests (id),
    qr_type            VARCHAR(10) NOT NULL CHECK (qr_type IN ('STATIC', 'DYNAMIC')),
    merchant_id        VARCHAR(64),
    merchant_name      VARCHAR(150),
    payload            TEXT        NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE billers (
    id       SERIAL PRIMARY KEY,
    code     VARCHAR(30)  NOT NULL UNIQUE,
    name_en  VARCHAR(150) NOT NULL,
    name_km  VARCHAR(150) NOT NULL,
    category VARCHAR(30)  NOT NULL
        CHECK (category IN ('ELECTRICITY', 'WATER', 'INTERNET', 'MOBILE', 'EDUCATION', 'INSURANCE', 'GOVERNMENT')),
    currency VARCHAR(3)   NOT NULL,
    active   BOOLEAN      NOT NULL DEFAULT TRUE,
    simulated BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE bill_payments (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id     UUID           NOT NULL UNIQUE REFERENCES transactions (id),
    biller_id          INT            NOT NULL REFERENCES billers (id),
    customer_reference VARCHAR(64)    NOT NULL,
    bill_amount        NUMERIC(19, 4) NOT NULL,
    currency           VARCHAR(3)     NOT NULL,
    provider_reference VARCHAR(64),
    created_at         TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TABLE mobile_operators (
    id        SERIAL PRIMARY KEY,
    code      VARCHAR(20)  NOT NULL UNIQUE,
    name      VARCHAR(100) NOT NULL,
    prefixes  VARCHAR(255) NOT NULL,
    active    BOOLEAN      NOT NULL DEFAULT TRUE,
    simulated BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE mobile_topups (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id     UUID           NOT NULL UNIQUE REFERENCES transactions (id),
    operator_id        INT            NOT NULL REFERENCES mobile_operators (id),
    phone              VARCHAR(20)    NOT NULL,
    package_code       VARCHAR(40),
    amount             NUMERIC(19, 4) NOT NULL,
    currency           VARCHAR(3)     NOT NULL,
    provider_reference VARCHAR(64),
    created_at         TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ---------- Cards (PAN never stored; only processor token + last4) ----------
CREATE TABLE bank_cards (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID           NOT NULL REFERENCES bank_accounts (id),
    user_id             UUID           NOT NULL REFERENCES users (id),
    card_type           VARCHAR(10)    NOT NULL CHECK (card_type IN ('PHYSICAL', 'VIRTUAL')),
    network             VARCHAR(20)    NOT NULL,
    processor_token     VARCHAR(128)   NOT NULL UNIQUE,
    pan_last4           VARCHAR(4)     NOT NULL,
    expiry_month        SMALLINT       NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year         SMALLINT       NOT NULL,
    status              VARCHAR(20)    NOT NULL DEFAULT 'INACTIVE'
        CHECK (status IN ('INACTIVE', 'ACTIVE', 'FROZEN', 'BLOCKED', 'EXPIRED')),
    daily_limit         NUMERIC(19, 4),
    online_enabled      BOOLEAN        NOT NULL DEFAULT TRUE,
    contactless_enabled BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- ---------- KYC ----------
CREATE TABLE kyc_documents (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    document_type       VARCHAR(20)  NOT NULL CHECK (document_type IN ('NATIONAL_ID', 'PASSPORT', 'SELFIE', 'PROOF_OF_ADDRESS')),
    document_number_enc VARCHAR(255),
    storage_key         VARCHAR(500) NOT NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'SUBMITTED' CHECK (status IN ('SUBMITTED', 'APPROVED', 'REJECTED')),
    reviewed_by         UUID REFERENCES admin_users (id),
    review_note         VARCHAR(500),
    submitted_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    reviewed_at         TIMESTAMPTZ
);

-- ---------- Notifications ----------
CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    category   VARCHAR(20)  NOT NULL
        CHECK (category IN ('TRANSFER', 'PAYMENT', 'LOGIN', 'SECURITY', 'PROMOTION', 'SYSTEM')),
    title_en   VARCHAR(150) NOT NULL,
    title_km   VARCHAR(150) NOT NULL,
    body_en    VARCHAR(500) NOT NULL,
    body_km    VARCHAR(500) NOT NULL,
    data       JSONB,
    read_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications (user_id, created_at DESC);

-- ---------- Reference data ----------
CREATE TABLE exchange_rates (
    id             BIGSERIAL PRIMARY KEY,
    base_currency  VARCHAR(3)     NOT NULL,
    quote_currency VARCHAR(3)     NOT NULL,
    buy_rate       NUMERIC(19, 8) NOT NULL CHECK (buy_rate > 0),
    sell_rate      NUMERIC(19, 8) NOT NULL CHECK (sell_rate > 0),
    mid_rate       NUMERIC(19, 8) NOT NULL CHECK (mid_rate > 0),
    effective_at   TIMESTAMPTZ    NOT NULL DEFAULT now(),
    created_by     UUID REFERENCES admin_users (id),
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CHECK (buy_rate <= mid_rate AND mid_rate <= sell_rate)
);
CREATE INDEX idx_exchange_rates_pair ON exchange_rates (base_currency, quote_currency, effective_at DESC);

CREATE TABLE transaction_limits (
    id                  SERIAL PRIMARY KEY,
    scope               VARCHAR(20)    NOT NULL DEFAULT 'DEFAULT' CHECK (scope IN ('DEFAULT', 'USER')),
    user_id             UUID REFERENCES users (id) ON DELETE CASCADE,
    transaction_type    VARCHAR(20)    NOT NULL,
    currency            VARCHAR(3)     NOT NULL,
    per_transaction_max NUMERIC(19, 4) NOT NULL,
    daily_max           NUMERIC(19, 4) NOT NULL,
    active              BOOLEAN        NOT NULL DEFAULT TRUE,
    CHECK ((scope = 'USER') = (user_id IS NOT NULL))
);
CREATE UNIQUE INDEX uq_limits_default ON transaction_limits (transaction_type, currency) WHERE scope = 'DEFAULT';
CREATE UNIQUE INDEX uq_limits_user ON transaction_limits (user_id, transaction_type, currency) WHERE scope = 'USER';

CREATE TABLE fee_rules (
    id               SERIAL PRIMARY KEY,
    transaction_type VARCHAR(20)    NOT NULL,
    transfer_type    VARCHAR(20)    NOT NULL DEFAULT 'ANY',
    currency         VARCHAR(3)     NOT NULL,
    flat_fee         NUMERIC(19, 4) NOT NULL DEFAULT 0 CHECK (flat_fee >= 0),
    percent_fee      NUMERIC(9, 6)  NOT NULL DEFAULT 0 CHECK (percent_fee >= 0),
    min_fee          NUMERIC(19, 4) NOT NULL DEFAULT 0,
    max_fee          NUMERIC(19, 4),
    active           BOOLEAN        NOT NULL DEFAULT TRUE,
    UNIQUE (transaction_type, transfer_type, currency)
);

-- ---------- Audit (append-only) ----------
CREATE TABLE audit_logs (
    id          BIGSERIAL PRIMARY KEY,
    actor_type  VARCHAR(10)  NOT NULL CHECK (actor_type IN ('USER', 'ADMIN', 'SYSTEM', 'ANONYMOUS')),
    actor_id    UUID,
    action      VARCHAR(60)  NOT NULL,
    outcome     VARCHAR(10)  NOT NULL CHECK (outcome IN ('SUCCESS', 'FAILURE')),
    entity_type VARCHAR(40),
    entity_id   VARCHAR(64),
    ip_address  VARCHAR(45),
    user_agent  VARCHAR(255),
    details     JSONB,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_actor ON audit_logs (actor_id, created_at DESC);
CREATE INDEX idx_audit_action ON audit_logs (action, created_at DESC);
