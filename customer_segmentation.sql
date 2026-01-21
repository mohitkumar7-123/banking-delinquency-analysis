-- =====================================================
-- CUSTOMER SEGMENTATION ANALYSIS
-- =====================================================
-- Purpose: Demographic and behavioral customer segmentation
-- Author: Mohit Kumar
-- Last Updated: January 2026
-- =====================================================

-- =====================================================
-- 1. INCOME-BASED SEGMENTATION
-- =====================================================

SELECT 
    CASE 
        WHEN income < 30000 THEN 'LOW_INCOME (<30K)'
        WHEN income BETWEEN 30000 AND 80000 THEN 'MIDDLE_INCOME (30K-80K)'
        WHEN income BETWEEN 80001 AND 150000 THEN 'UPPER_MIDDLE (80K-150K)'
        ELSE 'HIGH_INCOME (>150K)'
    END AS income_bracket,
    
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    
    -- Risk metrics
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Financial metrics
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio,
    
    -- Delinquency
    SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) AS actual_delinquents,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate

FROM risk_scores
GROUP BY 
    CASE 
        WHEN income < 30000 THEN 'LOW_INCOME (<30K)'
        WHEN income BETWEEN 30000 AND 80000 THEN 'MIDDLE_INCOME (30K-80K)'
        WHEN income BETWEEN 80001 AND 150000 THEN 'UPPER_MIDDLE (80K-150K)'
        ELSE 'HIGH_INCOME (>150K)'
    END
ORDER BY avg_risk_score DESC;


-- =====================================================
-- 2. EMPLOYMENT STATUS ANALYSIS
-- =====================================================

SELECT 
    employment_status,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    
    -- Risk distribution
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk,
    SUM(CASE WHEN risk_tier = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_risk,
    SUM(CASE WHEN risk_tier = 'LOW' THEN 1 ELSE 0 END) AS low_risk,
    
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_percentage,
    
    -- Key metrics
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments,
    
    -- Actual delinquency
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate

FROM risk_scores
GROUP BY employment_status
ORDER BY high_risk_percentage DESC;


-- =====================================================
-- 3. GEOGRAPHIC DISTRIBUTION
-- =====================================================

SELECT 
    location,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS market_share,
    
    -- Risk breakdown
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
    SUM(CASE WHEN risk_tier = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_risk_count,
    SUM(CASE WHEN risk_tier = 'LOW' THEN 1 ELSE 0 END) AS low_risk_count,
    
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    
    -- Financial profile
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(loan_balance), 0) AS avg_loan_balance,
    
    -- Delinquency metrics
    SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) AS delinquent_customers,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS delinquency_rate

FROM risk_scores
GROUP BY location
ORDER BY high_risk_count DESC;


-- =====================================================
-- 4. CREDIT CARD TYPE ANALYSIS
-- =====================================================

SELECT 
    credit_card_type,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio,
    
    -- Risk metrics
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_customers,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Customer profile
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(account_tenure), 1) AS avg_tenure_months,
    
    -- Financial exposure
    ROUND(AVG(loan_balance), 0) AS avg_loan_balance,
    ROUND(SUM(loan_balance), 0) AS total_loan_exposure,
    
    -- Delinquency
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate

FROM risk_scores
GROUP BY credit_card_type
ORDER BY high_risk_rate DESC;


-- =====================================================
-- 5. AGE GROUP SEGMENTATION
-- =====================================================

SELECT 
    CASE 
        WHEN age < 25 THEN '18-24 (Young Adult)'
        WHEN age BETWEEN 25 AND 34 THEN '25-34 (Early Career)'
        WHEN age BETWEEN 35 AND 44 THEN '35-44 (Mid Career)'
        WHEN age BETWEEN 45 AND 54 THEN '45-54 (Established)'
        WHEN age BETWEEN 55 AND 64 THEN '55-64 (Pre-Retirement)'
        ELSE '65+ (Retirement)'
    END AS age_group,
    
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_distribution,
    
    -- Risk profile
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Financial characteristics
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments,
    
    -- Account maturity
    ROUND(AVG(account_tenure), 1) AS avg_tenure_months

FROM risk_scores
GROUP BY 
    CASE 
        WHEN age < 25 THEN '18-24 (Young Adult)'
        WHEN age BETWEEN 25 AND 34 THEN '25-34 (Early Career)'
        WHEN age BETWEEN 35 AND 44 THEN '35-44 (Mid Career)'
        WHEN age BETWEEN 45 AND 54 THEN '45-54 (Established)'
        WHEN age BETWEEN 55 AND 64 THEN '55-64 (Pre-Retirement)'
        ELSE '65+ (Retirement)'
    END
ORDER BY avg_risk_score DESC;


-- =====================================================
-- 6. CREDIT UTILIZATION BANDS
-- =====================================================

SELECT 
    CASE 
        WHEN credit_utilization < 0.30 THEN 'LOW (<30%)'
        WHEN credit_utilization BETWEEN 0.30 AND 0.50 THEN 'MODERATE (30-50%)'
        WHEN credit_utilization BETWEEN 0.50 AND 0.70 THEN 'HIGH (50-70%)'
        ELSE 'CRITICAL (>70%)'
    END AS utilization_band,
    
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    
    -- Risk correlation
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Other risk indicators
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio,
    
    -- Financial stress indicators
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(loan_balance), 0) AS avg_loan_balance

FROM risk_scores
GROUP BY 
    CASE 
        WHEN credit_utilization < 0.30 THEN 'LOW (<30%)'
        WHEN credit_utilization BETWEEN 0.30 AND 0.50 THEN 'MODERATE (30-50%)'
        WHEN credit_utilization BETWEEN 0.50 AND 0.70 THEN 'HIGH (50-70%)'
        ELSE 'CRITICAL (>70%)'
    END
ORDER BY avg_risk_score DESC;


-- =====================================================
-- 7. ACCOUNT TENURE ANALYSIS
-- =====================================================

SELECT 
    CASE 
        WHEN account_tenure < 6 THEN '0-6 months (New)'
        WHEN account_tenure BETWEEN 6 AND 12 THEN '6-12 months'
        WHEN account_tenure BETWEEN 13 AND 24 THEN '1-2 years'
        ELSE '2+ years (Established)'
    END AS tenure_group,
    
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    
    -- Risk metrics
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Customer characteristics
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    
    -- Delinquency
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate

FROM risk_scores
GROUP BY 
    CASE 
        WHEN account_tenure < 6 THEN '0-6 months (New)'
        WHEN account_tenure BETWEEN 6 AND 12 THEN '6-12 months'
        WHEN account_tenure BETWEEN 13 AND 24 THEN '1-2 years'
        ELSE '2+ years (Established)'
    END
ORDER BY avg_risk_score DESC;


-- =====================================================
-- 8. CREDIT SCORE DISTRIBUTION
-- =====================================================

SELECT 
    CASE 
        WHEN credit_score < 300 THEN 'Very Poor (<300)'
        WHEN credit_score BETWEEN 300 AND 579 THEN 'Poor (300-579)'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END AS credit_score_range,
    
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    
    -- Risk correlation
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    
    -- Other metrics
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio

FROM risk_scores
GROUP BY 
    CASE 
        WHEN credit_score < 300 THEN 'Very Poor (<300)'
        WHEN credit_score BETWEEN 300 AND 579 THEN 'Poor (300-579)'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800+)'
    END
ORDER BY avg_risk_score DESC;


-- =====================================================
-- 9. MULTI-DIMENSIONAL RISK SEGMENTS
-- =====================================================
-- High-value segmentation combining multiple factors

SELECT 
    -- Segment definition
    CASE 
        WHEN income < 50000 AND employment_status = 'Unemployed' THEN 'High Risk - Low Income Unemployed'
        WHEN credit_score < 500 AND missed_payments >= 4 THEN 'High Risk - Poor Payment History'
        WHEN credit_utilization > 0.70 AND debt_to_income_ratio > 0.40 THEN 'High Risk - Financial Stress'
        WHEN income > 150000 AND credit_score > 700 THEN 'Low Risk - Premium'
        WHEN credit_score > 650 AND missed_payments <= 2 THEN 'Low Risk - Stable'
        ELSE 'Medium Risk - Standard'
    END AS customer_segment,
    
    COUNT(*) AS segment_size,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    
    -- Risk profile
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Average characteristics
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments,
    
    -- Business value
    ROUND(AVG(loan_balance), 0) AS avg_loan_balance,
    ROUND(SUM(loan_balance), 0) AS total_exposure

FROM risk_scores
GROUP BY 
    CASE 
        WHEN income < 50000 AND employment_status = 'Unemployed' THEN 'High Risk - Low Income Unemployed'
        WHEN credit_score < 500 AND missed_payments >= 4 THEN 'High Risk - Poor Payment History'
        WHEN credit_utilization > 0.70 AND debt_to_income_ratio > 0.40 THEN 'High Risk - Financial Stress'
        WHEN income > 150000 AND credit_score > 700 THEN 'Low Risk - Premium'
        WHEN credit_score > 650 AND missed_payments <= 2 THEN 'Low Risk - Stable'
        ELSE 'Medium Risk - Standard'
    END
ORDER BY avg_risk_score DESC;


-- =====================================================
-- 10. CROSS-SEGMENT COMPARISON MATRIX
-- =====================================================

SELECT 
    employment_status,
    credit_card_type,
    COUNT(*) AS customers,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk,
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score
FROM risk_scores
GROUP BY employment_status, credit_card_type
HAVING COUNT(*) >= 5
ORDER BY avg_risk DESC
LIMIT 30;
