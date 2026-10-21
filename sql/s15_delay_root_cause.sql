-- =====================================================
-- S15: Delay root cause with GROUPING SETS
-- =====================================================
-- One query, four groupings (warehouse / courier / month / warehouse x
--   month) instead of four separate queries stitched together by hand.
--
-- "Late" = NOT is_otif, covering both late delivery and incomplete
--   fulfilment. Rows with no delivered_date excluded (FAULT S1): unknown,
--   not late.
--
-- NULLs mark a dimension not used in that grouping, not missing data.
--   DATE_TRUNC is written out again inside GROUPING SETS instead of the
--   alias month. PostgreSQL would accept the alias, but SQL Server rejects
--   a SELECT alias in GROUP BY, and if the source ever gained a column
--   named month, PostgreSQL would group by that column instead.
--
-- Result: 31 rows (3 warehouses + 4 couriers + 6 months + 18
--   warehouse-month pairs).
--   - The courier is not the cause: all four sit at 17.6-18.0% late.
--   - Neither warehouse nor month alone explains the spike; only the
--     crossing does. WH-CKR in May is at 31.2% late, while the other
--     two warehouses stay at 13.5-13.8% that month.
--   - The failures are late deliveries, not incomplete ones (see the
--     supporting checks in S7).
--   See README.
-- =====================================================

SELECT
    warehouse_id,
    courier,
    DATE_TRUNC('month', ship_date)  AS month,
    COUNT(*)                                                     AS shipments,
    ROUND(COUNT(*) FILTER (WHERE NOT is_otif)::numeric / COUNT(*) * 100, 1)  AS late_pct
FROM analytics_staging.stg_shipments
WHERE delivered_date IS NOT NULL
GROUP BY GROUPING SETS (
    (warehouse_id),
    (courier),
    (DATE_TRUNC('month', ship_date)),
    (warehouse_id, DATE_TRUNC('month', ship_date))
)
ORDER BY late_pct DESC;
