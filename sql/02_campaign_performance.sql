-- ============================================
-- CAMPAIGN PERFORMANCE ANALYSIS QUERIES
-- Product Analytics Project
-- ============================================

-- This file contains SQL queries to analyze marketing campaign effectiveness
-- Metrics: Users, Conversions, Revenue, Cost, ROI

-- ============================================
-- 1. CAMPAIGN OVERVIEW
-- ============================================

SELECT 
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.cost AS campaign_cost,
    COUNT(DISTINCT u.user_id) AS total_users_acquired,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
    COUNT(CASE WHEN e.event_name = 'purchase' THEN 1 END) AS total_purchases,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS conversion_rate,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS total_revenue
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, c.cost
ORDER BY total_revenue DESC;


-- ============================================
-- 2. CAMPAIGN ROI ANALYSIS
-- ============================================

WITH campaign_metrics AS (
    SELECT 
        c.campaign_id,
        c.campaign_name,
        c.channel,
        c.cost,
        COUNT(DISTINCT u.user_id) AS users_acquired,
        COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
        SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) AS revenue
    FROM campaigns c
    LEFT JOIN users u ON c.campaign_id = u.acquisition_source
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY c.campaign_id, c.campaign_name, c.channel, c.cost
)
SELECT 
    campaign_name,
    channel,
    cost,
    users_acquired,
    purchasers,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue - cost, 2) AS profit,
    CASE 
        WHEN cost > 0 THEN ROUND(cost / NULLIF(users_acquired, 0), 2)
        ELSE 0 
    END AS cost_per_acquisition,
    CASE 
        WHEN cost > 0 THEN ROUND(cost / NULLIF(purchasers, 0), 2)
        ELSE 0 
    END AS cost_per_purchaser,
    CASE 
        WHEN cost > 0 THEN ROUND((revenue / NULLIF(cost, 0) - 1) * 100, 2)
        ELSE NULL 
    END AS roi_percentage,
    CASE 
        WHEN cost > 0 THEN ROUND(revenue / NULLIF(cost, 0), 2)
        ELSE NULL 
    END AS roas
FROM campaign_metrics
ORDER BY roi_percentage DESC;


-- ============================================
-- 3. CAMPAIGN EFFICIENCY RANKING
-- ============================================

WITH campaign_metrics AS (
    SELECT 
        c.campaign_name,
        c.channel,
        COUNT(DISTINCT u.user_id) AS users,
        COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
              NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS conversion_rate,
        SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) AS revenue,
        c.cost
    FROM campaigns c
    LEFT JOIN users u ON c.campaign_id = u.acquisition_source
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY c.campaign_name, c.channel, c.cost
)
SELECT 
    campaign_name,
    channel,
    users,
    purchasers,
    conversion_rate,
    ROUND(revenue, 2) AS revenue,
    cost,
    CASE 
        WHEN cost > 0 THEN ROUND((revenue / cost - 1) * 100, 2)
        ELSE NULL 
    END AS roi_percentage,
    CASE 
        WHEN conversion_rate >= 30 AND roi_percentage >= 100 THEN 'Excellent'
        WHEN conversion_rate >= 20 AND roi_percentage >= 50 THEN 'Good'
        WHEN conversion_rate >= 10 OR roi_percentage >= 0 THEN 'Fair'
        ELSE 'Poor'
    END AS performance_rating
FROM campaign_metrics
ORDER BY roi_percentage DESC;


-- ============================================
-- 4. CHANNEL COMPARISON
-- ============================================

SELECT 
    c.channel,
    COUNT(DISTINCT c.campaign_id) AS num_campaigns,
    SUM(c.cost) AS total_cost,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS total_purchasers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS conversion_rate,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS total_revenue,
    CASE 
        WHEN SUM(c.cost) > 0 THEN ROUND((SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) / SUM(c.cost) - 1) * 100, 2)
        ELSE NULL 
    END AS roi_percentage
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY c.channel
ORDER BY total_revenue DESC;


-- ============================================
-- 5. CAMPAIGN PERFORMANCE OVER TIME
-- ============================================

SELECT 
    FORMAT(u.signup_date, 'yyyy-MM') AS signup_month,
    c.campaign_name,
    COUNT(DISTINCT u.user_id) AS users_acquired,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS revenue
FROM users u
JOIN campaigns c ON u.acquisition_source = c.campaign_id
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY FORMAT(u.signup_date, 'yyyy-MM'), c.campaign_name
ORDER BY signup_month, revenue DESC;


-- ============================================
-- 6. TOP PERFORMING CAMPAIGNS BY METRIC
-- ============================================

-- Top by User Acquisition
SELECT TOP 3
    'User Acquisition' AS metric,
    c.campaign_name,
    COUNT(DISTINCT u.user_id) AS value
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
GROUP BY c.campaign_name
ORDER BY value DESC;

-- Top by Conversion Rate
WITH campaign_conversion AS (
    SELECT 
        c.campaign_name,
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
              NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS conversion_rate
    FROM campaigns c
    LEFT JOIN users u ON c.campaign_id = u.acquisition_source
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY c.campaign_name
)
SELECT TOP 3
    'Conversion Rate' AS metric,
    campaign_name,
    conversion_rate AS value
FROM campaign_conversion
ORDER BY conversion_rate DESC;

-- Top by Revenue
SELECT TOP 3
    'Revenue' AS metric,
    c.campaign_name,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS value
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY c.campaign_name
ORDER BY value DESC;


-- ============================================
-- 7. CAMPAIGN BUDGET ALLOCATION ANALYSIS
-- ============================================

WITH campaign_performance AS (
    SELECT 
        c.campaign_name,
        c.cost,
        SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) AS revenue,
        COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers
    FROM campaigns c
    LEFT JOIN users u ON c.campaign_id = u.acquisition_source
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY c.campaign_name, c.cost
)
SELECT 
    campaign_name,
    cost,
    ROUND(revenue, 2) AS revenue,
    ROUND(100.0 * cost / SUM(cost) OVER (), 2) AS budget_percentage,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS revenue_percentage,
    CASE 
        WHEN cost > 0 THEN ROUND((revenue / cost - 1) * 100, 2)
        ELSE NULL 
    END AS roi_percentage,
    CASE 
        WHEN (100.0 * revenue / SUM(revenue) OVER ()) > (100.0 * cost / SUM(cost) OVER ()) THEN 'Underinvested'
        WHEN (100.0 * revenue / SUM(revenue) OVER ()) < (100.0 * cost / SUM(cost) OVER ()) THEN 'Overinvested'
        ELSE 'Balanced'
    END AS investment_status
FROM campaign_performance
WHERE cost > 0
ORDER BY roi_percentage DESC;


-- ============================================
-- 8. PAID VS ORGANIC PERFORMANCE
-- ============================================

SELECT 
    CASE 
        WHEN c.cost > 0 THEN 'Paid'
        ELSE 'Organic'
    END AS campaign_type,
    COUNT(DISTINCT c.campaign_id) AS num_campaigns,
    SUM(c.cost) AS total_cost,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS total_purchasers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) / 
          NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS conversion_rate,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS total_revenue
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY CASE WHEN c.cost > 0 THEN 'Paid' ELSE 'Organic' END;


-- ============================================
-- 9. CUSTOMER LIFETIME VALUE BY CAMPAIGN
-- ============================================

SELECT 
    c.campaign_name,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END) AS purchasers,
    COUNT(CASE WHEN e.event_name = 'purchase' THEN 1 END) AS total_purchases,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END), 2) AS total_revenue,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT u.user_id), 0), 2) AS revenue_per_user,
    ROUND(SUM(CASE WHEN e.event_name = 'purchase' THEN e.revenue ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END), 0), 2) AS revenue_per_purchaser,
    ROUND(CAST(COUNT(CASE WHEN e.event_name = 'purchase' THEN 1 END) AS FLOAT) / 
          NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'purchase' THEN e.user_id END), 0), 2) AS avg_purchases_per_purchaser
FROM campaigns c
LEFT JOIN users u ON c.campaign_id = u.acquisition_source
LEFT JOIN events e ON u.user_id = e.user_id
GROUP BY c.campaign_name
ORDER BY revenue_per_user DESC;
