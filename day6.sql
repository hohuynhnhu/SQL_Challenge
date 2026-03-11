-- ============================================================
-- CLIQUE BAIT - T-SQL VERSION (SQL Server)
-- Converted from PostgreSQL
-- ============================================================

-- ============================================================
-- 2. DIGITAL ANALYSIS
-- ============================================================

-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users;

-- 2. How many cookies does each user have on average?
SELECT 
    ROUND(AVG(CAST(cookie_count AS FLOAT)), 2) AS avg_cookies_per_user
FROM (
    SELECT 
        user_id,
        COUNT(cookie_id) AS cookie_count
    FROM clique_bait.users
    GROUP BY user_id
) AS user_cookies;

-- 3. What is the unique number of visits by all users per month?
SELECT 
    MONTH(event_time)                        AS month_number,
    DATENAME(MONTH, event_time)              AS month_name,
    COUNT(DISTINCT visit_id)                 AS unique_visits
FROM clique_bait.events
GROUP BY 
    MONTH(event_time),
    DATENAME(MONTH, event_time)
ORDER BY month_number;

-- 4. What is the number of events for each event type?
SELECT 
    e.event_type,
    ei.event_name,
    COUNT(*)                                 AS number_of_events
FROM clique_bait.events e
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
GROUP BY e.event_type, ei.event_name
ORDER BY e.event_type;

-- 5. What is the percentage of visits which have a purchase event?
SELECT 
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN ei.event_name = 'Purchase' THEN e.visit_id END) 
        / COUNT(DISTINCT e.visit_id),
        2
    ) AS purchase_percentage
FROM clique_bait.events e
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
SELECT 
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
                        WHEN ph.page_name = 'Checkout' 
                        AND e.visit_id NOT IN (
                            SELECT DISTINCT visit_id 
                            FROM clique_bait.events e2
                            JOIN clique_bait.event_identifier ei2 
                                ON e2.event_type = ei2.event_type
                            WHERE ei2.event_name = 'Purchase'
                        ) 
                        THEN e.visit_id 
                      END) 
        / COUNT(DISTINCT e.visit_id),
        2
    ) AS checkout_no_purchase_pct
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type;

-- 7. What are the top 3 pages by number of views?
SELECT TOP 3
    ph.page_name,
    COUNT(*)                                 AS number_of_views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ei.event_name = 'Page View'
GROUP BY ph.page_name
ORDER BY number_of_views DESC;

-- 8. What is the number of views and cart adds for each product category?
SELECT 
    ph.product_category,
    SUM(CASE WHEN ei.event_name = 'Page View'   THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY page_views DESC;

-- 9. What are the top 3 products by purchases?
SELECT TOP 3
    ph.page_name                             AS product_name,
    COUNT(*)                                 AS total_purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ei.event_name = 'Add to Cart'
AND e.visit_id IN (
    SELECT DISTINCT visit_id
    FROM clique_bait.events e2
    JOIN clique_bait.event_identifier ei2
        ON e2.event_type = ei2.event_type
    WHERE ei2.event_name = 'Purchase'
)
AND ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY total_purchases DESC;


-- ============================================================
-- 3. PRODUCT FUNNEL ANALYSIS
-- ============================================================

-- How many times was each product viewed?
SELECT 
    ph.page_name                             AS product_name,
    COUNT(*)                                 AS total_views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ei.event_name = 'Page View'
AND ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY total_views DESC;

-- How many times was each product added to cart?
SELECT 
    ph.page_name                             AS product_name,
    COUNT(*)                                 AS total_cart_adds
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ei.event_name = 'Add to Cart'
AND ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY total_cart_adds DESC;

-- How many times was each product added to cart but not purchased (abandoned)?
SELECT 
    ph.page_name                             AS product_name,
    COUNT(*)                                 AS total_abandoned
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ei.event_name = 'Add to Cart'
AND ph.product_id IS NOT NULL
AND e.visit_id NOT IN (
    SELECT DISTINCT visit_id
    FROM clique_bait.events e2
    JOIN clique_bait.event_identifier ei2
        ON e2.event_type = ei2.event_type
    WHERE ei2.event_name = 'Purchase'
)
GROUP BY ph.page_name
ORDER BY total_abandoned DESC;

-- How many times was each product purchased?
SELECT 
    ph.page_name                             AS product_name,
    COUNT(*)                                 AS total_purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ei.event_name = 'Add to Cart'
AND ph.product_id IS NOT NULL
AND e.visit_id IN (
    SELECT DISTINCT visit_id
    FROM clique_bait.events e2
    JOIN clique_bait.event_identifier ei2
        ON e2.event_type = ei2.event_type
    WHERE ei2.event_name = 'Purchase'
)
GROUP BY ph.page_name
ORDER BY total_purchases DESC;


-- ============================================================
-- PRODUCT & CATEGORY SUMMARY TABLES
-- ============================================================

-- Table 1: Product level summary
DROP TABLE IF EXISTS #product_summary;
SELECT 
    ph.page_name                                                AS product_name,
    ph.product_category,
    SUM(CASE WHEN ei.event_name = 'Page View'   THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' 
             AND e.visit_id IN (
                SELECT DISTINCT visit_id 
                FROM clique_bait.events e2
                JOIN clique_bait.event_identifier ei2
                    ON e2.event_type = ei2.event_type
                WHERE ei2.event_name = 'Purchase'
             ) THEN 1 ELSE 0 END)                               AS purchases,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' 
             AND e.visit_id NOT IN (
                SELECT DISTINCT visit_id 
                FROM clique_bait.events e2
                JOIN clique_bait.event_identifier ei2
                    ON e2.event_type = ei2.event_type
                WHERE ei2.event_name = 'Purchase'
             ) THEN 1 ELSE 0 END)                               AS abandoned
INTO #product_summary
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name, ph.product_category;

-- Table 2: Category level summary
DROP TABLE IF EXISTS #category_summary;
SELECT 
    product_category,
    SUM(views)      AS views,
    SUM(cart_adds)  AS cart_adds,
    SUM(purchases)  AS purchases,
    SUM(abandoned)  AS abandoned
INTO #category_summary
FROM #product_summary
GROUP BY product_category;

-- Which product had the most views, cart adds and purchases?
SELECT 'Most Views' AS metric, product_name, views AS value
FROM (
    SELECT TOP 1 product_name, views 
    FROM #product_summary 
    ORDER BY views DESC 
) t1
UNION ALL
SELECT 'Most Cart Adds', product_name, cart_adds
FROM (
    SELECT TOP 1 product_name, cart_adds 
    FROM #product_summary 
    ORDER BY cart_adds DESC 
) t2
UNION ALL
SELECT 'Most Purchases', product_name, purchases
FROM (
    SELECT TOP 1 product_name, purchases 
    FROM #product_summary 
    ORDER BY purchases DESC 
) t3;

-- Which product was most likely to be abandoned?
SELECT TOP 1
    product_name,
    views,
    cart_adds,
    abandoned,
    ROUND(100.0 * abandoned / cart_adds, 2) AS abandon_rate
FROM #product_summary
ORDER BY abandon_rate DESC;

-- Which product had the highest view to purchase percentage?
SELECT TOP 1
    product_name,
    views,
    purchases,
    ROUND(100.0 * purchases / views, 2) AS view_to_purchase_pct
FROM #product_summary
ORDER BY view_to_purchase_pct DESC;

-- What is the average conversion rate from view to cart add?
SELECT 
    ROUND(AVG(100.0 * cart_adds / views), 2) AS avg_view_to_cart_rate
FROM #product_summary;

-- What is the average conversion rate from cart add to purchase?
SELECT 
    ROUND(AVG(100.0 * purchases / cart_adds), 2) AS avg_cart_to_purchase_rate
FROM #product_summary;


-- ============================================================
-- 4. CAMPAIGNS ANALYSIS
-- ============================================================

-- Generate campaign summary table
DROP TABLE IF EXISTS #campaign_summary;
SELECT 
    u.user_id,
    e.visit_id,
    v.visit_start_time,
    SUM(CASE WHEN ei.event_name = 'Page View'      THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN ei.event_name = 'Add to Cart'    THEN 1 ELSE 0 END) AS cart_adds,
    MAX(CASE WHEN ei.event_name = 'Purchase'       THEN 1 ELSE 0 END) AS purchase,
    c.campaign_name,
    SUM(CASE WHEN ei.event_name = 'Ad Impression'  THEN 1 ELSE 0 END) AS impression,
    SUM(CASE WHEN ei.event_name = 'Ad Click'       THEN 1 ELSE 0 END) AS click,
    -- STRING_AGG with ORDER BY requires SQL Server 2017+
    STRING_AGG(
        CASE WHEN ei.event_name = 'Add to Cart' THEN ph.page_name END, 
        ', '
    ) WITHIN GROUP (ORDER BY e.sequence_number)                        AS cart_products
INTO #campaign_summary
FROM clique_bait.events e
JOIN (
    SELECT visit_id, MIN(event_time) AS visit_start_time
    FROM clique_bait.events
    GROUP BY visit_id
) v ON e.visit_id = v.visit_id
JOIN clique_bait.users u 
    ON e.cookie_id = u.cookie_id
JOIN clique_bait.event_identifier ei 
    ON e.event_type = ei.event_type
JOIN clique_bait.page_hierarchy ph 
    ON e.page_id = ph.page_id
LEFT JOIN clique_bait.campaign_identifier c
    ON v.visit_start_time BETWEEN c.start_date AND c.end_date
GROUP BY u.user_id, e.visit_id, v.visit_start_time, c.campaign_name
ORDER BY u.user_id, v.visit_start_time;

-- Does clicking on an impression lead to higher purchase rates?
SELECT 
    CASE 
        WHEN impression = 0 THEN '1. No Impression'
        WHEN impression > 0 AND click = 0 THEN '2. Had Impression, No Click'
        WHEN impression > 0 AND click > 0 THEN '3. Had Impression & Clicked'
    END                                                      AS group_name,
    COUNT(*)                                                 AS total_visits,
    SUM(purchase)                                            AS total_purchases,
    ROUND(100.0 * SUM(purchase) / COUNT(*), 2)              AS purchase_rate,
    ROUND(AVG(CAST(cart_adds AS FLOAT)), 2)                  AS avg_cart_adds,
    ROUND(AVG(CAST(page_views AS FLOAT)), 2)                 AS avg_page_views
FROM #campaign_summary
GROUP BY 
    CASE 
        WHEN impression = 0 THEN '1. No Impression'
        WHEN impression > 0 AND click = 0 THEN '2. Had Impression, No Click'
        WHEN impression > 0 AND click > 0 THEN '3. Had Impression & Clicked'
    END
ORDER BY group_name;

-- Uplift Analysis
WITH purchase_rates AS (
    SELECT
        ROUND(100.0 * SUM(CASE WHEN impression = 0 THEN purchase END) /
              NULLIF(COUNT(CASE WHEN impression = 0 THEN 1 END), 0), 2) AS no_impression_rate,
        ROUND(100.0 * SUM(CASE WHEN impression > 0 AND click = 0 THEN purchase END) /
              NULLIF(COUNT(CASE WHEN impression > 0 AND click = 0 THEN 1 END), 0), 2) AS impression_no_click_rate,
        ROUND(100.0 * SUM(CASE WHEN impression > 0 AND click > 0 THEN purchase END) /
              NULLIF(COUNT(CASE WHEN impression > 0 AND click > 0 THEN 1 END), 0), 2) AS impression_and_click_rate
    FROM #campaign_summary
)
SELECT
    no_impression_rate,
    impression_no_click_rate,
    impression_and_click_rate,
    ROUND(impression_and_click_rate - no_impression_rate, 2)          AS uplift_click_vs_no_impression,
    ROUND(impression_and_click_rate - impression_no_click_rate, 2)    AS uplift_click_vs_no_click,
    ROUND(impression_no_click_rate - no_impression_rate, 2)           AS uplift_impression_vs_no_impression
FROM purchase_rates;

-- Campaign Performance Comparison
SELECT
    COALESCE(campaign_name, 'No Campaign')                             AS campaign,
    COUNT(*)                                                           AS total_visits,
    SUM(impression)                                                    AS total_impressions,
    SUM(click)                                                         AS total_clicks,
    SUM(purchase)                                                      AS total_purchases,
    ROUND(AVG(CAST(page_views AS FLOAT)), 2)                           AS avg_page_views,
    ROUND(AVG(CAST(cart_adds  AS FLOAT)), 2)                           AS avg_cart_adds,
    ROUND(100.0 * SUM(click) /
          NULLIF(SUM(impression), 0), 2)                               AS ctr,
    ROUND(100.0 * SUM(purchase) /
          NULLIF(COUNT(*), 0), 2)                                      AS purchase_rate,
    ROUND(100.0 * SUM(CASE WHEN cart_adds > 0 THEN 1 END) /
          NULLIF(COUNT(*), 0), 2)                                      AS cart_add_rate,
    ROUND(100.0 * SUM(purchase) /
          NULLIF(SUM(CASE WHEN cart_adds > 0 THEN 1 END), 0), 2)      AS cart_to_purchase_rate
FROM #campaign_summary
GROUP BY campaign_name
ORDER BY purchase_rate DESC;