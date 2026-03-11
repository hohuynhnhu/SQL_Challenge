-- Data Exploration and Cleansing---

-- 1 Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

-- Bước 1: Xử lý NULL string trước
UPDATE fresh_segments.interest_metrics
SET month_year = NULL
WHERE month_year = 'NULL';

-- Bước 2: Chuyển đổi định dạng chuỗi 'MM-YYYY' thành 'YYYY-MM-DD' để SQL Server hiểu được
UPDATE fresh_segments.interest_metrics
SET month_year = RIGHT(month_year, 4) + '-' + LEFT(month_year, 2) + '-01'
WHERE month_year IS NOT NULL;

-- Bước 3: Đổi kiểu dữ liệu sang DATE
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year DATE;

-- 2 Count records for each month_year sorted with null values first
-- (Trong T-SQL, NULL mặc định đứng đầu khi ORDER BY ASC)
SELECT 
    month_year,
    COUNT(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year ASC;

-- 3 Null values count
SELECT 
    SUM(CASE WHEN month_year IS NULL THEN 1 ELSE 0 END) AS null_month_year,
    SUM(CASE WHEN interest_id IS NULL THEN 1 ELSE 0 END) AS null_interest_id,
    SUM(CASE WHEN _month IS NULL THEN 1 ELSE 0 END) AS null_month,
    SUM(CASE WHEN _year IS NULL THEN 1 ELSE 0 END) AS null_year,
    COUNT(*) AS total_records
FROM fresh_segments.interest_metrics;

-- 4 interest_id in metrics but NOT in map
SELECT COUNT(DISTINCT interest_id) AS in_metrics_not_in_map
FROM fresh_segments.interest_metrics
WHERE CAST(interest_id AS INT) NOT IN (
    SELECT id FROM fresh_segments.interest_map
)
AND interest_id IS NOT NULL;

-- interest_id in map but NOT in metrics
SELECT COUNT(DISTINCT id) AS in_map_not_in_metrics
FROM fresh_segments.interest_map
WHERE id NOT IN (
    SELECT DISTINCT CAST(interest_id AS INT)
    FROM fresh_segments.interest_metrics
    WHERE interest_id IS NOT NULL
);

-- 5 Summarise map table
SELECT 
    COUNT(id) AS total_ids,
    COUNT(DISTINCT id) AS unique_ids,
    MIN(id) AS min_id,
    MAX(id) AS max_id
FROM fresh_segments.interest_map;

-- 6 Join tables check
SELECT 
    im.*,
    map.interest_name,
    map.interest_summary,
    map.created_at,
    map.last_modified
FROM fresh_segments.interest_metrics im
LEFT JOIN fresh_segments.interest_map map
    ON CAST(im.interest_id AS INT) = map.id
WHERE im.interest_id = '21246';

-- 7 month_year before created_at
SELECT 
    im.*,
    map.interest_name,
    map.created_at,
    im.month_year
FROM fresh_segments.interest_metrics im
LEFT JOIN fresh_segments.interest_map map
    ON CAST(im.interest_id AS INT) = map.id
WHERE im.month_year < DATEFROMPARTS(YEAR(map.created_at), MONTH(map.created_at), 1)
AND im.month_year IS NOT NULL;

--Interest Analysis---
-- 1 Present in all month_year dates
WITH TotalMonths AS (
  SELECT COUNT(DISTINCT month_year) AS max_months
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
)
SELECT 
  im.interest_id, 
  COUNT(DISTINCT im.month_year) AS months_present
FROM fresh_segments.interest_metrics im
WHERE im.month_year IS NOT NULL
GROUP BY im.interest_id
HAVING COUNT(DISTINCT im.month_year) = (SELECT max_months FROM TotalMonths)
ORDER BY im.interest_id;

-- 2 Cumulative percentage
WITH InterestMonthCounts AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
),
MonthFrequencies AS (
  SELECT 
    total_months, 
    COUNT(interest_id) AS interest_count
  FROM InterestMonthCounts
  GROUP BY total_months
)
SELECT 
  total_months,
  interest_count,
  SUM(interest_count) OVER (ORDER BY total_months DESC) AS cumulative_interests,
  ROUND(
    100.0 * SUM(interest_count) OVER (ORDER BY total_months DESC) 
    / SUM(interest_count) OVER (), 2
  ) AS cumulative_percentage
FROM MonthFrequencies
ORDER BY total_months DESC;

-- 3 Data points removed
WITH InterestMonthCounts AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
),
InterestsToRemove AS (
  SELECT interest_id
  FROM InterestMonthCounts
  WHERE total_months < 6  
)
SELECT COUNT(*) AS removed_data_points
FROM fresh_segments.interest_metrics
WHERE interest_id IN (SELECT interest_id FROM InterestsToRemove);

-- 5 Unique interests for each month
WITH InterestMonthCounts AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
)
SELECT 
  month_year, 
  COUNT(DISTINCT interest_id) AS unique_interests
FROM fresh_segments.interest_metrics
WHERE interest_id IN (
  SELECT interest_id 
  FROM InterestMonthCounts 
  WHERE total_months >= 6 
)
AND month_year IS NOT NULL
GROUP BY month_year
ORDER BY month_year;

---Segment Analysis--
-- 1 Top 10 and bottom 10 largest composition
WITH FilteredInterests AS (
  SELECT interest_id
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
),
MaxCompositionPerInterest AS (
  SELECT 
    im.interest_id,
    map.interest_name,
    im.month_year,
    im.composition,
    ROW_NUMBER() OVER(PARTITION BY im.interest_id ORDER BY im.composition DESC) as rank_comp
  FROM fresh_segments.interest_metrics im
  JOIN fresh_segments.interest_map map 
    ON im.interest_id = CAST(map.id AS VARCHAR(50))
  WHERE im.interest_id IN (SELECT interest_id FROM FilteredInterests)
),
HighestCompositions AS (
  SELECT interest_id, interest_name, month_year, composition
  FROM MaxCompositionPerInterest
  WHERE rank_comp = 1
),
Top10 AS (
  SELECT TOP 10 'Top 10' AS category, interest_id, interest_name, month_year, composition 
  FROM HighestCompositions 
  ORDER BY composition DESC 
),
Bottom10 AS (
  SELECT TOP 10 'Bottom 10' AS category, interest_id, interest_name, month_year, composition 
  FROM HighestCompositions 
  ORDER BY composition ASC 
)
SELECT * FROM Top10
UNION ALL
SELECT * FROM Bottom10;

-- 2 Lowest average ranking value
WITH FilteredInterests AS (
  SELECT interest_id
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT TOP 5
  im.interest_id,
  map.interest_name,
  ROUND(AVG(CAST(im.ranking AS DECIMAL(10,2))), 2) AS avg_ranking
FROM fresh_segments.interest_metrics im
JOIN fresh_segments.interest_map map 
  ON im.interest_id = CAST(map.id AS VARCHAR(50))
WHERE im.interest_id IN (SELECT interest_id FROM FilteredInterests)
GROUP BY im.interest_id, map.interest_name
ORDER BY avg_ranking ASC;

-- 3 Largest standard deviation
WITH FilteredInterests AS (
  SELECT interest_id
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT TOP 5
  im.interest_id,
  map.interest_name,
  ROUND(CAST(STDEV(im.percentile_ranking) AS DECIMAL(10,2)), 2) AS stddev_percentile_ranking
FROM fresh_segments.interest_metrics im
JOIN fresh_segments.interest_map map 
  ON im.interest_id = CAST(map.id AS VARCHAR(50))
WHERE im.interest_id IN (SELECT interest_id FROM FilteredInterests)
GROUP BY im.interest_id, map.interest_name
HAVING STDEV(im.percentile_ranking) IS NOT NULL
ORDER BY stddev_percentile_ranking DESC;

-- 4 Min and Max percentile ranking (Using STDEV to order)
WITH FilteredInterests AS (
  SELECT interest_id
  FROM fresh_segments.interest_metrics
  WHERE month_year IS NOT NULL
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
),
Top5Volatile AS (
  SELECT TOP 5 im.interest_id
  FROM fresh_segments.interest_metrics im
  WHERE im.interest_id IN (SELECT interest_id FROM FilteredInterests)
  GROUP BY im.interest_id
  ORDER BY STDEV(im.percentile_ranking) DESC 
),
RankedPercentiles AS (
  SELECT 
    im.interest_id,
    map.interest_name,
    im.month_year,
    im.percentile_ranking,
    ROW_NUMBER() OVER(PARTITION BY im.interest_id ORDER BY im.percentile_ranking ASC) as min_rank,
    ROW_NUMBER() OVER(PARTITION BY im.interest_id ORDER BY im.percentile_ranking DESC) as max_rank
  FROM fresh_segments.interest_metrics im
  JOIN fresh_segments.interest_map map ON im.interest_id = CAST(map.id AS VARCHAR(50))
  WHERE im.interest_id IN (SELECT interest_id FROM Top5Volatile)
)
SELECT 
  min_p.interest_name,
  min_p.month_year AS min_month_year,
  min_p.percentile_ranking AS min_percentile_ranking,
  max_p.month_year AS max_month_year,
  max_p.percentile_ranking AS max_percentile_ranking
FROM RankedPercentiles min_p
JOIN RankedPercentiles max_p ON min_p.interest_id = max_p.interest_id
WHERE min_p.min_rank = 1 AND max_p.max_rank = 1;

--- Index Analysis --- 
-- 3 Top 10 by average composition
WITH AvgCompositionCTE AS (
  SELECT 
    im.month_year,
    im.interest_id,
    ROUND((CAST(im.composition AS DECIMAL(10,2)) / CAST(im.index_value AS DECIMAL(10,2))), 2) AS avg_comp
  FROM fresh_segments.interest_metrics im
  WHERE im.month_year IS NOT NULL
),
RankedInterests AS (
  SELECT 
    a.month_year,
    m.interest_name,
    a.avg_comp,
    RANK() OVER (PARTITION BY a.month_year ORDER BY a.avg_comp DESC) as rank
  FROM AvgCompositionCTE a
  JOIN fresh_segments.interest_map m ON a.interest_id = CAST(m.id AS VARCHAR(50))
)
SELECT 
  month_year, 
  interest_name, 
  avg_comp
FROM RankedInterests
WHERE rank <= 10
ORDER BY month_year, rank;

-- 4 Top 10 interest that appears the most
WITH AvgCompositionCTE AS (
  SELECT 
    im.month_year,
    im.interest_id,
    ROUND((CAST(im.composition AS DECIMAL(10,2)) / CAST(im.index_value AS DECIMAL(10,2))), 2) AS avg_comp
  FROM fresh_segments.interest_metrics im
  WHERE im.month_year IS NOT NULL
),
RankedInterests AS (
  SELECT 
    a.month_year,
    m.interest_name,
    a.avg_comp,
    RANK() OVER (PARTITION BY a.month_year ORDER BY a.avg_comp DESC) as rank
  FROM AvgCompositionCTE a
  JOIN fresh_segments.interest_map m ON a.interest_id = CAST(m.id AS VARCHAR(50))
)
SELECT TOP 5
  interest_name,
  COUNT(*) AS appearance_count
FROM RankedInterests
WHERE rank <= 10
GROUP BY interest_name
ORDER BY appearance_count DESC;

-- 5 Average of the average composition
WITH AvgCompositionCTE AS (
  SELECT 
    im.month_year,
    ROUND((CAST(im.composition AS DECIMAL(10,2)) / CAST(im.index_value AS DECIMAL(10,2))), 2) AS avg_comp
  FROM fresh_segments.interest_metrics im
  WHERE im.month_year IS NOT NULL
),
RankedInterests AS (
  SELECT 
    month_year,
    avg_comp,
    RANK() OVER (PARTITION BY month_year ORDER BY avg_comp DESC) as rank
  FROM AvgCompositionCTE
)
SELECT 
  month_year,
  ROUND(AVG(avg_comp), 2) AS avg_of_top_10_comp
FROM RankedInterests
WHERE rank <= 10
GROUP BY month_year
ORDER BY month_year;

-- 6 3 month rolling average (T-SQL requires string concatenation with explicit cast for LAG output)
WITH AvgCompositionCTE AS (
  SELECT 
    im.month_year,
    m.interest_name,
    ROUND((CAST(im.composition AS DECIMAL(10,2)) / CAST(im.index_value AS DECIMAL(10,2))), 2) AS avg_comp
  FROM fresh_segments.interest_metrics im
  JOIN fresh_segments.interest_map m ON im.interest_id = CAST(m.id AS VARCHAR(50))
  WHERE im.month_year IS NOT NULL
),
Top1PerMonth AS (
  SELECT 
    month_year,
    interest_name,
    avg_comp AS max_avg_comp
  FROM (
    SELECT 
      month_year,
      interest_name,
      avg_comp,
      RANK() OVER (PARTITION BY month_year ORDER BY avg_comp DESC) as rank
    FROM AvgCompositionCTE
  ) ranked
  WHERE rank = 1
),
RollingStats AS (
  SELECT 
    month_year,
    interest_name,
    max_avg_comp,
    ROUND(
      AVG(max_avg_comp) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 
    2) AS [3_month_moving_avg],
    LAG(interest_name, 1) OVER(ORDER BY month_year) + ': ' + CAST(LAG(max_avg_comp, 1) OVER(ORDER BY month_year) AS VARCHAR(50)) AS [1_month_ago],
    LAG(interest_name, 2) OVER(ORDER BY month_year) + ': ' + CAST(LAG(max_avg_comp, 2) OVER(ORDER BY month_year) AS VARCHAR(50)) AS [2_months_ago]
  FROM Top1PerMonth
)
SELECT * FROM RollingStats
WHERE month_year >= '2018-09-01' AND month_year <= '2019-08-01'
ORDER BY month_year;