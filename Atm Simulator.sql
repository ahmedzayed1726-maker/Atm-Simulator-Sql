PRAGMA foreign_keys = ON;

DROP VIEW    IF EXISTS mini_statement;
DROP TRIGGER IF EXISTS trg_txn_validate;
DROP TRIGGER IF EXISTS trg_txn_apply;
DROP TABLE   IF EXISTS transactions;
DROP TABLE   IF EXISTS accounts;

-- ---------- TABLES ----------
CREATE TABLE accounts (
    account_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    holder_name  TEXT    NOT NULL,
    pin          TEXT    NOT NULL CHECK (length(pin) = 4),
    balance      REAL    NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status       TEXT    NOT NULL DEFAULT 'ACTIVE'
                         CHECK (status IN ('ACTIVE', 'BLOCKED', 'CLOSED'))
);

CREATE TABLE transactions (
    txn_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id    INTEGER NOT NULL REFERENCES accounts(account_id),
    txn_type      TEXT    NOT NULL CHECK (txn_type IN ('OPEN', 'DEPOSIT', 'WITHDRAW')),
    amount        REAL    NOT NULL CHECK (amount >= 0),
    balance_after REAL,
    description   TEXT,
    txn_time      TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------- RULES (same checks as the Java code) ----------
CREATE TRIGGER trg_txn_validate
BEFORE INSERT ON transactions
BEGIN
    SELECT RAISE(ABORT, 'Invalid amount. Must be greater than zero.')
    WHERE NEW.txn_type IN ('DEPOSIT', 'WITHDRAW') AND NEW.amount <= 0;

    SELECT RAISE(ABORT, 'Account is not active.')
    WHERE NEW.txn_type IN ('DEPOSIT', 'WITHDRAW')
      AND (SELECT status FROM accounts WHERE account_id = NEW.account_id) <> 'ACTIVE';

    SELECT RAISE(ABORT, 'Transaction Declined: Insufficient balance!')
    WHERE NEW.txn_type = 'WITHDRAW'
      AND NEW.amount > (SELECT balance FROM accounts WHERE account_id = NEW.account_id);
END;

CREATE TRIGGER trg_txn_apply
AFTER INSERT ON transactions
BEGIN
    UPDATE accounts
       SET balance = ROUND(balance + CASE WHEN NEW.txn_type = 'WITHDRAW'
                                          THEN -NEW.amount ELSE NEW.amount END, 2)
     WHERE account_id = NEW.account_id;

    UPDATE transactions
       SET balance_after = (SELECT balance FROM accounts WHERE account_id = NEW.account_id)
     WHERE txn_id = NEW.txn_id;
END;

-- ---------- MINI STATEMENT (menu option 4) ----------
CREATE VIEW mini_statement AS
SELECT t.account_id, a.holder_name, t.txn_id, t.txn_time, t.txn_type,
       t.amount, t.balance_after, t.description
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id;

-- ---------- SAMPLE USERS ----------
INSERT INTO accounts (holder_name, pin, status) VALUES
 ('Rahul Sharma',      '1234', 'ACTIVE'),   -- 1 normal user (matches Java: starts with 1000)
 ('Zero Balance User', '0000', 'ACTIVE'),   -- 2 exceptional: opens with 0
 ('Rich User',         '9999', 'ACTIVE'),   -- 3 exceptional: very large balance
 ('Blocked User',      '1111', 'ACTIVE'),   -- 4 exceptional: gets blocked later
 ('No History User',   '2222', 'ACTIVE'),   -- 5 exceptional: never transacts
 ('Decimal User',      '3333', 'ACTIVE');   -- 6 exceptional: paise amounts

INSERT INTO transactions (account_id, txn_type, amount, description) VALUES
 (1, 'OPEN', 1000.00,       'Account opened with initial deposit: ₹1000.00'),
 (2, 'OPEN', 0,             'Account opened with zero balance'),
 (3, 'OPEN', 99999999.99,   'Account opened with very large deposit'),
 (4, 'OPEN', 500.00,        'Account opened with initial deposit: ₹500.00'),
 (5, 'OPEN', 100.00,        'Account opened with initial deposit: ₹100.00'),
 (6, 'OPEN', 250.75,        'Account opened with initial deposit: ₹250.75');

-- ---------- SIMULATE ATM ACTIONS ----------
INSERT INTO transactions (account_id, txn_type, amount, description) VALUES
 (1, 'DEPOSIT',  500.00, 'Deposited: ₹500.0'),
 (1, 'WITHDRAW', 200.00, 'Withdrew: ₹200.0'),
 (1, 'WITHDRAW', 1300.00,'Withdrew: ₹1300.0'),        -- exact full balance -> leaves 0
 (2, 'DEPOSIT',  50.50,  'Deposited: ₹50.5'),
 (3, 'WITHDRAW', 0.01,   'Withdrew: ₹0.01'),
 (4, 'WITHDRAW', 100.00, 'Withdrew: ₹100.0'),
 (6, 'DEPOSIT',  0.25,   'Deposited: ₹0.25');

UPDATE accounts SET status = 'BLOCKED' WHERE account_id = 4;

-- ---------- MENU OPTIONS AS QUERIES ----------
-- 1. Check Balance
SELECT holder_name, printf('₹%.2f', balance) AS current_balance
FROM accounts WHERE account_id = 1;

-- 4. View Statement for one user
SELECT txn_time, txn_type, amount, description, printf('₹%.2f', balance_after) AS balance_after
FROM mini_statement WHERE account_id = 1 ORDER BY txn_id;

-- All users overview
SELECT account_id, holder_name, status, printf('%.2f', balance) AS balance
FROM accounts ORDER BY account_id;
