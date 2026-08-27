-- S12: 7-day conversion attribution
--
-- Conversion = user placed an order within 7 days of first seeing their
-- variant. Only the first order counts: this measures whether they
-- converted, not how often they bought.
--
-- LEFT JOIN LATERAL lets the subquery reference b.first_exposure_ts from
-- the outer row, which a plain JOIN cannot do — the search window is
-- different for every user. LEFT keeps non-converters as NULL, so
-- COUNT(order_id) counts converters while COUNT(*) counts everyone.
--
-- Performance note: LATERAL runs the subquery once per user (66,570
-- times). Against stg_orders_d2c, a view that re-runs its dedup logic on
-- every call, this never finished. Staging it into an indexed temp table
-- first brings it down to seconds. The temp table lives only for the
-- session, so the three setup statements below are part of the script.
--
-- Result: A = 5.893%, B = 6.809% — matches the official figures from
-- ab_analysis.py exactly, which validates the whole SQL pipeline.

-- Setup (session-scoped)
CREATE TEMP TABLE tmp_orders AS
SELECT customer_id, order_id, order_ts_wib
FROM analytics_staging.stg_orders_d2c;

CREATE INDEX ON tmp_orders (customer_id, order_ts_wib);

ANALYZE tmp_orders;


-- Main query
WITH base AS (
    SELECT user_id, variant, first_exposure_ts
    FROM analytics_staging.stg_ab_exposures
    WHERE is_bot            = FALSE
      AND is_multi_variant  = FALSE
      AND is_first_exposure = TRUE
),
converted AS (
    SELECT
        b.user_id,
        b.variant,
        fo.order_id
    FROM base  b
    LEFT JOIN LATERAL (
        SELECT o.order_id
        FROM tmp_orders  o
        WHERE o.customer_id  = b.user_id
          AND o.order_ts_wib >= b.first_exposure_ts
          AND o.order_ts_wib <= b.first_exposure_ts + INTERVAL '7 days'
        ORDER BY o.order_ts_wib
        LIMIT 1
    ) fo  ON true
)
SELECT
    variant,
    COUNT(*)                                              AS n,
    COUNT(order_id)                                       AS converters,
    ROUND(COUNT(order_id)::numeric / COUNT(*) * 100, 3)   AS conv_rate_pct
FROM converted
GROUP BY variant
ORDER BY variant;