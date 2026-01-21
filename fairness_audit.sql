-- =====================================================
-- FAIRNESS & BIAS AUDIT ANALYSIS
-- =====================================================
-- Purpose: Ensure equitable treatment across demographics
-- Author: Mohit Kumar
-- Last Updated: January 2026
-- =====================================================

-- =====================================================
-- 1. DEMOGRAPHIC PARITY CHECK
-- =====================================================
-- Ensures similar risk classification rates across groups

SELECT 
    employment_status,
    COUNT(*) AS total_customers,
    
    -- Risk tier distribution
    SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
    SUM(CASE WHEN risk_tier = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_risk_count,
    SUM(CASE WHEN risk_tier = 'LOW' THEN 1 ELSE 0 END) AS low_risk_count,
    
    -- Ratios for parity analysis
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
        3
    ) AS high_risk_ratio,
    
    ROUND(
        SUM(CASE WHEN risk_tier = 'MEDIUM' THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
        3
    ) AS medium_risk_ratio,
    
    ROUND(
        SUM(CASE WHEN risk_tier = 'LOW' THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
        3
    ) AS low_risk_ratio,
    
    -- Actual outcomes
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
        3
    ) AS actual_delinquency_ratio

FROM risk_scores
GROUP BY employment_status
ORDER BY high_risk_ratio DESC;


-- =====================================================
-- 2. INCOME-BASED FAIRNESS CHECK
-- =====================================================
-- Identifies potential income-based discrimination

SELECT 
    CASE 
        WHEN income < 30000 THEN 'LOW_INCOME'
        WHEN income BETWEEN 30000 AND 80000 THEN 'MID_INCOME'
        ELSE 'HIGH_INCOME'
    END AS income_group,
    
    COUNT(*) AS total_customers,
    
    -- High risk rate
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Actual delinquency rate
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    
    -- Performance gap (prediction vs actual)
    ROUND(
        (SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) -
        (SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)),
        2
    ) AS prediction_gap,
    
    -- Key indicators
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(missed_payments), 2) AS avg_missed_payments

FROM risk_scores
GROUP BY 
    CASE 
        WHEN income < 30000 THEN 'LOW_INCOME'
        WHEN income BETWEEN 30000 AND 80000 THEN 'MID_INCOME'
        ELSE 'HIGH_INCOME'
    END
ORDER BY high_risk_rate DESC;


-- =====================================================
-- 3. EQUALIZED ODDS ANALYSIS
-- =====================================================
-- Checks if true positive and false positive rates are similar

WITH predictions AS (
    SELECT 
        employment_status,
        risk_tier,
        delinquent_account,
        CASE 
            WHEN risk_tier = 'HIGH' AND delinquent_account = 1 THEN 'TRUE_POSITIVE'
            WHEN risk_tier = 'HIGH' AND delinquent_account = 0 THEN 'FALSE_POSITIVE'
            WHEN risk_tier != 'HIGH' AND delinquent_account = 1 THEN 'FALSE_NEGATIVE'
            ELSE 'TRUE_NEGATIVE'
        END AS prediction_outcome
    FROM risk_scores
)
SELECT 
    employment_status,
    COUNT(*) AS total,
    
    -- True Positive Rate (Sensitivity)
    ROUND(
        SUM(CASE WHEN prediction_outcome = 'TRUE_POSITIVE' THEN 1 ELSE 0 END) * 1.0 /
        NULLIF(SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END), 0),
        3
    ) AS true_positive_rate,
    
    -- False Positive Rate
    ROUND(
        SUM(CASE WHEN prediction_outcome = 'FALSE_POSITIVE' THEN 1 ELSE 0 END) * 1.0 /
        NULLIF(SUM(CASE WHEN delinquent_account = 0 THEN 1 ELSE 0 END), 0),
        3
    ) AS false_positive_rate,
    
    -- False Negative Rate
    ROUND(
        SUM(CASE WHEN prediction_outcome = 'FALSE_NEGATIVE' THEN 1 ELSE 0 END) * 1.0 /
        NULLIF(SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END), 0),
        3
    ) AS false_negative_rate,
    
    -- Accuracy
    ROUND(
        (SUM(CASE WHEN prediction_outcome IN ('TRUE_POSITIVE', 'TRUE_NEGATIVE') THEN 1 ELSE 0 END) * 1.0 / COUNT(*)),
        3
    ) AS accuracy

FROM predictions
GROUP BY employment_status
ORDER BY employment_status;


-- =====================================================
-- 4. DISPARATE IMPACT RATIO
-- =====================================================
-- Four-fifths rule: protected group rate / reference group rate >= 0.80

WITH group_rates AS (
    SELECT 
        employment_status,
        COUNT(*) AS total,
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS high_risk_count,
        ROUND(
            SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
            3
        ) AS high_risk_rate
    FROM risk_scores
    GROUP BY employment_status
),
reference_rate AS (
    SELECT MAX(high_risk_rate) AS max_rate
    FROM group_rates
)
SELECT 
    gr.employment_status,
    gr.total,
    gr.high_risk_count,
    gr.high_risk_rate,
    rr.max_rate AS reference_rate,
    ROUND(gr.high_risk_rate / NULLIF(rr.max_rate, 0), 3) AS disparate_impact_ratio,
    CASE 
        WHEN gr.high_risk_rate / NULLIF(rr.max_rate, 0) >= 0.80 THEN 'PASS'
        ELSE 'FAIL - POTENTIAL BIAS'
    END AS four_fifths_test
FROM group_rates gr
CROSS JOIN reference_rate rr
ORDER BY disparate_impact_ratio;


-- =====================================================
-- 5. CALIBRATION ANALYSIS
-- =====================================================
-- Checks if predicted probabilities match actual outcomes

SELECT 
    risk_tier,
    COUNT(*) AS total_customers,
    
    -- Predicted vs Actual
    ROUND(AVG(delinquency_probability) * 100, 2) AS avg_predicted_probability,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    
    -- Calibration gap
    ROUND(
        (AVG(delinquency_probability) * 100) - 
        (SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)),
        2
    ) AS calibration_gap,
    
    CASE 
        WHEN ABS(
            (AVG(delinquency_probability) * 100) - 
            (SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))
        ) <= 10 THEN 'WELL_CALIBRATED'
        WHEN ABS(
            (AVG(delinquency_probability) * 100) - 
            (SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))
        ) <= 20 THEN 'MODERATELY_CALIBRATED'
        ELSE 'POORLY_CALIBRATED'
    END AS calibration_status

FROM risk_scores
GROUP BY risk_tier
ORDER BY 
    CASE risk_tier 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;


-- =====================================================
-- 6. AGE-BASED FAIRNESS CHECK
-- =====================================================

SELECT 
    CASE 
        WHEN age < 30 THEN 'Young (<30)'
        WHEN age BETWEEN 30 AND 50 THEN 'Middle (30-50)'
        ELSE 'Senior (50+)'
    END AS age_group,
    
    COUNT(*) AS total_customers,
    
    -- Risk distribution
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    -- Actual outcomes
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    
    -- Key factors
    ROUND(AVG(income), 0) AS avg_income,
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(credit_utilization), 3) AS avg_utilization,
    ROUND(AVG(debt_to_income_ratio), 3) AS avg_dti_ratio,
    
    -- Statistical significance
    COUNT(*) AS sample_size

FROM risk_scores
GROUP BY 
    CASE 
        WHEN age < 30 THEN 'Young (<30)'
        WHEN age BETWEEN 30 AND 50 THEN 'Middle (30-50)'
        ELSE 'Senior (50+)'
    END
ORDER BY high_risk_rate DESC;


-- =====================================================
-- 7. GEOGRAPHIC FAIRNESS AUDIT
-- =====================================================

WITH location_stats AS (
    SELECT 
        location,
        COUNT(*) AS total_customers,
        ROUND(
            SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS high_risk_rate,
        ROUND(
            SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS actual_delinquency_rate,
        ROUND(AVG(income), 0) AS avg_income,
        ROUND(AVG(credit_score), 0) AS avg_credit_score
    FROM risk_scores
    GROUP BY location
),
overall_stats AS (
    SELECT 
        AVG(high_risk_rate) AS avg_high_risk_rate,
        STDDEV(high_risk_rate) AS stddev_high_risk_rate
    FROM location_stats
)
SELECT 
    ls.*,
    os.avg_high_risk_rate AS portfolio_avg_high_risk,
    ROUND(ls.high_risk_rate - os.avg_high_risk_rate, 2) AS deviation_from_average,
    CASE 
        WHEN ABS(ls.high_risk_rate - os.avg_high_risk_rate) > (2 * os.stddev_high_risk_rate) 
            THEN 'SIGNIFICANT_DEVIATION'
        WHEN ABS(ls.high_risk_rate - os.avg_high_risk_rate) > os.stddev_high_risk_rate 
            THEN 'MODERATE_DEVIATION'
        ELSE 'NORMAL_RANGE'
    END AS fairness_flag
FROM location_stats ls
CROSS JOIN overall_stats os
ORDER BY deviation_from_average DESC;


-- =====================================================
-- 8. PREDICTIVE PARITY CHECK
-- =====================================================
-- PPV (Positive Predictive Value) should be similar across groups

WITH confusion_matrix AS (
    SELECT 
        employment_status,
        COUNT(*) AS total,
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) AS predicted_high_risk,
        SUM(CASE WHEN risk_tier = 'HIGH' AND delinquent_account = 1 THEN 1 ELSE 0 END) AS true_positives,
        SUM(CASE WHEN risk_tier = 'HIGH' AND delinquent_account = 0 THEN 1 ELSE 0 END) AS false_positives
    FROM risk_scores
    GROUP BY employment_status
)
SELECT 
    employment_status,
    total,
    predicted_high_risk,
    true_positives,
    false_positives,
    
    -- Positive Predictive Value (Precision)
    ROUND(
        true_positives * 1.0 / NULLIF(predicted_high_risk, 0),
        3
    ) AS positive_predictive_value,
    
    -- False Discovery Rate
    ROUND(
        false_positives * 1.0 / NULLIF(predicted_high_risk, 0),
        3
    ) AS false_discovery_rate,
    
    CASE 
        WHEN true_positives * 1.0 / NULLIF(predicted_high_risk, 0) >= 0.50 
            THEN 'ACCEPTABLE'
        ELSE 'REVIEW_NEEDED'
    END AS ppv_status

FROM confusion_matrix
ORDER BY positive_predictive_value DESC;


-- =====================================================
-- 9. INTERSECTIONAL FAIRNESS ANALYSIS
-- =====================================================
-- Multi-dimensional bias detection

SELECT 
    employment_status,
    CASE 
        WHEN income < 50000 THEN 'Low Income'
        ELSE 'Higher Income'
    END AS income_level,
    
    COUNT(*) AS total_customers,
    
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    
    -- Fairness gap
    ROUND(
        (SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) -
        (SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)),
        2
    ) AS prediction_fairness_gap,
    
    ROUND(AVG(credit_score), 0) AS avg_credit_score,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score

FROM risk_scores
GROUP BY 
    employment_status,
    CASE 
        WHEN income < 50000 THEN 'Low Income'
        ELSE 'Higher Income'
    END
HAVING COUNT(*) >= 10
ORDER BY high_risk_rate DESC;


-- =====================================================
-- 10. FAIRNESS SUMMARY DASHBOARD
-- =====================================================

SELECT 
    'Overall Portfolio' AS metric_group,
    COUNT(*) AS total_customers,
    ROUND(AVG(delinquency_probability), 3) AS avg_risk_score,
    ROUND(
        SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS high_risk_rate,
    ROUND(
        SUM(CASE WHEN delinquent_account = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS actual_delinquency_rate,
    
    -- Fairness metrics
    ROUND(STDDEV(delinquency_probability), 3) AS risk_score_variance,
    ROUND(
        MAX(delinquency_probability) - MIN(delinquency_probability),
        3
    ) AS risk_score_range

FROM risk_scores

UNION ALL

SELECT 
    'By Employment Status' AS metric_group,
    NULL AS total_customers,
    NULL AS avg_risk_score,
    ROUND(MAX(high_risk_rate) - MIN(high_risk_rate), 2) AS high_risk_rate_range,
    NULL AS actual_delinquency_rate,
    NULL AS risk_score_variance,
    NULL AS risk_score_range
FROM (
    SELECT 
        ROUND(
            SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS high_risk_rate
    FROM risk_scores
    GROUP BY employment_status
) emp_stats

UNION ALL

SELECT 
    'By Income Level' AS metric_group,
    NULL AS total_customers,
    NULL AS avg_risk_score,
    ROUND(MAX(high_risk_rate) - MIN(high_risk_rate), 2) AS high_risk_rate_range,
    NULL AS actual_delinquency_rate,
    NULL AS risk_score_variance,
    NULL AS risk_score_range
FROM (
    SELECT 
        ROUND(
            SUM(CASE WHEN risk_tier = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
            2
        ) AS high_risk_rate
    FROM risk_scores
    GROUP BY 
        CASE 
            WHEN income < 30000 THEN 'LOW'
            WHEN income < 80000 THEN 'MID'
            ELSE 'HIGH'
        END
) income_stats;
