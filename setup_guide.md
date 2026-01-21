# Database Setup Guide

## Quick Start Guide for Banking Delinquency Analysis

This guide will help you set up the database and run the analysis queries.

---

## Prerequisites

- **PostgreSQL 12+** or **MySQL 8+** installed
- **pgAdmin** (for PostgreSQL) or **MySQL Workbench** (for MySQL)
- Basic SQL knowledge
- Terminal/Command Line access

---

## Step 1: Install PostgreSQL (if not already installed)

### Windows
```bash
# Download from: https://www.postgresql.org/download/windows/
# Follow the installer wizard
```

### macOS
```bash
brew install postgresql
brew services start postgresql
```

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

---

## Step 2: Create Database

### PostgreSQL
```bash
# Switch to postgres user
sudo -i -u postgres

# Create database
createdb banking_analytics

# Or using psql
psql
CREATE DATABASE banking_analytics;
\q
```

### MySQL
```bash
# Login to MySQL
mysql -u root -p

# Create database
CREATE DATABASE banking_analytics;
EXIT;
```

---

## Step 3: Load Data

### Option 1: Using Command Line

#### PostgreSQL
```bash
# Navigate to the data directory
cd banking-delinquency-analysis/data

# Load the SQL file
psql -d banking_analytics -f banking_data.sql

# Verify data loaded
psql -d banking_analytics -c "SELECT COUNT(*) FROM delinquency_prediction;"
```

#### MySQL
```bash
mysql -u root -p banking_analytics < data/banking_data.sql

# Verify
mysql -u root -p banking_analytics -e "SELECT COUNT(*) FROM delinquency_prediction;"
```

### Option 2: Using GUI Tool

#### pgAdmin (PostgreSQL)
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on Databases → Create → Database
4. Name it `banking_analytics`
5. Right-click on `banking_analytics` → Query Tool
6. File → Open → Select `banking_data.sql`
7. Click Execute (F5)

#### MySQL Workbench (MySQL)
1. Open MySQL Workbench
2. Connect to your MySQL server
3. File → Run SQL Script
4. Select `banking_data.sql`
5. Choose `banking_analytics` as the default schema
6. Click Run

---

## Step 4: Verify Installation

Run this query to verify data loaded correctly:

```sql
-- Check total records
SELECT COUNT(*) AS total_records FROM delinquency_prediction;
-- Expected: 1000 records

-- Check data structure
SELECT * FROM delinquency_prediction LIMIT 5;

-- Check for missing values
SELECT 
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS customer_id_count,
    COUNT(age) AS age_count,
    COUNT(income) AS income_count,
    COUNT(credit_score) AS credit_score_count,
    COUNT(loan_balance) AS loan_balance_count
FROM delinquency_prediction;
```

---

## Step 5: Run Analysis Queries

### Create Risk Scores View

```sql
-- Run this first to create the risk_scores view
-- This view is used by all analysis queries

CREATE OR REPLACE VIEW risk_scores AS
SELECT 
    customer_id,
    age,
    income,
    credit_score,
    credit_utilization,
    missed_payments,
    debt_to_income_ratio,
    employment_status,
    delinquent_account,
    location,
    credit_card_type,
    account_tenure,
    loan_balance,
    month_1,
    month_2,
    month_3,
    month_4,
    month_5,
    month_6,
    
    -- Calculate delinquency probability
    ROUND(
        (
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            credit_utilization * 0.25 +
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            debt_to_income_ratio * 0.20
        ),
        3
    ) AS delinquency_probability,
    
    -- Risk tier classification
    CASE 
        WHEN (
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            credit_utilization * 0.25 +
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            debt_to_income_ratio * 0.20
        ) >= 0.70 THEN 'HIGH'
        WHEN (
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            credit_utilization * 0.25 +
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            debt_to_income_ratio * 0.20
        ) >= 0.30 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_tier,
    
    -- Collection action
    CASE 
        WHEN (
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            credit_utilization * 0.25 +
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            debt_to_income_ratio * 0.20
        ) >= 0.70 THEN 'IMMEDIATE_ACTION'
        WHEN (
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            credit_utilization * 0.25 +
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            debt_to_income_ratio * 0.20
        ) >= 0.50 THEN 'PROACTIVE_MONITORING'
        WHEN (
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            credit_utilization * 0.25 +
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            debt_to_income_ratio * 0.20
        ) >= 0.30 THEN 'STANDARD_MONITORING'
        ELSE 'LOW_PRIORITY'
    END AS collection_action
FROM delinquency_prediction;
```

### Run Analysis Queries

Now you can run the analysis queries:

```bash
# PostgreSQL
psql -d banking_analytics -f sql/risk_analysis.sql
psql -d banking_analytics -f sql/customer_segmentation.sql
psql -d banking_analytics -f sql/fairness_audit.sql

# MySQL
mysql -u root -p banking_analytics < sql/risk_analysis.sql
mysql -u root -p banking_analytics < sql/customer_segmentation.sql
mysql -u root -p banking_analytics < sql/fairness_audit.sql
```

---

## Step 6: Python Setup (Optional)

### Install Python Dependencies

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

### Update Database Connection

Edit `python/eda_analysis.py` and update the connection string:

```python
# PostgreSQL
connection_string = 'postgresql://username:password@localhost:5432/banking_analytics'

# MySQL
connection_string = 'mysql+pymysql://username:password@localhost:3306/banking_analytics'
```

### Run Python Analysis

```bash
python python/eda_analysis.py
```

---

## Common Issues & Troubleshooting

### Issue 1: Permission Denied
```bash
# PostgreSQL - Grant permissions
GRANT ALL PRIVILEGES ON DATABASE banking_analytics TO your_username;

# MySQL - Grant permissions
GRANT ALL PRIVILEGES ON banking_analytics.* TO 'your_username'@'localhost';
FLUSH PRIVILEGES;
```

### Issue 2: Connection Refused
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start PostgreSQL
sudo systemctl start postgresql

# MySQL
sudo systemctl status mysql
sudo systemctl start mysql
```

### Issue 3: View Already Exists
```sql
-- Drop and recreate
DROP VIEW IF EXISTS risk_scores;
-- Then run the CREATE VIEW statement again
```

### Issue 4: Python Module Not Found
```bash
# Make sure virtual environment is activated
# Reinstall requirements
pip install --upgrade -r requirements.txt
```

---

## Sample Queries to Get Started

### 1. Basic Risk Overview
```sql
SELECT 
    risk_tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score
FROM risk_scores
GROUP BY risk_tier;
```

### 2. Top 10 High-Risk Customers
```sql
SELECT 
    customer_id,
    income,
    credit_score,
    missed_payments,
    delinquency_probability
FROM risk_scores
WHERE risk_tier = 'HIGH'
ORDER BY delinquency_probability DESC
LIMIT 10;
```

### 3. Income vs Risk Analysis
```sql
SELECT 
    CASE 
        WHEN income < 50000 THEN 'Low Income'
        WHEN income < 100000 THEN 'Medium Income'
        ELSE 'High Income'
    END AS income_bracket,
    COUNT(*) AS customers,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk
FROM risk_scores
GROUP BY 
    CASE 
        WHEN income < 50000 THEN 'Low Income'
        WHEN income < 100000 THEN 'Medium Income'
        ELSE 'High Income'
    END
ORDER BY avg_risk DESC;
```

---

## Next Steps

1. ✅ Database and data loaded
2. ✅ Risk scores view created
3. 📊 Explore analysis queries in `sql/` directory
4. 🐍 Run Python analysis for visualizations
5. 📈 Customize queries for your specific needs
6. 📋 Review insights in the README.md

---

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)

---

**Need Help?**  
Open an issue on GitHub or contact the maintainer.

---

**Last Updated**: January 2026
