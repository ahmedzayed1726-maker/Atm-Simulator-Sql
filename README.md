# Apex Bank ATM Simulator Backend (SQLite Engine)

A secure, transaction-safe database backend layer for an **Automated Teller Machine (ATM) Simulator**. This solution shifts core banking business validation, automatic ledger calculation, and multi-user constraints directly away from fragile application code, enforcing them natively within an atomic database state using **SQLite Triggers, Views, and Generative Check Constraints**.

---

## 🚀 Architectural Blueprint

*   **Native Core Enforcement:** Automates state limits—like blocking negative balances or checking security PIN strings—inside database hooks before any write operation executes.
*   **Automatic Financial Ledger Audits:** Automatically calculates and injects post-transaction account snapshots (`balance_after`) into transaction histories after validating deposits or withdrawals.
*   **Decoupled View Architecture:** Synthesizes isolated cross-table joins into a lightweight view layer, allowing your program UI to pull complete mini-statements through simplified single queries.
*   **ACID Compliance & Rounding Safety:** Employs math wrappers (`ROUND(..., 2)`) to completely prevent floating-point penny discrepancies during calculations.

---

## 📊 Relational Database Schema

```text
                  ┌────────────────────────┐
                  │        ACCOUNTS        │
                  ├────────────────────────┤
                  │ PK  account_id (AI)    │◄──────┐
                  │     holder_name        │       │
                  │     pin (CHECK 4-dig)  │       │
                  │     balance (>= 0)     │       │
                  │     status             │       │
                  └────────────────────────┘       │ 1:N
                                                   │ Relationship
                  ┌────────────────────────┐       │
                  │      TRANSACTIONS      │       │
                  ├────────────────────────┤       │
                  │ PK  txn_id (AI)        │       │
                  │ FK  account_id         │───────┘
                  │     txn_type           │
                  │     amount (>= 0)      │
                  │     balance_after      │
                  │     description        │
                  │     txn_time           │
                  └────────────────────────┘
```

### 1. `accounts` Table
Tracks customer metadata, security keys, and available liquidity boundaries.
*   `pin`: Enforced via structural rules to restrict input to exactly **4 characters**.
*   `balance`: Guaranteed field logic configured to never slip into negative values (`CHECK (balance >= 0)`).
*   `status`: System operation flag isolated strictly to: `ACTIVE`, `BLOCKED`, or `CLOSED`.

### 2. `transactions` Table
An immutable historical ledger mapping tracking account mutations.
*   `txn_type`: Restricts input logs to core workflow actions: `OPEN`, `DEPOSIT`, or `WITHDRAW`.
*   `amount`: Blocks invalid or zero-value transactional amounts.
*   `balance_after`: Evaluated dynamically by database application hooks to take a precise account balance snapshot.

---

## ⚡ Automated Business Logic Controls

### 🔒 Validation Trigger: `trg_txn_validate`
Fires automatically **BEFORE INSERT** on any row inside `transactions`. It executes three critical security checks, using `RAISE(ABORT, ...)` to reject faulty commands before they execute:
1.  **Value Check:** Blocks transactions where the operation amount is less than or equal to zero.
2.  **Status Check:** Rejects requests if the target profile state matches `BLOCKED` or `CLOSED`.
3.  **Overdraft Protection:** Aborts withdrawal requests instantly if the amount exceeds the user's current liquid balance.

### 🧮 Application Trigger: `trg_txn_apply`
Fires automatically **AFTER INSERT** to update the relational tables:
*   Dynamically processes balance additions or subtractions using conditional mapping (`CASE WHEN`).
*   Mutates the core master customer balance record, wrapping the output in a rounding handler to prevent fractional issues.
*   Updates the `balance_after` column within the transaction row to ensure an accurate historical audit history.

### 📋 Statement View: `mini_statement`
A decoupled relational analytics layer that combines transaction ledger items with the account holder names. It eliminates the need for complex multi-table joins in the application codebase.

---

## 🎯 Test Scenarios & Edge Cases

The initialization script populates diverse developer test cases to verify core backend boundaries:
1.  **Rahul Sharma (ID 1):** Standard active profile checking baseline operations.
2.  **Zero Balance User (ID 2):** Tests database behavior with an initial opening state of ₹0.
3.  **Rich User (ID 3):** Evaluates high float-value stability (initialized at **₹99,999,999.99**).
4.  **Blocked User (ID 4):** Simulates transitioning status to `BLOCKED` to prove that the validation triggers block subsequent ATM interactions.
5.  **Decimal User (ID 6):** Enforces micro-penny decimal stability testing fractional entries (e.g., Indian Paise tracking).

---

## 💻 ATM Interface Mappings (SQL Examples)

Here is how the application frontend maps menu items directly onto the SQLite script:

### Option 1: Check Balance
```sql
SELECT holder_name, printf('An available balance of: ₹%.2f', balance) AS current_balance
FROM accounts WHERE account_id = 1;
```

### Option 2: Deposit Money
```sql
INSERT INTO transactions (account_id, txn_type, amount, description) 
VALUES (1, 'DEPOSIT', 500.00, 'Deposited: ₹500.00');
```

### Option 3: Withdraw Money (Triggers automatic Overdraft Validation)
```sql
INSERT INTO transactions (account_id, txn_type, amount, description) 
VALUES (1, 'WITHDRAW', 200.00, 'Withdrew: ₹200.00');
```

### Option 4: View Mini Statement
```sql
SELECT txn_time, txn_type, amount, description, printf('₹%.2f', balance_after) AS balance_after
FROM mini_statement WHERE account_id = 1 ORDER BY txn_id ASC;
```

---

## 🛠️ Getting Started & Execution

### Prerequisites
Ensure you have the [SQLite3 CLI](https://sqlite.org) tool or a visual GUI browser engine like [DB Browser for SQLite](https://sqlitebrowser.org) installed.

### Standard Installation
1. Clone this repository to your machine.
2. Navigate to the SQL directory and execute the setup initialization file:
   ```bash
   sqlite3 apex_bank.db < schema.sql
   ```
3. Open the database interactively to inspect the generated tables, triggers, and mock states:
   ```bash
   sqlite3 apex_bank.db
   ```

---

