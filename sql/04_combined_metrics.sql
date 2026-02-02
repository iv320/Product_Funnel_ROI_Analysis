-- ============================================
-- COMBINED METRICS FOR POWER BI
-- Product Analytics Project
-- ============================================

-- This file contains aggregated views optimized for Power BI import
-- These queries combine data from multiple tables for easy visualization

-- ============================================
-- VIEW 1: Daily Metrics Summary
-- ============================================

SELECT 
    CAST(e.event_date AS DATE) AS date,
    COUNT(DISTINCT e.user_id) AS active_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS visitors,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
    COUNT(CASE WHEN e.event_name = 'purchase' THEN 1 END) AS total_purchases,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS daily_revenue,
    ROUND(AVG(CASE WHEN e.event_name = 'purchase' THEN e.revenue END), 2) AS avg_order_value
FROM events e
GROUP BY CAST(e.event_date AS DATE)
ORDER BY date;


-- ============================================
-- VIEW 2: Campaign Summary for Power BI
-- ============================================

SELECT 
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.cost AS campaign_cost,
    COUNT(DISTINCT u.user_id) AS users_acquired,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS visitors,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
    COUNT(CASE WHEN e.event_name = 'purchase' THEN 1 END) AS total_purchases,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS total_revenue,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS conversion_rate,
    CASE 
        WHEN c.cost > 0 THEN ROUND(c.cost / NULLIF(COUNT(DISTINCT u.user_id), 0), 2)
        ELSE 0 
    END AS cost_per_acquisition,
    CASE 
        WHEN c.cost > 0 THEN ROUND((SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) / c.cost - 1) * 100, 2)
        ELSE NULL 
    END AS roi_percentage
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, c.cost;


-- ============================================
-- VIEW 3: User Dimension Table
-- ============================================

SELECT 
    u.user_id,
    u.signup_date,
    u.device,
    u.country,
    c.campaign_name AS acquisition_campaign,
    c.channel AS acquisition_channel,
    COUNT(DISTINCT e.event_id) AS total_events,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.event_id END) AS total_visits,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.event_id END) AS total_carts,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.event_id END) AS total_purchases,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS lifetime_value,
    MIN(e.event_date) AS first_activity_date,
    MAX(e.event_date) AS last_activity_date,
    DATEDIFF(DAY, u.signup_date, MAX(e.event_date)) AS customer_lifespan_days,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.event_id END) = 0 THEN 'Never Purchased'
        WHEN COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.event_id END) = 1 THEN 'One-time Buyer'
        ELSE 'Repeat Buyer'
    END AS customer_segment
FROM users u
LEFT JOIN campaigns c ON u.acquisition_source = c.campaign_id
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY u.user_id, u.signup_date, u.device, u.country, c.campaign_name, c.channel;


-- ============================================
-- VIEW 4: Funnel Metrics by Dimension
-- ============================================

-- By Device
SELECT 
    'Device' AS dimension_type,
    u.device AS dimension_value,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS stage_1_visit,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS stage_3_purchase,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS conversion_visit_to_cart,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END), 0), 2) AS conversion_cart_to_purchase
FROM events e
JOIN users u ON e.user_id = u.user_id
GROUP BY u.device

UNION ALL

-- By Country
SELECT 
    'Country' AS dimension_type,
    u.country AS dimension_value,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS stage_1_visit,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS stage_3_purchase,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS conversion_visit_to_cart,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END), 0), 2) AS conversion_cart_to_purchase
FROM events e
JOIN users u ON e.user_id = u.user_id
GROUP BY u.country

UNION ALL

-- By Channel
SELECT 
    'Channel' AS dimension_type,
    c.channel AS dimension_value,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS stage_1_visit,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS stage_3_purchase,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS conversion_visit_to_cart,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END), 0), 2) AS conversion_cart_to_purchase
FROM events e
JOIN campaigns c ON e.campaign_id = c.campaign_id
GROUP BY c.channel;


-- ============================================
-- VIEW 5: Cohort Retention for Power BI
-- ============================================

WITH user_cohorts AS (
    SELECT 
        user_id,
        FORMAT(signup_date, 'yyyy-MM') AS cohort_month,
        DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1) AS cohort_date
    FROM users
),
user_monthly_activity AS (
    SELECT DISTINCT
        e.user_id,
        DATEFROMPARTS(YEAR(e.event_date), MONTH(e.event_date), 1) AS activity_month
    FROM events e
    WHERE e.event_name IN ('visit', 'add_to_cart', 'purchase')
)
SELECT 
    uc.cohort_month,
    DATEDIFF(MONTH, uc.cohort_date, uma.activity_month) AS months_since_signup,
    COUNT(DISTINCT uc.user_id) AS active_users
FROM user_cohorts uc
LEFT JOIN user_monthly_activity uma ON uc.user_id = uma.user_id
GROUP BY uc.cohort_month, DATEDIFF(MONTH, uc.cohort_date, uma.activity_month)
HAVING DATEDIFF(MONTH, uc.cohort_date, uma.activity_month) >= 0
ORDER BY uc.cohort_month, months_since_signup;


-- ============================================
-- VIEW 6: KPI Summary (for Dashboard Cards)
-- ============================================

SELECT 
    'Total Users' AS kpi_name,
    COUNT(DISTINCT user_id) AS kpi_value,
    NULL AS kpi_percentage
FROM users

UNION ALL

SELECT 
    'Total Revenue' AS kpi_name,
    ROUND(SUM(revenue), 2) AS kpi_value,
    NULL AS kpi_percentage
FROM events
WHERE event_name = 'purchase'

UNION ALL

SELECT 
    'Overall Conversion Rate' AS kpi_name,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'visit' THEN user_id END), 0), 2) AS kpi_value,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'visit' THEN user_id END), 0), 2) AS kpi_percentage
FROM events

UNION ALL

SELECT 
    'Average Order Value' AS kpi_name,
    ROUND(AVG(revenue), 2) AS kpi_value,
    NULL AS kpi_percentage
FROM events
WHERE event_name = 'purchase'

UNION ALL

SELECT 
    'Total Marketing Cost' AS kpi_name,
    SUM(cost) AS kpi_value,
    NULL AS kpi_percentage
FROM campaigns

UNION ALL

SELECT 
    'Marketing ROI' AS kpi_name,
    ROUND((SUM(e.revenue) / NULLIF(SUM(c.cost), 0) - 1) * 100, 2) AS kpi_value,
    ROUND((SUM(e.revenue) / NULLIF(SUM(c.cost), 0) - 1) * 100, 2) AS kpi_percentage
FROM events e
CROSS JOIN (SELECT SUM(cost) AS cost FROM campaigns) c
WHERE e.event_name = 'purchase'

UNION ALL

SELECT 
    'Repeat Purchase Rate' AS kpi_name,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN purchase_count > 1 THEN user_id END) / 
          NULLIF(COUNT(DISTINCT user_id), 0), 2) AS kpi_value,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN purchase_count > 1 THEN user_id END) / 
          NULLIF(COUNT(DISTINCT user_id), 0), 2) AS kpi_percentage
FROM (
    SELECT user_id, COUNT(*) AS purchase_count
    FROM events
    WHERE event_name = 'purchase'
    GROUP BY user_id
) purchase_counts;
