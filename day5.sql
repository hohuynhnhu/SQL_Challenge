
-- 1. Data Cleansing Steps
--In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

--Convert the week_date to a DATE format

--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

--Add a month_number with the calendar month for each week_date value as the 3rd column

--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

--Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
--Add a new demographic column using the following mapping for the first letter in the segment values:
--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
DROP TABLE IF EXISTS data_mart.clean_weekly_sales;

SELECT
    CONVERT(date, week_date, 3) AS week_date,

    DATEPART(WEEK, CONVERT(date, week_date, 3)) AS week_number,

    MONTH(CONVERT(date, week_date, 3)) AS month_number,

    YEAR(CONVERT(date, week_date, 3)) AS calendar_year,

    region,
    platform,

    CASE 
        WHEN segment IS NULL OR segment = 'null' THEN 'unknown'
        ELSE segment
    END AS segment,

    CASE 
        WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
        WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
        WHEN RIGHT(segment,1) = '3' THEN 'Retirees'
        ELSE 'unknown'
    END AS age_band,

    CASE
        WHEN LEFT(segment,1) = 'C' THEN 'Couples'
        WHEN LEFT(segment,1) = 'F' THEN 'Families'
        ELSE 'unknown'
    END AS demographic,

    customer_type,
    transactions,
    sales,

    ROUND(CAST(sales AS FLOAT) / transactions, 2) AS avg_transaction

INTO data_mart.clean_weekly_sales
FROM data_mart.weekly_sales;

---2. Data Exploration
--What day of the week is used for each week_date value?
SELECT DISTINCT 
    DATENAME(WEEKDAY, CONVERT(date, week_date, 3)) AS weekday
FROM data_mart.weekly_sales;

--What range of week numbers are missing from the dataset?
WITH week_list AS (
    SELECT DISTINCT 
        DATEPART(WEEK, CONVERT(date, week_date, 3)) AS week_number
    FROM data_mart.weekly_sales
),
all_weeks AS (
    SELECT 1 AS week_number
    UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13
    UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
    UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22
    UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25
    UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28
    UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31
    UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34
    UNION ALL SELECT 35 UNION ALL SELECT 36 UNION ALL SELECT 37
    UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40
    UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43
    UNION ALL SELECT 44 UNION ALL SELECT 45 UNION ALL SELECT 46
    UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49
    UNION ALL SELECT 50 UNION ALL SELECT 51 UNION ALL SELECT 52
)

SELECT a.week_number
FROM all_weeks a
LEFT JOIN week_list w
    ON a.week_number = w.week_number
WHERE w.week_number IS NULL;

-- How many total transactions were there for each year in the dataset?
SELECT 
    YEAR(CONVERT(date, week_date, 3)) AS calendar_year,
    SUM(transactions) AS total_transactions
FROM data_mart.weekly_sales
GROUP BY YEAR(CONVERT(date, week_date, 3))
ORDER BY calendar_year;

--What is the total sales for each region for each month?
SELECT 
    region,
    month_number,
    SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

-- What is the total count of transactions for each platform
SELECT 
    platform,
    SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform
ORDER BY total_transactions DESC;

-- What is the percentage of sales for Retail vs Shopify for each month?
WITH monthly_sales AS (
    SELECT 
        month_number,
        platform,
        SUM(CAST(sales AS BIGINT)) AS sales
    FROM data_mart.clean_weekly_sales
    GROUP BY month_number, platform
)
SELECT 
    month_number,
    platform,
    sales AS total_sales,
    ROUND(
        100.0 * sales / SUM(sales) OVER (PARTITION BY month_number),
        2
    ) AS percentage_sales
FROM monthly_sales
ORDER BY month_number, platform;

--What is the percentage of sales by demographic for each year in the dataset?
SELECT 
    calendar_year,
    demographic,
    SUM(CAST(sales AS BIGINT)) AS total_sales,
    ROUND(
        100.0 * SUM(CAST(sales AS BIGINT)) / SUM(SUM(CAST(sales AS BIGINT))) OVER (PARTITION BY calendar_year),
        2
    ) AS percentage_sales
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, demographic
ORDER BY calendar_year, demographic;

--Which age_band and demographic values contribute the most to Retail sales?
SELECT 
    age_band,
    demographic,
    SUM(CAST(sales AS BIGINT)) AS total_sales,
    ROUND(
        100.0 * SUM(CAST(sales AS BIGINT)) / SUM(SUM(CAST(sales AS BIGINT))) OVER (),
        2
    ) AS percentage_of_retail_sales
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_sales DESC;

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT 
    calendar_year,
    platform,
    SUM(CAST(sales AS BIGINT)) AS total_sales,
    SUM(transactions) AS total_transactions,
    ROUND(
        1.0 * SUM(CAST(sales AS BIGINT)) / SUM(transactions),
        2
    ) AS correct_avg_transaction
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

--3. Before & After Analysis
--This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

--Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

--We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

--Using this analysis approach - answer the following questions:

--What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

DECLARE @baseline_week INT;
SELECT @baseline_week = week_number
FROM data_mart.clean_weekly_sales
WHERE week_date = '2020-06-15';

-- Step 2: Use the variable throughout (no subqueries in GROUP BY)
WITH period_sales AS (
    SELECT 
        CASE 
            WHEN week_number BETWEEN @baseline_week - 4 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week AND @baseline_week + 3     THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 4 AND @baseline_week + 3
    GROUP BY 
        CASE 
            WHEN week_number BETWEEN @baseline_week - 4 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week AND @baseline_week + 3     THEN 'After'
        END
)

SELECT
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) AS after_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS variance,
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    ) AS pct_change
FROM period_sales;

-- What about the entire 12 weeks before and after?
-- Only change needed: swap 4 → 12
DECLARE @baseline_week INT;
SELECT @baseline_week = week_number
FROM data_mart.clean_weekly_sales
WHERE week_date = '2020-06-15';

WITH period_sales AS (
    SELECT 
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1  THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11  THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 12 AND @baseline_week + 11
    GROUP BY 
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1  THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11  THEN 'After'
        END
)
SELECT
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) AS after_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS variance,
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    ) AS pct_change
FROM period_sales;

-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
DECLARE @baseline_week INT;
SELECT @baseline_week = week_number
FROM data_mart.clean_weekly_sales
WHERE week_date = '2020-06-15';

WITH period_sales AS (
    SELECT 
        calendar_year,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 4 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week     AND @baseline_week + 3  THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year IN (2018, 2019, 2020)
      AND week_number BETWEEN @baseline_week - 4 AND @baseline_week + 3
    GROUP BY 
        calendar_year,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 4 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week     AND @baseline_week + 3  THEN 'After'
        END
)
SELECT
    calendar_year,
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) AS after_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS variance,
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    ) AS pct_change
FROM period_sales
GROUP BY calendar_year
ORDER BY calendar_year;

--4. Bonus Question
--Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

--region
--platform
--age_band
--demographic
--customer_type
--Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
DECLARE @baseline_week INT;
SELECT @baseline_week = week_number
FROM data_mart.clean_weekly_sales
WHERE week_date = '2020-06-15';

-- 1. BY REGION
WITH period_sales AS (
    SELECT 
        region AS segment,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 12 AND @baseline_week + 11
    GROUP BY 
        region,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END
)
SELECT
    'Region'     AS dimension,
    segment,
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) AS after_sales,
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END) AS variance,
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    ) AS pct_change
FROM period_sales
GROUP BY segment

UNION ALL

-- 2. BY PLATFORM
SELECT 
    'Platform' AS dimension,
    platform,
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    )
FROM (
    SELECT 
        platform,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 12 AND @baseline_week + 11
    GROUP BY 
        platform,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END
) p
GROUP BY platform

UNION ALL

-- 3. BY AGE BAND
SELECT 
    'Age Band' AS dimension,
    age_band,
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    )
FROM (
    SELECT 
        age_band,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 12 AND @baseline_week + 11
    GROUP BY 
        age_band,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END
) a
GROUP BY age_band

UNION ALL

-- 4. BY DEMOGRAPHIC
SELECT 
    'Demographic' AS dimension,
    demographic,
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    )
FROM (
    SELECT 
        demographic,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 12 AND @baseline_week + 11
    GROUP BY 
        demographic,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END
) d
GROUP BY demographic

UNION ALL

-- 5. BY CUSTOMER TYPE
SELECT 
    'Customer Type' AS dimension,
    customer_type,
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END),
    MAX(CASE WHEN period = 'After'  THEN total_sales END) -
    MAX(CASE WHEN period = 'Before' THEN total_sales END),
    ROUND(
        100.0 * (
            MAX(CASE WHEN period = 'After'  THEN total_sales END) -
            MAX(CASE WHEN period = 'Before' THEN total_sales END)
        ) / MAX(CASE WHEN period = 'Before' THEN total_sales END),
        2
    )
FROM (
    SELECT 
        customer_type,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END AS period,
        SUM(CAST(sales AS BIGINT)) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
      AND week_number BETWEEN @baseline_week - 12 AND @baseline_week + 11
    GROUP BY 
        customer_type,
        CASE 
            WHEN week_number BETWEEN @baseline_week - 12 AND @baseline_week - 1 THEN 'Before'
            WHEN week_number BETWEEN @baseline_week      AND @baseline_week + 11 THEN 'After'
        END
) c
GROUP BY customer_type

ORDER BY dimension, pct_change;

