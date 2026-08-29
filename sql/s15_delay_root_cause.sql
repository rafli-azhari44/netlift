-- S15: Delay root cause with GROUPING SETS
--
-- One query, four groupings (warehouse / courier / month / warehouse x
-- month) instead of four separate queries stitched together by hand.
--
-- "Late" = NOT is_otif, covering both late delivery and incomplete
-- fulfilment. Rows with no delivered_date excluded (FAULT S1) — unknown,
-- not late.
--
-- NULLs mark a dimension not used in that grouping, not missing data.
-- DATE_TRUNC is repeated inside GROUPING SETS because GROUP BY runs
-- before SELECT, so the alias does not exist yet.
--
-- Result: 31 rows. Neither warehouse nor month alone explains the spike;
-- only the crossing does — WH-CKR in May at 31.2% while the other two
-- warehouses stay near 13.5% that month. See findings log.

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