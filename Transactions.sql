CREATE DATABASE bank_risk_analysis;
USE bank_risk_analysis;

CREATE SCHEMA risk_data;
USE risk_data;

CREATE TABLE transactions (
    TransactionID NVARCHAR(50) PRIMARY KEY,
    AccountID NVARCHAR(50),
    TransactionAmount DECIMAL(10,2),
    TransactionDate DATETIME,
    TransactionType VARCHAR(50),
    Location VARCHAR(100),
    DeviceID NVARCHAR(50),
    IPAddress VARCHAR(50),
    MerchantID NVARCHAR(50),
    Channel VARCHAR(50),
    CustomerAge INT,
    CustomerOccupation VARCHAR(100),
    TransactionDuration INT,
    LoginAttempts INT,
    Account_Bal DECIMAL(10,2)
);
INSERT INTO transactions
SELECT * FROM bank_transactions;

SELECT TOP 10 * 
FROM transactions;

SELECT COUNT(*) 
FROM transactions;
-- DATA CLEANING
DELETE FROM transactions
WHERE TransactionAmount IS NULL;

--EDA (Exploratory Data Analysis)

SELECT AccountID, COUNT(*) AS total_txn
FROM transactions
GROUP BY AccountID;

-- Total amount per account.

SELECT AccountID, SUM(TransactionAmount) AS total_amount
FROM transactions
GROUP BY AccountID;

--HIGH VALUE

SELECT *
FROM transactions
WHERE TransactionAmount > 1000;

--Login Attempt

SELECT *
FROM transactions
WHERE LoginAttempts > 3;

--Multiple Location

SELECT AccountID, COUNT(DISTINCT Location) AS location_count
FROM transactions
GROUP BY AccountID
HAVING COUNT(DISTINCT Location) > 3;

--Risk Flag (CASE)

SELECT *,
       CASE 
           WHEN TransactionAmount > 1000 THEN 'High Risk'
           WHEN LoginAttempts > 3 THEN 'Medium Risk'
           WHEN TransactionDuration < 5 THEN 'Suspicious'
           ELSE 'Low Risk'
       END AS RiskLevel
FROM transactions;

-- Windows

WITH ranked_txn AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY AccountID ORDER BY TransactionAmount DESC) AS rn
    FROM transactions
)
SELECT *
FROM ranked_txn
WHERE rn = 1;

-- Running

SELECT AccountID,
       TransactionDate,
       SUM(TransactionAmount) OVER (
           PARTITION BY AccountID 
           ORDER BY TransactionDate
       ) AS running_total
FROM transactions;

--date

SELECT CAST(TransactionDate AS DATE) AS txn_date,
       COUNT(*) AS total_txn
FROM transactions
GROUP BY CAST(TransactionDate AS DATE);

--Fraud pattern

SELECT *
FROM transactions
WHERE TransactionAmount > 1000
AND TransactionDuration > 10;

-- Multiple Users with Same IP Address

SELECT IPAddress, COUNT(DISTINCT AccountID) AS users
FROM transactions
GROUP BY IPAddress
HAVING COUNT(DISTINCT AccountID) > 3;

--INDEX
CREATE INDEX idx_account 
ON transactions(AccountID);

CREATE INDEX idx_date 
ON transactions(TransactionDate);

CREATE VIEW risk_data.risk_summary AS
SELECT AccountID,
       COUNT(*) AS total_txn,
       SUM(TransactionAmount) AS total_amount,
       MAX(TransactionAmount) AS max_txn,
       AVG(TransactionAmount) AS avg_txn
FROM transactions
GROUP BY AccountID;
GO

--REPORT

SELECT *
FROM risk_data.risk_summary
ORDER BY total_amount DESC;