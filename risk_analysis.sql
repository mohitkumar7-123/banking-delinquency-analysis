-- =====================================================
-- BANKING DELINQUENCY RISK ANALYSIS
-- =====================================================
-- Purpose: Comprehensive risk assessment and scoring
-- Author: Mohit Kumar
-- Last Updated: January 2026
-- =====================================================

-- =====================================================
-- 1. RISK SCORING MODEL
-- =====================================================
-- Calculate delinquency probability based on weighted factors

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
    
    -- Calculate risk score (0-1 scale)
    ROUND(
        (
            -- Weight: 30% - Payment history is strongest predictor
            (CAST(missed_payments AS DECIMAL) / 6.0) * 0.30 +
            
            -- Weight: 25% - Credit utilization indicates financial stress
            credit_utilization * 0.25 +
            
            -- Weight: 25% - Credit score (inverted, lower score = higher risk)
            ((850.0 - CAST(credit_score AS DECIMAL)) / 850.0) * 0.25 +
            
            -- Weight: 20% - Debt-to-income ratio
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
    
    -- Collection action recommendation
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


-- =====================================================
-- 2. RISK DISTRIBUTION OVERVIEW
-- =====================================================

SELECT 
    risk_tier,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    MIN(delinquency_probability) AS min_risk_score,
    MAX(delinquency_probability) AS max_risk_score
FROM risk_scores
GROUP BY risk_tier
ORDER BY 
    CASE risk_tier 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;


-- =====================================================
-- 3. TOP HIGH-RISK CUSTOMERS
-- =====================================================
-- Identify customers requiring immediate attention

SELECT 
    customer_id,
    age,
    income,
    credit_score,
    missed_payments,
    credit_utilization,
    debt_to_income_ratio,
    employment_status,
    delinquency_probability,
    risk_tier,
    collection_action
FROM risk_scores
WHERE risk_tier = 'HIGH'
ORDER BY delinquency_probability DESC
LIMIT 50;


-- =====================================================
-- 4. COLLECTION ACTION BREAKDOWN
-- =====================================================

SELECT 
    collection_action,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score
FROM risk_scores
GROUP BY collection_action
ORDER BY 
    CASE collection_action 
        WHEN 'IMMEDIATE_ACTION' THEN 1 
        WHEN 'PROACTIVE_MONITORING' THEN 2 
        WHEN 'STANDARD_MONITORING' THEN 3 
        WHEN 'LOW_PRIORITY' THEN 4 
    END;


-- =====================================================
-- 5. RISK VS ACTUAL DELINQUENCY ACCURACY
-- =====================================================
-- Validate model prediction accuracy

SELECT 
    risk_tier,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) AS actual_delinquents,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    ROUND(AVG(delinquency_probability) * 100, 2) AS predicted_delinquency_rate
FROM risk_scores
GROUP BY risk_tier
ORDER BY 
    CASE risk_tier 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;


-- =====================================================
-- 6. RISK PROBABILITY BANDS
-- =====================================================

SELECT 
    CASE 
        WHEN delinquency_probability < 0.20 THEN '0-20%'
        WHEN delinquency_probability < 0.40 THEN '20-40%'
        WHEN delinquency_probability < 0.60 THEN '40-60%'
        WHEN delinquency_probability < 0.80 THEN '60-80%'
        ELSE '80-100%'
    END AS probability_band,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM risk_scores
GROUP BY 
    CASE 
        WHEN delinquency_probability < 0.20 THEN '0-20%'
        WHEN delinquency_probability < 0.40 THEN '20-40%'
        WHEN delinquency_probability < 0.60 THEN '40-60%'
        WHEN delinquency_probability < 0.80 THEN '60-80%'
        ELSE '80-100%'
    END
ORDER BY probability_band;


-- =====================================================
-- 7. TOP RISK DRIVERS BY TIER
-- =====================================================
-- Identify key characteristics of each risk segment

SELECT 
    risk_tier,
    COUNT(*) AS customers,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(missed_payments), 1) AS avg_missed_payments,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio,
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(CASE WHEN loan_balance IS NOT NULL THEN loan_balance ELSE 0 END), 0) AS avg_loan_balance
FROM risk_scores
GROUP BY risk_tier
ORDER BY 
    CASE risk_tier 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;


-- =====================================================
-- 8. EARLY WARNING INDICATORS
-- =====================================================
-- Customers showing deteriorating payment behavior

SELECT 
    customer_id,
    risk_tier,
    delinquency_probability,
    missed_payments,
    month_1 AS most_recent_payment,
    month_2,
    month_3,
    CASE 
        WHEN month_1 = 'Missed' AND month_2 IN ('Late', 'On-time') THEN 'RAPID_DECLINE'
        WHEN month_1 = 'Late' AND month_2 = 'On-time' AND month_3 = 'On-time' THEN 'EARLY_WARNING'
        WHEN month_1 = 'Missed' AND month_2 = 'Missed' THEN 'CRITICAL'
        ELSE 'STABLE'
    END AS trend_indicator
FROM risk_scores
WHERE risk_tier IN ('MEDIUM', 'HIGH')
    AND month_1 IN ('Late', 'Missed')
ORDER BY delinquency_probability DESC
LIMIT 100;


-- =====================================================
-- 9. EXECUTIVE SUMMARY - KEY RISK METRICS
-- =====================================================

SELECT 
    COUNT(*) AS total_customers,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    
    -- Delinquency metrics
    SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) AS total_delinquent,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS delinquency_rate,
    
    -- Risk tier breakdown
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
    SUM(CASE WHEN risk_tier = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_risk_count,
    SUM(CASE WHEN risk_tier = 'LOW' THEN 1 ELSE 0 END) AS low_risk_count,
    
    -- Financial exposure
    ROUND(SUM(CASE WHEN risk_tier = 'HIGH' THEN loan_balance ELSE 0 END), 0) AS high_risk_exposure,
    ROUND(AVG(CASE WHEN risk_tier = 'HIGH' THEN loan_balance END), 0) AS avg_high_risk_loan
    
FROM risk_scores;


-- =====================================================
-- 10. MONTH-OVER-MONTH PAYMENT DETERIORATION
-- =====================================================
-- Track payment pattern changes

WITH payment_trends AS (
    SELECT 
        customer_id,
        risk_tier,
        -- Count payment status types
        (CASE WHEN month_1 = 'On-time' THEN 1 ELSE 0 END +
         CASE WHEN month_2 = 'On-time' THEN 1 ELSE 0 END +
         CASE WHEN month_3 = 'On-time' THEN 1 ELSE 0 END +
         CASE WHEN month_4 = 'On-time' THEN 1 ELSE 0 END +
         CASE WHEN month_5 = 'On-time' THEN 1 ELSE 0 END +
         CASE WHEN month_6 = 'On-time' THEN 1 ELSE 0 END) AS ontime_count,
         
        (CASE WHEN month_1 = 'Late' THEN 1 ELSE 0 END +
         CASE WHEN month_2 = 'Late' THEN 1 ELSE 0 END +
         CASE WHEN month_3 = 'Late' THEN 1 ELSE 0 END +
         CASE WHEN month_4 = 'Late' THEN 1 ELSE 0 END +
         CASE WHEN month_5 = 'Late' THEN 1 ELSE 0 END +
         CASE WHEN month_6 = 'Late' THEN 1 ELSE 0 END) AS late_count,
         
        (CASE WHEN month_1 = 'Missed' THEN 1 ELSE 0 END +
         CASE WHEN month_2 = 'Missed' THEN 1 ELSE 0 END +
         CASE WHEN month_3 = 'Missed' THEN 1 ELSE 0 END +
         CASE WHEN month_4 = 'Missed' THEN 1 ELSE 0 END +
         CASE WHEN month_5 = 'Missed' THEN 1 ELSE 0 END +
         CASE WHEN month_6 = 'Missed' THEN 1 ELSE 0 END) AS missed_count
    FROM risk_scores
)
SELECT 
    CASE 
        WHEN ontime_count >= 5 THEN 'EXCELLENT'
        WHEN ontime_count >= 3 THEN 'GOOD'
        WHEN late_count >= 3 THEN 'CONCERNING'
        WHEN missed_count >= 3 THEN 'CRITICAL'
        ELSE 'MIXED'
    END AS payment_behavior,
    COUNT(*) AS customer_count,
    ROUND(AVG(ontime_count), 1) AS avg_ontime_payments,
    ROUND(AVG(late_count), 1) AS avg_late_payments,
    ROUND(AVG(missed_count), 1) AS avg_missed_payments
FROM payment_trends
GROUP BY 
    CASE 
        WHEN ontime_count >= 5 THEN 'EXCELLENT'
        WHEN ontime_count >= 3 THEN 'GOOD'
        WHEN late_count >= 3 THEN 'CONCERNING'
        WHEN missed_count >= 3 THEN 'CRITICAL'
        ELSE 'MIXED'
    END
ORDER BY customer_count DESC;
