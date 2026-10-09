-- =====================================================
-- S10: D2C cohort retention, M0-M3
-- =====================================================
-- Cohort = month of a customer's first order. Registered customers only
--   (customer_id LIKE 'C%'). Guest IDs (G...) change on every order and
--   visitor IDs (V...) exist only inside the experiment window, so
--   neither can be followed across months.
--
-- Status filter: excluded 'cancelled' only. A cancelled order never
--   became a transaction, but 'refunded' did (money moved), and
--   'processing' only exists in June. Filtering it would shrink the
--   June cohort by 27% (321 -> 234) for reasons of data maturity, not
--   behaviour.
--
-- COUNT(DISTINCT customer_id), not COUNT(*): retention counts people,
--   not orders. Registered customers average ~3 orders each.
--
-- Result: 6 rows. Zeros in the lower right are right-censoring (data
--   ends 30 June), not lost customers. See README for findings.
-- =====================================================

WITH orders AS (
    -- LAYER 1: Monthly orders, registered customers only.
    SELECT
        customer_id,
        DATE_TRUNC('month', order_ts_wib)  AS order_month
    FROM analytics_staging.stg_orders_d2c
    WHERE customer_id LIKE 'C%'
      AND order_status <> 'cancelled'
),

cohorts AS (
    -- LAYER 2: Month of each customer's first order
    SELECT
        customer_id,
        MIN(order_month)  AS cohort_month
    FROM orders
    GROUP BY customer_id
),

joined AS (
    -- LAYER 3: Assign a cohort to each order and calculate the month difference.
    SELECT
        c.cohort_month,
        o.customer_id,
        (EXTRACT(YEAR  FROM o.order_month) - EXTRACT(YEAR  FROM c.cohort_month)) * 12
      + (EXTRACT(MONTH FROM o.order_month) - EXTRACT(MONTH FROM c.cohort_month))
            AS month_number
    FROM orders   o
    JOIN cohorts  c  ON o.customer_id = c.customer_id
)

-- LAYER 4: pivot into M0-M3 columns
SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0)  AS m0,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 1)  AS m1,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 2)  AS m2,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 3)  AS m3
FROM joined
GROUP BY cohort_month
ORDER BY cohort_month;
