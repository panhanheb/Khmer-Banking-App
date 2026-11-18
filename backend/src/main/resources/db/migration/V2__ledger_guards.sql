-- =====================================================================
-- Ledger integrity guards enforced by the database itself
-- =====================================================================

-- 1. Append-only tables: ledger entries and audit logs can never be changed or removed.
CREATE OR REPLACE FUNCTION forbid_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only; % is not allowed', TG_TABLE_NAME, TG_OP
        USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transaction_entries_immutable
    BEFORE UPDATE OR DELETE ON transaction_entries
    FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

CREATE TRIGGER trg_transaction_entries_no_truncate
    BEFORE TRUNCATE ON transaction_entries
    FOR EACH STATEMENT EXECUTE FUNCTION forbid_mutation();

CREATE TRIGGER trg_audit_logs_immutable
    BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION forbid_mutation();

-- 2. Double-entry: at COMMIT time every transaction's entries must balance per currency.
CREATE OR REPLACE FUNCTION check_transaction_balanced() RETURNS trigger AS $$
DECLARE
    unbalanced INT;
BEGIN
    SELECT count(*) INTO unbalanced
    FROM (SELECT currency,
                 sum(CASE WHEN direction = 'DEBIT' THEN amount ELSE -amount END) AS net
          FROM transaction_entries
          WHERE transaction_id = NEW.transaction_id
          GROUP BY currency) t
    WHERE t.net <> 0;

    IF unbalanced > 0 THEN
        RAISE EXCEPTION 'Ledger transaction % is not balanced', NEW.transaction_id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_transaction_entries_balanced
    AFTER INSERT ON transaction_entries
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE FUNCTION check_transaction_balanced();

-- 3. Entry currency must match the account currency.
CREATE OR REPLACE FUNCTION check_entry_currency() RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM bank_accounts a WHERE a.id = NEW.account_id AND a.currency = NEW.currency) THEN
        RAISE EXCEPTION 'Entry currency % does not match account %', NEW.currency, NEW.account_id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transaction_entries_currency
    BEFORE INSERT ON transaction_entries
    FOR EACH ROW EXECUTE FUNCTION check_entry_currency();

-- 4. Reconciliation: stored balance vs. sum of immutable entries. Any non-zero
--    difference is an incident. Also: the sum of all balances per currency is always 0.
CREATE VIEW v_ledger_reconciliation AS
SELECT b.account_id,
       a.account_number,
       b.currency,
       b.ledger_balance,
       COALESCE(e.entries_balance, 0)                    AS entries_balance,
       b.ledger_balance - COALESCE(e.entries_balance, 0) AS difference
FROM account_balances b
JOIN bank_accounts a ON a.id = b.account_id
LEFT JOIN (SELECT account_id,
                  sum(CASE WHEN direction = 'CREDIT' THEN amount ELSE -amount END) AS entries_balance
           FROM transaction_entries
           GROUP BY account_id) e ON e.account_id = b.account_id;

CREATE VIEW v_ledger_trial_balance AS
SELECT currency, sum(ledger_balance) AS net_balance
FROM account_balances
GROUP BY currency;
