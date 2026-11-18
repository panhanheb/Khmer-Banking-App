-- =====================================================================
-- Reference / seed data (safe for every environment; no credentials)
-- =====================================================================

INSERT INTO roles (code, description) VALUES
    ('CUSTOMER', 'Retail banking customer'),
    ('SUPER_ADMIN', 'Full administrative access'),
    ('OPERATIONS', 'Back-office operations'),
    ('COMPLIANCE', 'KYC review and fraud monitoring'),
    ('SUPPORT', 'Customer support, read-only financial data');

INSERT INTO permissions (code, description) VALUES
    ('CUSTOMER_READ', 'View customers'),
    ('CUSTOMER_WRITE', 'Lock/unlock and edit customers'),
    ('ACCOUNT_WRITE', 'Freeze/unfreeze accounts'),
    ('KYC_REVIEW', 'Approve or reject KYC'),
    ('TRANSACTION_READ', 'View transactions'),
    ('TRANSACTION_REVERSE', 'Reverse transactions'),
    ('FX_WRITE', 'Publish exchange rates'),
    ('CONFIG_WRITE', 'Edit billers, operators, limits, fees'),
    ('STAFF_WRITE', 'Manage staff and roles'),
    ('AUDIT_READ', 'Read audit logs');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.code = 'SUPER_ADMIN';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
    ON p.code IN ('CUSTOMER_READ', 'CUSTOMER_WRITE', 'ACCOUNT_WRITE', 'TRANSACTION_READ', 'FX_WRITE', 'CONFIG_WRITE')
WHERE r.code = 'OPERATIONS';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
    ON p.code IN ('CUSTOMER_READ', 'KYC_REVIEW', 'TRANSACTION_READ', 'AUDIT_READ')
WHERE r.code = 'COMPLIANCE';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p
    ON p.code IN ('CUSTOMER_READ', 'TRANSACTION_READ')
WHERE r.code = 'SUPPORT';

-- System (internal) ledger accounts. They may go negative: e.g. FX position or
-- simulated cash represent the bank's side of a posting.
INSERT INTO bank_accounts (account_number, owner_type, system_code, account_type, currency, nickname) VALUES
    ('900000000011', 'SYSTEM', 'FEE_INCOME_USD',     'SYSTEM', 'USD', 'Fee income USD'),
    ('900000000029', 'SYSTEM', 'FEE_INCOME_KHR',     'SYSTEM', 'KHR', 'Fee income KHR'),
    ('900000000037', 'SYSTEM', 'FX_POSITION_USD',    'SYSTEM', 'USD', 'FX position USD'),
    ('900000000045', 'SYSTEM', 'FX_POSITION_KHR',    'SYSTEM', 'KHR', 'FX position KHR'),
    ('900000000052', 'SYSTEM', 'SIMULATED_CASH_USD', 'SYSTEM', 'USD', 'SIMULATED cash (dev only)'),
    ('900000000060', 'SYSTEM', 'SIMULATED_CASH_KHR', 'SYSTEM', 'KHR', 'SIMULATED cash (dev only)');

INSERT INTO account_balances (account_id, currency, allow_negative)
SELECT id, currency, TRUE FROM bank_accounts WHERE owner_type = 'SYSTEM';

-- Indicative USD/KHR rate. Operations must publish real rates via the admin module.
INSERT INTO exchange_rates (base_currency, quote_currency, buy_rate, sell_rate, mid_rate)
VALUES ('USD', 'KHR', 4080, 4120, 4100);

INSERT INTO transaction_limits (scope, transaction_type, currency, per_transaction_max, daily_max) VALUES
    ('DEFAULT', 'TRANSFER', 'USD', 5000, 10000),
    ('DEFAULT', 'TRANSFER', 'KHR', 20000000, 40000000);

-- Internal transfers are free by default; adjust here or via admin later.
INSERT INTO fee_rules (transaction_type, transfer_type, currency, flat_fee, percent_fee) VALUES
    ('TRANSFER', 'INTERNAL', 'USD', 0, 0),
    ('TRANSFER', 'INTERNAL', 'KHR', 0, 0),
    ('TRANSFER', 'OWN', 'USD', 0, 0),
    ('TRANSFER', 'OWN', 'KHR', 0, 0);

-- Configurable billers / operators. simulated = TRUE until a real provider agreement exists.
INSERT INTO billers (code, name_en, name_km, category, currency) VALUES
    ('EDC', 'Electricité du Cambodge', 'អគ្គិសនីកម្ពុជា', 'ELECTRICITY', 'KHR'),
    ('PPWSA', 'Phnom Penh Water Supply Authority', 'រដ្ឋាករទឹកស្វយ័តក្រុងភ្នំពេញ', 'WATER', 'KHR'),
    ('DEMO_ISP', 'Demo Internet Provider', 'ក្រុមហ៊ុនអ៊ីនធឺណិតសាកល្បង', 'INTERNET', 'USD');

INSERT INTO mobile_operators (code, name, prefixes) VALUES
    ('SMART', 'Smart', '10,15,16,69,70,81,86,87,93,96,98'),
    ('CELLCARD', 'Cellcard', '11,12,14,17,61,76,77,78,85,89,92,95,99'),
    ('METFONE', 'Metfone', '31,60,66,67,68,71,88,90,97');
