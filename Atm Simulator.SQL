-- Create the Customers table
CREATE TABLE customers (
    account_id INT PRIMARY KEY,
    pin INT NOT NULL,
    customer_name VARCHAR(100),
    balance DECIMAL(10, 2) DEFAULT 0.00
);

-- Create the Transaction History table
CREATE TABLE transaction_history (
    transaction_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id INT REFERENCES customers(account_id),
    transaction_type VARCHAR(20), -- 'Deposit' or 'Withdrawal'
    amount DECIMAL(10, 2),
    transaction_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert dummy data for testing
INSERT INTO customers (account_id, pin, customer_name, balance) VALUES
(1001, 1234, 'Alice Smith', 5000.00),
(1002, 5678, 'Bob Jones', 150.00);

-- Operation 1: PIN Verification & Balance Check
SELECT customer_name, balance 
FROM customers 
WHERE account_id = 1001 AND pin = 1234;

-- Operation 2: Cash Deposit
-- Step 1: Update the customer's balance
UPDATE customers 
SET balance = balance + 2000.00 
WHERE account_id = 1001 AND pin = 1234;

-- Step 2: Log the deposit in history
INSERT INTO transaction_history (account_id, transaction_type, amount)
VALUES (1001, 'Deposit', 2000.00);


-- Operation 3: Cash Withdrawal (With Overdraft Protection)
-- Safely deduct funds only if the current balance is enough
UPDATE customers 
SET balance = balance - 1500.00 
WHERE account_id = 1001 
  AND pin = 1234 
  AND balance >= 1500.00;

-- Log the transaction only if the above update affected 1 row (success)
INSERT INTO transaction_history (account_id, transaction_type, amount)
VALUES (1001, 'Withdrawal', 1500.00);

-- Operation 4: To view the last 5 transactions for a specific account
SELECT transaction_type, amount, transaction_timestamp 
FROM transaction_history 
WHERE account_id = 1001 
ORDER BY transaction_timestamp DESC 
LIMIT 5;
