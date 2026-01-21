# Data Dictionary

## Banking Delinquency Prediction Dataset

This document provides detailed descriptions of all fields in the `delinquency_prediction` table.

---

## Table: delinquency_prediction

### Primary Identifiers

| Field Name | Data Type | Description | Example Values |
|------------|-----------|-------------|----------------|
| `id` | SERIAL | Auto-incrementing primary key | 1, 2, 3, ... |
| `customer_id` | VARCHAR(20) | Unique customer identifier | CUST0001, CUST0002 |

---

### Demographic Information

| Field Name | Data Type | Description | Range/Values |
|------------|-----------|-------------|--------------|
| `age` | INTEGER | Customer's age in years | 18-74 years |
| `employment_status` | VARCHAR(50) | Current employment situation | Employed, Unemployed, Self-employed, Retired |
| `location` | VARCHAR(50) | Customer's city of residence | New York, Los Angeles, Chicago, Houston, Phoenix |

---

### Financial Profile

| Field Name | Data Type | Description | Range/Values | Notes |
|------------|-----------|-------------|--------------|-------|
| `income` | DECIMAL(15,2) | Annual income in USD | $30,000 - $400,000 | Gross annual income |
| `credit_score` | INTEGER | FICO credit score | 300-850 | Standard FICO range |
| `loan_balance` | DECIMAL(15,2) | Outstanding loan amount | $0 - $100,000 | NULL if no loan |

---

### Credit Behavior Metrics

| Field Name | Data Type | Description | Range/Values | Calculation |
|------------|-----------|-------------|--------------|-------------|
| `credit_utilization` | DECIMAL(10,6) | Proportion of credit limit used | 0.0 - 1.0 (0-100%) | Used Credit / Total Credit Limit |
| `missed_payments` | INTEGER | Count of missed payments in last 6 months | 0-6 | Total across all accounts |
| `debt_to_income_ratio` | DECIMAL(10,6) | Monthly debt obligations vs income | 0.0 - 1.0 (0-100%) | Total Monthly Debt / Gross Monthly Income |

---

### Account Details

| Field Name | Data Type | Description | Possible Values |
|------------|-----------|-------------|-----------------|
| `account_tenure` | INTEGER | Months since account opening | 0-19 months |
| `credit_card_type` | VARCHAR(50) | Type of credit card held | Standard, Gold, Platinum, Business, Student |
| `delinquent_account` | INTEGER | Current delinquency status | 0 (Current), 1 (Delinquent) |

---

### Payment History (6-Month Lookback)

All payment history fields record the customer's payment status for each of the last 6 months, with `month_1` being the most recent.

| Field Name | Data Type | Description | Possible Values |
|------------|-----------|-------------|-----------------|
| `month_1` | VARCHAR(20) | Most recent month payment status | On-time, Late, Missed |
| `month_2` | VARCHAR(20) | 2 months ago payment status | On-time, Late, Missed |
| `month_3` | VARCHAR(20) | 3 months ago payment status | On-time, Late, Missed |
| `month_4` | VARCHAR(20) | 4 months ago payment status | On-time, Late, Missed |
| `month_5` | VARCHAR(20) | 5 months ago payment status | On-time, Late, Missed |
| `month_6` | VARCHAR(20) | 6 months ago (oldest) payment status | On-time, Late, Missed |

#### Payment Status Definitions:
- **On-time**: Payment received by due date
- **Late**: Payment received 1-30 days after due date
- **Missed**: Payment not received or received >30 days after due date

---

### System Fields

| Field Name | Data Type | Description | Example |
|------------|-----------|-------------|---------|
| `created_at` | TIMESTAMP | Record creation timestamp | 2026-01-21 10:30:00 |

---

## Calculated Fields (Analysis Views)

### Risk Scoring Model

The following fields are calculated during analysis:

| Field Name | Data Type | Description | Formula |
|------------|-----------|-------------|---------|
| `delinquency_probability` | DECIMAL(10,3) | Predicted probability of delinquency | (missed_payments/6 × 0.30) + (credit_utilization × 0.25) + ((850-credit_score)/850 × 0.25) + (debt_to_income_ratio × 0.20) |
| `risk_tier` | VARCHAR(10) | Risk classification category | HIGH (≥0.70), MEDIUM (0.30-0.69), LOW (<0.30) |
| `collection_action` | VARCHAR(50) | Recommended collection strategy | IMMEDIATE_ACTION, PROACTIVE_MONITORING, STANDARD_MONITORING, LOW_PRIORITY |

---

## Key Metrics & Thresholds

### Risk Assessment Weights

The delinquency probability model uses the following weights:

| Factor | Weight | Rationale |
|--------|--------|-----------|
| Payment History (missed_payments) | 30% | Strongest predictor of future behavior |
| Credit Utilization | 25% | Indicates financial stress |
| Credit Score | 25% | Historical creditworthiness |
| Debt-to-Income Ratio | 20% | Capacity to repay |

### Risk Tier Definitions

| Risk Tier | Probability Range | Typical Characteristics | Recommended Action |
|-----------|-------------------|------------------------|-------------------|
| **LOW** | 0% - 30% | Good payment history, low utilization, high credit score | Standard monitoring |
| **MEDIUM** | 30% - 70% | Some late payments, moderate utilization | Proactive outreach |
| **HIGH** | 70% - 100% | Multiple missed payments, high utilization, low score | Immediate intervention |

---

## Data Quality Notes

### Missing Values
- `loan_balance`: Approximately 5-10% NULL (customers without loans)
- All other fields: Complete data

### Data Validation Rules
1. `credit_utilization`: Must be between 0.0 and 1.0
2. `credit_score`: Must be between 300 and 850
3. `age`: Must be ≥18 years
4. `missed_payments`: Cannot exceed 6 (6-month window)
5. `delinquent_account`: Binary (0 or 1)

### Outlier Considerations
- Income values >$300K flagged for review (potential data entry errors)
- Credit utilization >0.95 indicates maxed-out credit
- Debt-to-income ratio >0.60 indicates severe financial stress

---

## Usage Examples

### Basic Query
```sql
SELECT 
    customer_id,
    age,
    income,
    credit_score,
    missed_payments,
    delinquent_account
FROM delinquency_prediction
WHERE credit_score < 600
    AND missed_payments >= 3;
```

### Risk Calculation
```sql
SELECT 
    customer_id,
    ROUND(
        (missed_payments / 6.0 * 0.30 +
         credit_utilization * 0.25 +
         (850 - credit_score) / 850.0 * 0.25 +
         debt_to_income_ratio * 0.20),
        3
    ) AS delinquency_probability
FROM delinquency_prediction;
```

---

## Data Refresh & Updates

- **Frequency**: Monthly
- **Payment History**: Rolling 6-month window
- **Credit Scores**: Updated from credit bureaus monthly
- **Income**: Updated annually or upon customer notification

---

## Related Documentation

- [README.md](../README.md) - Project overview and business context
- [risk_analysis.sql](../sql/risk_analysis.sql) - Risk scoring queries
- [customer_segmentation.sql](../sql/customer_segmentation.sql) - Segmentation analysis
- [fairness_audit.sql](../sql/fairness_audit.sql) - Bias detection queries

---

**Last Updated**: January 2026  
**Version**: 1.0
