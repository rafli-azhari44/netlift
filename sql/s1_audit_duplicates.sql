-- S1: Duplicate order audit
-- Bu Ratna (Finance) reports the order count in my report differs from TokoRia's.
-- Show raw row count, unique order count, and the gap in a single query.
-- Expected: 44,200 / 43,893 / 307
SELECT
    COUNT(*)  AS total_rows,
    COUNT(DISTINCT order_id)  AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS gap
FROM raw.orders_d2c;