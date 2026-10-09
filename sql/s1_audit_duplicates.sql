-- =====================================================
-- S1: Duplicate order audit
-- =====================================================
-- Question: Bu Ratna (Finance) reports that the order count in my
--   report differs from TokoRia's. Show the raw row count, the unique
--   order count and the gap in a single query.
--
-- Result: 1 row. 44,200 rows, 43,893 unique orders, a gap of 307.
--   The 307 extra rows are orders recorded twice when the payment
--   webhook fired twice (FAULT O2). Staging keeps one copy per order,
--   the most recently ingested one.
-- =====================================================

SELECT
    COUNT(*)                             AS total_rows,
    COUNT(DISTINCT order_id)             AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id)  AS gap
FROM raw.orders_d2c;
