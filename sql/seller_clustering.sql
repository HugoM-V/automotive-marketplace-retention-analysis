-- Monthly overview of sellers by cluster (New, Recurring, Reactivated, Churned)
-- Based on successful sales only. Includes continuous month calendar to capture inactivity.
-- Clusters are assigned by activity history (3-month threshold for churn) and aggregated by month × segmentation.
-- Commented by step for clarity.
-- Note: monthly keys are CAST to DATE to avoid timezone/DST issues when joining on months.
-- ASSUMPTION: Churn is treated as an event, not a state.
-- Sellers are counted as "Churned" only in the month they reach 3 months of inactivity.


-- Step 1: Successful sales per seller per month
-- Purpose: set monthly grain based on business activity (successful sales only)
WITH successful_sales AS (
  SELECT DISTINCT
    seller_account_uuid,
    CAST(DATE_TRUNC('month', auction_reference_date) AS DATE) AS month  -- normalized to DATE
  FROM auction_overview
  WHERE is_successful = TRUE
),

-- Step 2: Define min/max month across the dataset
-- Purpose: bound the global analysis window for calendar generation
global_bounds AS (
  SELECT
    MIN(month) AS min_month,
    MAX(month) AS max_month
  FROM successful_sales
),

-- Step 3: First/last active month per seller
-- Purpose: start each seller’s timeline at first activity (avoid pre-first-sale noise)
first_last_by_seller AS (
  SELECT
    seller_account_uuid,
    MIN(month) AS first_month,
    MAX(month) AS last_month
  FROM successful_sales
  GROUP BY seller_account_uuid
),

-- Step 4: Global month calendar from min to max
-- Purpose: generate a continuous month list so inactivity months (0 activity) can exist
months AS (
  SELECT *
  FROM (
    SELECT CAST(
             DATEADD(month, seq4(), (SELECT min_month FROM global_bounds))
           AS DATE) AS month                                             -- normalized to DATE
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
  )
  WHERE month <= (SELECT max_month FROM global_bounds)
),

-- Step 5: Seller × month grid with activity flag
-- Combine sellers with months within their window; mark active (1) / inactive (0)
seller_month AS (
  SELECT
    f.seller_account_uuid,
    m.month,
    CASE WHEN ss.seller_account_uuid IS NOT NULL THEN 1 ELSE 0 END AS active
  FROM first_last_by_seller f
  JOIN months m
    ON m.month >= f.first_month                                 -- start at first active month
   AND m.month <= (SELECT max_month FROM global_bounds)         -- extend to global max (detect churn)
  LEFT JOIN successful_sales ss
    ON ss.seller_account_uuid = f.seller_account_uuid
   AND ss.month = m.month                                       -- DATE = DATE (no DST mismatch)
),

-- Step 6: Add features for clustering (prev activity, cumulative active months, last active month)
enriched AS (
  SELECT
    seller_account_uuid,
    month,
    active,
    LAG(active) OVER (
      PARTITION BY seller_account_uuid
      ORDER BY month
    ) AS active_prev,                                           -- last month’s activity (1/0)

    SUM(CASE WHEN active = 1 THEN 1 ELSE 0 END) OVER (
      PARTITION BY seller_account_uuid
      ORDER BY month
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_active_count,                                      -- cumulative active months (to distinguish New vs Reactivated)

    MAX(CASE WHEN active = 1 THEN month END) OVER (
      PARTITION BY seller_account_uuid
      ORDER BY month
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS last_active_month                                      -- last active month strictly before current
  FROM seller_month
),

-- Step 7: Months since last activity (gap used to tag churn)
with_inactivity AS (
  SELECT
    *,
    CASE
      WHEN active = 1 THEN 0
      WHEN last_active_month IS NULL THEN NULL
      ELSE DATEDIFF('month', last_active_month, month)
    END AS months_since_last_active
  FROM enriched
),

-- Step 8: Assign monthly clusters
-- Purpose: map each seller×month to New / Recurring / Reactivated / Churned
clusters AS (
  SELECT
    seller_account_uuid,
    month,
    CASE
      WHEN active = 1 AND cum_active_count = 1 THEN 'New'
      WHEN active = 1 AND COALESCE(active_prev, 0) = 1 THEN 'Recurring'
      WHEN active = 1 AND COALESCE(active_prev, 0) = 0 AND cum_active_count > 1 THEN 'Reactivated'
      WHEN active = 0 AND months_since_last_active = 3 THEN 'Churned'
      ELSE NULL
    END AS cluster
  FROM with_inactivity
)

-- Final result
SELECT
  c.month,
  c.cluster,
  COALESCE(cs.segmentation, 'Unassigned') AS segmentation, -- turn NULL segmentation into "Unassigned"
  COUNT(DISTINCT c.seller_account_uuid) AS sellers_count
FROM clusters c
JOIN customer_seller_account cs
  ON cs.seller_account_uuid = c.seller_account_uuid
WHERE c.cluster IS NOT NULL
GROUP BY
  c.month, c.cluster, COALESCE(cs.segmentation, 'Unassigned') 
ORDER BY
  c.month, c.cluster, segmentation;

  
