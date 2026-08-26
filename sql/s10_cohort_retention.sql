-- S10: D2C cohort retention, M0-M3
--
-- Cohort = month of a customer's first order. Registered customers only
-- (customer_id LIKE 'C%'); guest IDs starting with V cannot be tracked
-- across time.
--
-- Status filter: excluded 'cancelled' only. A cancelled order never
-- became a transaction, but 'refunded' did (money moved), and
-- 'processing' only exists in June — filtering it would shrink the
-- June cohort by 28% for reasons of data maturity, not behaviour.
--
-- COUNT(DISTINCT customer_id), not COUNT(*): retention counts people,
-- not orders. There are ~3 orders per customer in this dataset.
--
-- Result: 6 rows. See README for the retention findings.

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

    -- LAYER 4: pivot jadi M0-M3
SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0)  AS m0,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 1)  AS m1,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 2)  AS m2,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 3)  AS m3
FROM joined
GROUP BY cohort_month
ORDER BY cohort_month;