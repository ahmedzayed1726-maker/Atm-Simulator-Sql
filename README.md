# Atm-Simulator-Sql
# Apex Bank ATM Simulator (Database Driven)

A secure, database-driven **Automated Teller Machine (ATM) Simulator** application. This project demonstrates how to connect real-world banking logic with relational databases, handling multi-user authentication, ACID-compliant transactions, and historical data logging using strict operational boundaries.

---

## 🚀 Features

*   **Multi-User PIN Verification:** Authenticates unique account credentials directly against database records before granting system access.
*   **Balance Inquiries:** Performs accurate, real-time balance checks directly from persistent state storage.
*   **Persistent Cash Deposits:** Safely credits monetary inputs and commits mutations directly to the host database.
*   **Overdraft Protected Withdrawals:** Implements logic bounds checking directly at the database transaction layer to block withdrawals that exceed the current balance.
*   **Chronological Auditing:** Automatically logs sequential transaction history with microsecond-level timestamps, tracking transaction states persistently.

---

## 📊 Database Architecture & Schema

The relational database layer consists of two tables linked by a foreign key relationship to ensure absolute data integrity.

### 1. `customers` Table
Tracks vital customer profile states and current credit liquidity.
*   `account_id`: Primary identifier for the unique customer account.
*   `pin`: Standard 4-digit security key required for transactional query access.
*   `customer_name`: Name of the account holder.
*   `balance`: The running account balance (Defaults to `0.00`).

### 2. `transaction_history` Table
Stores an immutable log of all historical user transaction behavior.
*   `transaction_id`: Auto-generated identity sequence key.
*   `account_id`: Reference mapping back to the primary account owner.
*   `transaction_type`: Logs whether the event was a `'Deposit'` or a `'Withdrawal'`.
*   `amount`: The exact numerical quantity shifted during the operation.
*   `transaction_timestamp`: System time generation marking the transaction completion.

---

## ⚙️ Core Operations Implemented

### 🔓 1. PIN Verification & Balance Check
Verifies credentials safely in a single execution step to retrieve user profiles.
```sql
SELECT customer_name, balance 
FROM customers 
WHERE account_id = 1001 AND pin = 1234;
```

### 💰 2. Cash Deposit Sequence
Updates user balances while systematically registering an entry in the audit database.
```sql
-- Step 1: Update the customer's balance
UPDATE customers 
SET balance = balance + 2000.00 
WHERE account_id = 1001 AND pin = 1234;

-- Step 2: Log the deposit in history
INSERT INTO transaction_history (account_id, transaction_type, amount)
VALUES (1001, 'Deposit', 2000.00);
```

### 🛑 3. Cash Withdrawal (Overdraft Protection)
Uses state conditions (`balance >= amount`) directly inside the update query to natively prevent balances from slipping below zero.
```sql
UPDATE customers 
SET balance = balance - 1500.00 
WHERE account_id = 1001 
  AND pin = 1234 
  AND balance >= 1500.00;
```

### 📜 4. Statement Retrieval
Queries historical transaction logs sorted chronologically, limited to the 5 most recent records.
```sql
SELECT transaction_type, amount, transaction_timestamp 
FROM transaction_history 
WHERE account_id = 1001 
ORDER BY transaction_timestamp DESC 
LIMIT 5;
```

---

## 🛠️ Technology Stack

*   **Language Backend:** Java (JDK 8+)
*   **Database Engine:** PostgreSQL / MySQL / Standard SQL RDBMS
*   **Connectivity Layer:** JDBC (Java Database Connectivity)

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for details.
