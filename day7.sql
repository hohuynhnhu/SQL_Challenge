-- ============================================================
-- BALANCED TREE - T-SQL VERSION (SQL Server)
-- Converted from PostgreSQL
-- ============================================================


-- ============================================================
-- HIGH LEVEL SALES ANALYSIS
-- ============================================================

-- 1. Total quantity sold
SELECT 
    SUM(qty) AS total_quantity_sold
FROM balanced_tree.sales;

-- 2. Total revenue before discounts
SELECT 
    SUM(qty * price) AS total_revenue_before_discount
FROM balanced_tree.sales;

-- 3. Total discount amount
SELECT 
    ROUND(SUM(qty * price * discount / 100.0), 2) AS total_discount_amount
FROM balanced_tree.sales;


-- ============================================================
-- TRANSACTION ANALYSIS
-- ============================================================

-- 1. Unique transactions
SELECT 
    COUNT(DISTINCT txn_id) AS unique_transactions
FROM balanced_tree.sales;

-- 2. Average unique products per transaction
WITH txn_products AS (
    SELECT 
        txn_id,
        COUNT(DISTINCT prod_id) AS unique_products
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT 
    ROUND(AVG(CAST(unique_products AS FLOAT)), 2) AS avg_unique_products
FROM txn_products;

-- 3. 25th, 50th, 75th percentile for revenue per transaction
WITH txn_revenue AS (
    SELECT 
        txn_id,
        SUM(qty * price) AS revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) AS percentile_25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue) AS percentile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) AS percentile_75
FROM txn_revenue;

-- 4. Average discount per transaction
WITH txn_discount AS (
    SELECT 
        txn_id,
        SUM(qty * price * discount / 100.0) AS total_discount
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT 
    ROUND(AVG(CAST(total_discount AS FLOAT)), 2) AS avg_discount_per_txn
FROM txn_discount;

-- 5. Percentage split of transactions for members vs non-members
WITH member_txns AS (
    SELECT 
        member,
        COUNT(DISTINCT txn_id) AS total_transactions
    FROM balanced_tree.sales
    GROUP BY member
)
SELECT 
    CASE WHEN member = 1 THEN 'Member' ELSE 'Non-Member' END AS member_status,
    total_transactions,
    ROUND(
        100.0 * total_transactions / SUM(total_transactions) OVER (),
        2
    ) AS transaction_pct
FROM member_txns
ORDER BY member_status;

-- 6. Average revenue for member vs non-member transactions
WITH txn_revenue AS (
    SELECT 
        txn_id,
        member,
        SUM(qty * price * (1 - discount / 100.0)) AS revenue_after_discount
    FROM balanced_tree.sales
    GROUP BY txn_id, member
)
SELECT 
    CASE WHEN member = 1 THEN 'Member' ELSE 'Non-Member' END AS member_status,
    ROUND(AVG(CAST(revenue_after_discount AS FLOAT)), 2)      AS avg_revenue
FROM txn_revenue
GROUP BY member
ORDER BY member_status;


-- ============================================================
-- PRODUCT ANALYSIS
-- ============================================================

-- 1. Top 3 products by total revenue before discount
SELECT TOP 3
    pd.product_name,
    SUM(s.qty * s.price) AS revenue_before_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY revenue_before_discount DESC;

-- 2. Total revenue before discounts
SELECT 
    SUM(qty * price) AS revenue_before_discount
FROM balanced_tree.sales;

-- 3. Top selling product for each segment
WITH ranked_products AS (
    SELECT 
        pd.segment_name,
        pd.product_name,
        SUM(s.qty) AS total_quantity,
        RANK() OVER (
            PARTITION BY pd.segment_name
            ORDER BY SUM(s.qty) DESC
        ) AS rnk
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT 
    segment_name,
    product_name,
    total_quantity
FROM ranked_products
WHERE rnk = 1
ORDER BY segment_name;

-- 4. Total quantity, revenue and discount for each category
SELECT 
    pd.category_name,
    SUM(s.qty)                                               AS total_quantity,
    SUM(s.qty * s.price)                                     AS revenue_before_discount,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2)     AS total_discount,
    ROUND(SUM(s.qty * s.price * (1 - s.discount / 100.0)), 2) AS revenue_after_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- 5. Top selling product for each category
WITH ranked_products AS (
    SELECT 
        pd.category_name,
        pd.product_name,
        SUM(s.qty)                                           AS total_quantity,
        SUM(s.qty * s.price)                                 AS revenue_before_discount,
        ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS total_discount,
        RANK() OVER (
            PARTITION BY pd.category_name
            ORDER BY SUM(s.qty) DESC
        ) AS rnk
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.product_name
)
SELECT 
    category_name,
    product_name,
    total_quantity,
    revenue_before_discount,
    total_discount
FROM ranked_products
WHERE rnk = 1
ORDER BY category_name;

-- 6. Percentage split of revenue by product for each segment
WITH product_revenue AS (
    SELECT 
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT 
    segment_name,
    product_name,
    revenue,
    ROUND(
        100.0 * revenue / SUM(revenue) OVER (PARTITION BY segment_name),
        2
    ) AS revenue_pct
FROM product_revenue
ORDER BY segment_name, revenue_pct DESC;

-- 7. Percentage split of revenue by segment for each category
WITH segment_revenue AS (
    SELECT 
        pd.category_name,
        pd.segment_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.segment_name
)
SELECT 
    category_name,
    segment_name,
    revenue,
    ROUND(
        100.0 * revenue / SUM(revenue) OVER (PARTITION BY category_name),
        2
    ) AS revenue_pct
FROM segment_revenue
ORDER BY category_name, revenue_pct DESC;

-- 8. Percentage split of total revenue by category
WITH category_revenue AS (
    SELECT 
        pd.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name
)
SELECT 
    category_name,
    revenue,
    ROUND(
        100.0 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_pct
FROM category_revenue
ORDER BY revenue_pct DESC;

-- 9. Transaction penetration for each product
WITH total_txns AS (
    SELECT COUNT(DISTINCT txn_id) AS total_transactions
    FROM balanced_tree.sales
)
SELECT 
    pd.product_name,
    COUNT(DISTINCT s.txn_id)                                    AS product_transactions,
    (SELECT total_transactions FROM total_txns)                 AS total_transactions,
    ROUND(
        100.0 * COUNT(DISTINCT s.txn_id) /
        (SELECT total_transactions FROM total_txns),
        2
    )                                                           AS penetration_pct
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY penetration_pct DESC;

-- 10. Most common combination of any 3 products in a single transaction
WITH product_combos AS (
    SELECT
        s1.txn_id,
        p1.product_name AS product_1,
        p2.product_name AS product_2,
        p3.product_name AS product_3
    FROM balanced_tree.sales s1
    JOIN balanced_tree.sales s2
        ON s1.txn_id = s2.txn_id
        AND s1.prod_id < s2.prod_id
    JOIN balanced_tree.sales s3
        ON s1.txn_id = s3.txn_id
        AND s2.prod_id < s3.prod_id
    JOIN balanced_tree.product_details p1 ON s1.prod_id = p1.product_id
    JOIN balanced_tree.product_details p2 ON s2.prod_id = p2.product_id
    JOIN balanced_tree.product_details p3 ON s3.prod_id = p3.product_id
)
SELECT TOP 1
    product_1,
    product_2,
    product_3,
    COUNT(*) AS combo_count
FROM product_combos
GROUP BY product_1, product_2, product_3
ORDER BY combo_count DESC;


-- ============================================================
-- REPORTING CHALLENGE - MONTHLY REPORT
-- 👇 CHỈ CẦN THAY SỐ THÁNG Ở ĐÂY (1=Jan, 2=Feb, ...)
-- ============================================================
DECLARE @report_month INT = 1;   -- 👈 đổi tháng tại đây
DECLARE @report_year  INT = 2021;

-- Q1: Total quantity sold
SELECT 
    'Q1 - Total Quantity Sold'           AS question,
    SUM(qty)                             AS total_quantity_sold
FROM balanced_tree.sales
WHERE MONTH(start_txn_time) = @report_month
  AND YEAR(start_txn_time)  = @report_year;

-- Q2: Total revenue before discounts
SELECT 
    'Q2 - Total Revenue Before Discount' AS question,
    SUM(qty * price)                     AS total_revenue_before_discount
FROM balanced_tree.sales
WHERE MONTH(start_txn_time) = @report_month
  AND YEAR(start_txn_time)  = @report_year;

-- Q3: Total discount amount
SELECT 
    'Q3 - Total Discount Amount'                  AS question,
    ROUND(SUM(qty * price * discount / 100.0), 2) AS total_discount_amount
FROM balanced_tree.sales
WHERE MONTH(start_txn_time) = @report_month
  AND YEAR(start_txn_time)  = @report_year;

-- Q4: Unique transactions
SELECT 
    'Q4 - Unique Transactions'           AS question,
    COUNT(DISTINCT txn_id)               AS unique_transactions
FROM balanced_tree.sales
WHERE MONTH(start_txn_time) = @report_month
  AND YEAR(start_txn_time)  = @report_year;

-- Q5: Average unique products per transaction
WITH txn_products AS (
    SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_products
    FROM balanced_tree.sales
    WHERE MONTH(start_txn_time) = @report_month
      AND YEAR(start_txn_time)  = @report_year
    GROUP BY txn_id
)
SELECT 
    'Q5 - Avg Unique Products Per Txn'           AS question,
    ROUND(AVG(CAST(unique_products AS FLOAT)), 2) AS avg_unique_products
FROM txn_products;

-- Q6: Percentiles for revenue per transaction
WITH txn_revenue AS (
    SELECT txn_id, SUM(qty * price) AS revenue
    FROM balanced_tree.sales
    WHERE MONTH(start_txn_time) = @report_month
      AND YEAR(start_txn_time)  = @report_year
    GROUP BY txn_id
)
SELECT
    'Q6 - Revenue Percentiles'                                    AS question,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue)         AS p25_revenue,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue)         AS p50_revenue,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue)         AS p75_revenue
FROM txn_revenue;

-- Q7: Average discount per transaction
WITH txn_discount AS (
    SELECT txn_id, SUM(qty * price * discount / 100.0) AS total_discount
    FROM balanced_tree.sales
    WHERE MONTH(start_txn_time) = @report_month
      AND YEAR(start_txn_time)  = @report_year
    GROUP BY txn_id
)
SELECT 
    'Q7 - Avg Discount Per Txn'                   AS question,
    ROUND(AVG(CAST(total_discount AS FLOAT)), 2)  AS avg_discount_per_txn
FROM txn_discount;

-- Q8: Member vs non-member transaction split
WITH member_txns AS (
    SELECT member, COUNT(DISTINCT txn_id) AS total_transactions
    FROM balanced_tree.sales
    WHERE MONTH(start_txn_time) = @report_month
      AND YEAR(start_txn_time)  = @report_year
    GROUP BY member
)
SELECT 
    'Q8 - Member vs Non-Member Split'                            AS question,
    CASE WHEN member = 1 THEN 'Member' ELSE 'Non-Member' END    AS member_status,
    total_transactions,
    ROUND(
        100.0 * total_transactions / SUM(total_transactions) OVER (),
        2
    )                                                            AS transaction_pct
FROM member_txns
ORDER BY member_status;

-- Q9: Average revenue for member vs non-member
WITH txn_revenue AS (
    SELECT 
        txn_id,
        member,
        SUM(qty * price * (1 - discount / 100.0)) AS revenue_after_discount
    FROM balanced_tree.sales
    WHERE MONTH(start_txn_time) = @report_month
      AND YEAR(start_txn_time)  = @report_year
    GROUP BY txn_id, member
)
SELECT 
    'Q9 - Avg Revenue Member vs Non-Member'                      AS question,
    CASE WHEN member = 1 THEN 'Member' ELSE 'Non-Member' END    AS member_status,
    ROUND(AVG(CAST(revenue_after_discount AS FLOAT)), 2)         AS avg_revenue
FROM txn_revenue
GROUP BY member
ORDER BY member_status;

-- Q10: Top 3 products by revenue before discount
SELECT TOP 3
    'Q10 - Top 3 Products By Revenue'    AS question,
    pd.product_name,
    SUM(s.qty * s.price)                 AS revenue_before_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
WHERE MONTH(s.start_txn_time) = @report_month
  AND YEAR(s.start_txn_time)  = @report_year
GROUP BY pd.product_name
ORDER BY revenue_before_discount DESC;

-- Q11: Top selling product per segment
WITH ranked_segments AS (
    SELECT 
        pd.segment_name,
        pd.product_name,
        SUM(s.qty) AS total_quantity,
        RANK() OVER (PARTITION BY pd.segment_name ORDER BY SUM(s.qty) DESC) AS rnk
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE MONTH(s.start_txn_time) = @report_month
      AND YEAR(s.start_txn_time)  = @report_year
    GROUP BY pd.segment_name, pd.product_name
)
SELECT 
    'Q11 - Top Product Per Segment'      AS question,
    segment_name,
    product_name,
    total_quantity
FROM ranked_segments
WHERE rnk = 1
ORDER BY segment_name;

-- Q12: Total quantity, revenue and discount per category
SELECT 
    'Q12 - Category Summary'                                         AS question,
    pd.category_name,
    SUM(s.qty)                                                       AS total_quantity,
    SUM(s.qty * s.price)                                             AS revenue_before_discount,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2)             AS total_discount,
    ROUND(SUM(s.qty * s.price * (1 - s.discount / 100.0)), 2)       AS revenue_after_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
WHERE MONTH(s.start_txn_time) = @report_month
  AND YEAR(s.start_txn_time)  = @report_year
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- Q13: Top selling product per category
WITH ranked_categories AS (
    SELECT 
        pd.category_name,
        pd.product_name,
        SUM(s.qty) AS total_quantity,
        RANK() OVER (PARTITION BY pd.category_name ORDER BY SUM(s.qty) DESC) AS rnk
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE MONTH(s.start_txn_time) = @report_month
      AND YEAR(s.start_txn_time)  = @report_year
    GROUP BY pd.category_name, pd.product_name
)
SELECT 
    'Q13 - Top Product Per Category'     AS question,
    category_name,
    product_name,
    total_quantity
FROM ranked_categories
WHERE rnk = 1
ORDER BY category_name;

-- Q14: Revenue % by product for each segment
WITH product_revenue AS (
    SELECT 
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE MONTH(s.start_txn_time) = @report_month
      AND YEAR(s.start_txn_time)  = @report_year
    GROUP BY pd.segment_name, pd.product_name
)
SELECT 
    'Q14 - Revenue % By Product Per Segment'                         AS question,
    segment_name,
    product_name,
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY segment_name), 2) AS revenue_pct
FROM product_revenue
ORDER BY segment_name, revenue_pct DESC;

-- Q15: Revenue % by segment for each category
WITH segment_revenue AS (
    SELECT 
        pd.category_name,
        pd.segment_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE MONTH(s.start_txn_time) = @report_month
      AND YEAR(s.start_txn_time)  = @report_year
    GROUP BY pd.category_name, pd.segment_name
)
SELECT 
    'Q15 - Revenue % By Segment Per Category'                        AS question,
    category_name,
    segment_name,
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY category_name), 2) AS revenue_pct
FROM segment_revenue
ORDER BY category_name, revenue_pct DESC;

-- Q16: Revenue % by category
WITH category_revenue AS (
    SELECT 
        pd.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE MONTH(s.start_txn_time) = @report_month
      AND YEAR(s.start_txn_time)  = @report_year
    GROUP BY pd.category_name
)
SELECT 
    'Q16 - Revenue % By Category'                                    AS question,
    category_name,
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2)                 AS revenue_pct
FROM category_revenue
ORDER BY revenue_pct DESC;

-- Q17: Transaction penetration per product
WITH product_txns AS (
    SELECT 
        pd.product_name,
        COUNT(DISTINCT s.txn_id) AS product_transactions
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE MONTH(s.start_txn_time) = @report_month
      AND YEAR(s.start_txn_time)  = @report_year
    GROUP BY pd.product_name
),
total_txns AS (
    SELECT COUNT(DISTINCT txn_id) AS total_transactions
    FROM balanced_tree.sales
    WHERE MONTH(start_txn_time) = @report_month
      AND YEAR(start_txn_time)  = @report_year
)
SELECT 
    'Q17 - Product Penetration'          AS question,
    product_name,
    product_transactions,
    total_transactions,
    ROUND(100.0 * product_transactions / total_transactions, 2) AS penetration_pct
FROM product_txns
CROSS JOIN total_txns
ORDER BY penetration_pct DESC;


-- ============================================================
-- BONUS CHALLENGE - Recursive CTE
-- Transform product_hierarchy + product_prices → product_details
-- ============================================================

WITH hierarchy AS (
    -- Base case: Category level (no parent)
    SELECT 
        id,
        parent_id,
        level_text,
        level_name,
        CAST(level_text AS VARCHAR(19)) AS category_name,
        CAST(NULL AS VARCHAR(19))       AS segment_name,
        CAST(NULL AS VARCHAR(19))       AS style_name
    FROM balanced_tree.product_hierarchy
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive case: join children to parents
    SELECT 
        child.id,
        child.parent_id,
        child.level_text,
        child.level_name,
        parent.category_name,
        CASE WHEN child.level_name = 'Segment' THEN child.level_text ELSE parent.segment_name END,
        CASE WHEN child.level_name = 'Style'   THEN child.level_text ELSE NULL END
    FROM balanced_tree.product_hierarchy child
    JOIN hierarchy parent
        ON child.parent_id = parent.id
)
SELECT 
    pp.product_id,
    pp.price,
    h.style_name + ' ' +
    h.segment_name + ' ' +
    h.category_name                      AS product_name,
    cat.id                               AS category_id,
    seg.id                               AS segment_id,
    h.id                                 AS style_id,
    h.category_name,
    h.segment_name,
    h.style_name
FROM hierarchy h
JOIN balanced_tree.product_prices pp
    ON h.id = pp.id
JOIN balanced_tree.product_hierarchy seg
    ON seg.level_text = h.segment_name
    AND seg.level_name = 'Segment'
JOIN balanced_tree.product_hierarchy cat
    ON cat.level_text = h.category_name
    AND cat.level_name = 'Category'
WHERE h.level_name = 'Style'
ORDER BY pp.product_id;