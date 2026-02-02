-- ============================================
-- FUNNEL ANALYSIS QUERIES
-- Product Analytics Project
-- ============================================

-- This file contains SQL queries to analyze user funnel behavior
-- Funnel stages: Visit → Add to Cart → Purchase

-- ============================================
-- 1. OVERALL FUNNEL METRICS
-- ============================================

-- Count users at each funnel stage
SELECT 
    'Visit' AS funnel_stage,
    COUNT(DISTINCT user_id) AS users,
    1 AS stage_order
FROM events
WHERE event_name = 'visit'

UNION ALL

SELECT 
    'Add to Cart' AS funnel_stage,
    COUNT(DISTINCT user_id) AS users,
    2 AS stage_order
FROM events
WHERE event_name = 'add_to_cart'

UNION ALL

SELECT 
    'Purchase' AS funnel_stage,
    COUNT(DISTINCT user_id) AS users,
    3 AS stage_order
FROM events
WHERE event_name = 'purchase'

ORDER BY stage_order;


-- ============================================
-- 2. FUNNEL WITH CONVERSION RATES
-- ============================================

WITH funnel_stages AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_name = 'visit' THEN user_id END) AS visit_users,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) AS purchase_users
    FROM events
)
SELECT 
    'Visit' AS stage,
    visit_users AS users,
    100.0 AS conversion_from_previous,
    ROUND(100.0 * visit_users / visit_users, 2) AS conversion_from_start
FROM funnel_stages

UNION ALL

SELECT 
    'Add to Cart' AS stage,
    cart_users AS users,
    ROUND(100.0 * cart_users / visit_users, 2) AS conversion_from_previous,
    ROUND(100.0 * cart_users / visit_users, 2) AS conversion_from_start
FROM funnel_stages

UNION ALL

SELECT 
    'Purchase' AS stage,
    purchase_users AS users,
    ROUND(100.0 * purchase_users / cart_users, 2) AS conversion_from_previous,
    ROUND(100.0 * purchase_users / visit_users, 2) AS conversion_from_start
FROM funnel_stages;


-- ============================================
-- 3. DROP-OFF ANALYSIS
-- ============================================

WITH funnel_stages AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_name = 'visit' THEN user_id END) AS visit_users,
        COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) AS purchase_users
    FROM events
)
SELECT 
    'Visit → Add to Cart' AS drop_off_point,
    visit_users - cart_users AS users_dropped,
    ROUND(100.0 * (visit_users - cart_users) / visit_users, 2) AS drop_off_percentage
FROM funnel_stages

UNION ALL

SELECT 
    'Add to Cart → Purchase' AS drop_off_point,
    cart_users - purchase_users AS users_dropped,
    ROUND(100.0 * (cart_users - purchase_users) / cart_users, 2) AS drop_off_percentage
FROM funnel_stages;


-- ============================================
-- 4. FUNNEL BY DEVICE TYPE
-- ============================================

SELECT 
    u.device,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS visit_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchase_users,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS visit_to_cart_rate,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END), 0), 2) AS cart_to_purchase_rate,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS overall_conversion_rate
FROM events e
JOIN users u ON e.user_id = u.user_id
GROUP BY u.device
ORDER BY purchase_users DESC;


-- ============================================
-- 5. FUNNEL BY CAMPAIGN
-- ============================================

SELECT 
    c.campaign_name,
    c.channel,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS visit_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchase_users,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS visit_to_cart_rate,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END), 0), 2) AS cart_to_purchase_rate,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS overall_conversion_rate
FROM events e
JOIN campaigns c ON e.campaign_id = c.campaign_id
GROUP BY c.campaign_name, c.channel
ORDER BY purchase_users DESC;


-- ============================================
-- 6. FUNNEL BY COUNTRY
-- ============================================

SELECT 
    u.country,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS visit_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchase_users,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS overall_conversion_rate
FROM events e
JOIN users u ON e.user_id = u.user_id
GROUP BY u.country
ORDER BY purchase_users DESC;


-- ============================================
-- 7. TIME-BASED FUNNEL TRENDS (Monthly)
-- ============================================

SELECT 
    FORMAT(e.event_date, 'yyyy-MM') AS month,
    COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END) AS visit_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'add_to_cart' THEN e.user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchase_users,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'visit' THEN e.user_id END), 0), 2) AS conversion_rate
FROM events e
GROUP BY FORMAT(e.event_date, 'yyyy-MM')
ORDER BY month;


-- ============================================
-- 8. USER-LEVEL FUNNEL COMPLETION
-- ============================================

-- Identify which users completed which stages
SELECT 
    u.user_id,
    u.signup_date,
    u.device,
    u.country,
    c.campaign_name,
    MAX(CASE WHEN e.event_name = 'visit' THEN 1 ELSE 0 END) AS reached_visit,
    MAX(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_cart,
    MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) AS reached_purchase,
    CASE 
        WHEN MAX(CASE WHEN e.event_name = 'purchase' THEN 1 ELSE 0 END) = 1 THEN 'Converted'
        WHEN MAX(CASE WHEN e.event_name = 'add_to_cart' THEN 1 ELSE 0 END) = 1 THEN 'Abandoned Cart'
        WHEN MAX(CASE WHEN e.event_name = 'visit' THEN 1 ELSE 0 END) = 1 THEN 'Browsed Only'
        ELSE 'No Activity'
    END AS funnel_status
FROM users u
LEFT JOIN events e ON u.user_id = e.user_id
LEFT JOIN campaigns c ON u.acquisition_source = c.campaign_id
GROUP BY u.user_id, u.signup_date, u.device, u.country, c.campaign_name;


-- ============================================
-- 9. AVERAGE TIME BETWEEN FUNNEL STAGES
-- ============================================

WITH user_events AS (
    SELECT 
        user_id,
        MIN(CASE WHEN event_name = 'visit' THEN event_date END) AS first_visit,
        MIN(CASE WHEN event_name = 'add_to_cart' THEN event_date END) AS first_cart,
        MIN(CASE WHEN event_name = 'purchase' THEN event_date END) AS first_purchase
    FROM events
    GROUP BY user_id
)
SELECT 
    AVG(DATEDIFF(MINUTE, first_visit, first_cart)) AS avg_minutes_visit_to_cart,
    AVG(DATEDIFF(MINUTE, first_cart, first_purchase)) AS avg_minutes_cart_to_purchase,
    AVG(DATEDIFF(MINUTE, first_visit, first_purchase)) AS avg_minutes_visit_to_purchase
FROM user_events
WHERE first_cart IS NOT NULL AND first_purchase IS NOT NULL;
