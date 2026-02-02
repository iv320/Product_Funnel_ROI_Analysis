-- ============================================
-- RETENTION & CHURN ANALYSIS QUERIES
-- Product Analytics Project
-- ============================================

-- This file contains SQL queries to analyze user retention and churn patterns
-- Metrics: Cohort retention, repeat purchases, churn rates

-- ============================================
-- 1. COHORT RETENTION ANALYSIS (Monthly)
-- ============================================

WITH user_cohorts AS (
    SELECT 
        user_id,
        FORMAT(signup_date, 'yyyy-MM') AS cohort_month,
        signup_date
    FROM users
),
user_activity AS (
    SELECT DISTINCT
        e.user_id,
        FORMAT(e.event_date, 'yyyy-MM') AS activity_month
    FROM events e
    WHERE e.event_name IN ('visit', 'add_to_cart', 'purchase')
)
SELECT 
    uc.cohort_month,
    COUNT(DISTINCT uc.user_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN ua.activity_month = uc.cohort_month THEN uc.user_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 1 THEN uc.user_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 2 THEN uc.user_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 3 THEN uc.user_id END) AS month_3,
    COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 4 THEN uc.user_id END) AS month_4,
    COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 5 THEN uc.user_id END) AS month_5
FROM user_cohorts uc
LEFT JOIN user_activity ua ON uc.user_id = ua.user_id
GROUP BY uc.cohort_month
ORDER BY uc.cohort_month;


-- ============================================
-- 2. COHORT RETENTION RATES (Percentage)
-- ============================================

WITH user_cohorts AS (
    SELECT 
        user_id,
        FORMAT(signup_date, 'yyyy-MM') AS cohort_month,
        signup_date
    FROM users
),
user_activity AS (
    SELECT DISTINCT
        e.user_id,
        FORMAT(e.event_date, 'yyyy-MM') AS activity_month
    FROM events e
    WHERE e.event_name IN ('visit', 'add_to_cart', 'purchase')
),
cohort_counts AS (
    SELECT 
        uc.cohort_month,
        COUNT(DISTINCT uc.user_id) AS cohort_size,
        COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 0 THEN uc.user_id END) AS month_0,
        COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 1 THEN uc.user_id END) AS month_1,
        COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 2 THEN uc.user_id END) AS month_2,
        COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, uc.signup_date, CAST(ua.activity_month + '-01' AS DATE)) = 3 THEN uc.user_id END) AS month_3
    FROM user_cohorts uc
    LEFT JOIN user_activity ua ON uc.user_id = ua.user_id
    GROUP BY uc.cohort_month
)
SELECT 
    cohort_month,
    cohort_size,
    ROUND(100.0 * month_0 / cohort_size, 2) AS retention_month_0,
    ROUND(100.0 * month_1 / NULLIF(cohort_size, 0), 2) AS retention_month_1,
    ROUND(100.0 * month_2 / NULLIF(cohort_size, 0), 2) AS retention_month_2,
    ROUND(100.0 * month_3 / NULLIF(cohort_size, 0), 2) AS retention_month_3
FROM cohort_counts
ORDER BY cohort_month;


-- ============================================
-- 3. REPEAT PURCHASE ANALYSIS
-- ============================================

WITH purchase_counts AS (
    SELECT 
        user_id,
        COUNT(*) AS num_purchases,
        MIN(event_date) AS first_purchase_date,
        MAX(event_date) AS last_purchase_date
    FROM events
    WHERE event_name = 'purchase'
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN num_purchases = 1 THEN '1 Purchase'
        WHEN num_purchases = 2 THEN '2 Purchases'
        WHEN num_purchases = 3 THEN '3 Purchases'
        WHEN num_purchases >= 4 THEN '4+ Purchases'
    END AS purchase_frequency,
    COUNT(*) AS num_users,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_purchasers
FROM purchase_counts
GROUP BY 
    CASE 
        WHEN num_purchases = 1 THEN '1 Purchase'
        WHEN num_purchases = 2 THEN '2 Purchases'
        WHEN num_purchases = 3 THEN '3 Purchases'
        WHEN num_purchases >= 4 THEN '4+ Purchases'
    END
ORDER BY 
    CASE 
        WHEN purchase_frequency = '1 Purchase' THEN 1
        WHEN purchase_frequency = '2 Purchases' THEN 2
        WHEN purchase_frequency = '3 Purchases' THEN 3
        ELSE 4
    END;


-- ============================================
-- 4. REPEAT PURCHASE RATE
-- ============================================

WITH purchaser_counts AS (
    SELECT 
        user_id,
        COUNT(*) AS num_purchases
    FROM events
    WHERE event_name = 'purchase'
    GROUP BY user_id
)
SELECT 
    COUNT(DISTINCT user_id) AS total_purchasers,
    COUNT(DISTINCT CASE WHEN num_purchases > 1 THEN user_id END) AS repeat_purchasers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN num_purchases > 1 THEN user_id END) / 
          COUNT(DISTINCT user_id), 2) AS repeat_purchase_rate
FROM purchaser_counts;


-- ============================================
-- 5. DAYS TO SECOND PURCHASE
-- ============================================

WITH purchase_dates AS (
    SELECT 
        user_id,
        event_date,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_date) AS purchase_number
    FROM events
    WHERE event_name = 'purchase'
),
first_two_purchases AS (
    SELECT 
        user_id,
        MAX(CASE WHEN purchase_number = 1 THEN event_date END) AS first_purchase,
        MAX(CASE WHEN purchase_number = 2 THEN event_date END) AS second_purchase
    FROM purchase_dates
    WHERE purchase_number <= 2
    GROUP BY user_id
    HAVING MAX(CASE WHEN purchase_number = 2 THEN event_date END) IS NOT NULL
)
SELECT 
    AVG(DATEDIFF(DAY, first_purchase, second_purchase)) AS avg_days_to_second_purchase,
    MIN(DATEDIFF(DAY, first_purchase, second_purchase)) AS min_days_to_second_purchase,
    MAX(DATEDIFF(DAY, first_purchase, second_purchase)) AS max_days_to_second_purchase,
    COUNT(*) AS users_with_repeat_purchase
FROM first_two_purchases;


-- ============================================
-- 6. CHURN IDENTIFICATION
-- ============================================

-- Users who haven't had any activity in the last 30 days
WITH last_activity AS (
    SELECT 
        user_id,
        MAX(event_date) AS last_activity_date,
        DATEDIFF(DAY, MAX(event_date), GETDATE()) AS days_since_last_activity
    FROM events
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN days_since_last_activity <= 7 THEN 'Active (0-7 days)'
        WHEN days_since_last_activity <= 30 THEN 'At Risk (8-30 days)'
        WHEN days_since_last_activity <= 60 THEN 'Churned (31-60 days)'
        ELSE 'Lost (60+ days)'
    END AS user_status,
    COUNT(*) AS num_users,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM last_activity
GROUP BY 
    CASE 
        WHEN days_since_last_activity <= 7 THEN 'Active (0-7 days)'
        WHEN days_since_last_activity <= 30 THEN 'At Risk (8-30 days)'
        WHEN days_since_last_activity <= 60 THEN 'Churned (31-60 days)'
        ELSE 'Lost (60+ days)'
    END
ORDER BY 
    CASE 
        WHEN user_status = 'Active (0-7 days)' THEN 1
        WHEN user_status = 'At Risk (8-30 days)' THEN 2
        WHEN user_status = 'Churned (31-60 days)' THEN 3
        ELSE 4
    END;


-- ============================================
-- 7. RETENTION BY ACQUISITION SOURCE
-- ============================================

WITH user_activity AS (
    SELECT 
        u.user_id,
        u.acquisition_source,
        c.campaign_name,
        u.signup_date,
        MAX(e.event_date) AS last_activity_date,
        COUNT(DISTINCT e.event_date) AS active_days,
        COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.event_id END) AS num_purchases
    FROM users u
    LEFT JOIN events e ON u.user_id = e.user_id
    LEFT JOIN campaigns c ON u.acquisition_source = c.campaign_id
    GROUP BY u.user_id, u.acquisition_source, c.campaign_name, u.signup_date
)
SELECT 
    campaign_name,
    COUNT(*) AS total_users,
    AVG(active_days) AS avg_active_days,
    AVG(num_purchases) AS avg_purchases_per_user,
    COUNT(CASE WHEN num_purchases > 1 THEN 1 END) AS repeat_purchasers,
    ROUND(100.0 * COUNT(CASE WHEN num_purchases > 1 THEN 1 END) / COUNT(*), 2) AS repeat_purchase_rate,
    COUNT(CASE WHEN DATEDIFF(DAY, last_activity_date, GETDATE()) > 30 THEN 1 END) AS churned_users,
    ROUND(100.0 * COUNT(CASE WHEN DATEDIFF(DAY, last_activity_date, GETDATE()) > 30 THEN 1 END) / COUNT(*), 2) AS churn_rate
FROM user_activity
GROUP BY campaign_name
ORDER BY repeat_purchase_rate DESC;


-- ============================================
-- 8. CUSTOMER LIFETIME VALUE ESTIMATION
-- ============================================

WITH user_metrics AS (
    SELECT 
        u.user_id,
        u.signup_date,
        c.campaign_name,
        COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.event_id END) AS num_purchases,
        SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) AS total_revenue,
        DATEDIFF(DAY, u.signup_date, MAX(e.event_date)) AS customer_lifespan_days
    FROM users u
    LEFT JOIN events e ON u.user_id = e.user_id
    LEFT JOIN campaigns c ON u.acquisition_source = c.campaign_id
    GROUP BY u.user_id, u.signup_date, c.campaign_name
)
SELECT 
    campaign_name,
    COUNT(*) AS total_users,
    ROUND(AVG(total_revenue), 2) AS avg_ltv,
    ROUND(AVG(num_purchases), 2) AS avg_purchases,
    ROUND(AVG(customer_lifespan_days), 1) AS avg_lifespan_days,
    ROUND(AVG(CASE WHEN num_purchases > 0 THEN total_revenue / num_purchases END), 2) AS avg_order_value
FROM user_metrics
GROUP BY campaign_name
ORDER BY avg_ltv DESC;


-- ============================================
-- 9. EARLY ENGAGEMENT IMPACT ON RETENTION
-- ============================================

-- Users who purchase in first 7 days vs later
WITH first_purchase AS (
    SELECT 
        u.user_id,
        u.signup_date,
        MIN(e.event_date) AS first_purchase_date,
        DATEDIFF(DAY, u.signup_date, MIN(e.event_date)) AS days_to_first_purchase
    FROM users u
    JOIN events e ON u.user_id = e.user_id
    WHERE e.event_name = 'purchase'
    GROUP BY u.user_id, u.signup_date
),
user_purchases AS (
    SELECT 
        fp.user_id,
        fp.days_to_first_purchase,
        COUNT(*) AS total_purchases,
        SUM(e.revenue) AS total_revenue
    FROM first_purchase fp
    JOIN events e ON fp.user_id = e.user_id
    WHERE e.event_name = 'purchase'
    GROUP BY fp.user_id, fp.days_to_first_purchase
)
SELECT 
    CASE 
        WHEN days_to_first_purchase <= 7 THEN 'Purchased in First Week'
        ELSE 'Purchased After First Week'
    END AS user_segment,
    COUNT(*) AS num_users,
    ROUND(AVG(total_purchases), 2) AS avg_purchases,
    ROUND(AVG(total_revenue), 2) AS avg_revenue,
    ROUND(100.0 * COUNT(CASE WHEN total_purchases > 1 THEN 1 END) / COUNT(*), 2) AS repeat_purchase_rate
FROM user_purchases
GROUP BY 
    CASE 
        WHEN days_to_first_purchase <= 7 THEN 'Purchased in First Week'
        ELSE 'Purchased After First Week'
    END;


-- ============================================
-- 10. MONTHLY CHURN RATE TREND
-- ============================================

WITH monthly_cohorts AS (
    SELECT 
        FORMAT(signup_date, 'yyyy-MM') AS cohort_month,
        user_id
    FROM users
),
churned_users AS (
    SELECT 
        mc.cohort_month,
        mc.user_id,
        MAX(e.event_date) AS last_activity
    FROM monthly_cohorts mc
    LEFT JOIN events e ON mc.user_id = e.user_id
    GROUP BY mc.cohort_month, mc.user_id
)
SELECT 
    cohort_month,
    COUNT(*) AS cohort_size,
    COUNT(CASE WHEN DATEDIFF(DAY, last_activity, GETDATE()) > 30 THEN 1 END) AS churned,
    ROUND(100.0 * COUNT(CASE WHEN DATEDIFF(DAY, last_activity, GETDATE()) > 30 THEN 1 END) / COUNT(*), 2) AS churn_rate
FROM churned_users
GROUP BY cohort_month
ORDER BY cohort_month;
