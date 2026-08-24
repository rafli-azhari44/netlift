-- =====================================================
-- S7: Weekly OTIF trend by warehouse
-- =====================================================
-- Question: OTIF percentage per warehouse per week, plus the change
--   versus the previous week. Which warehouse dropped, when, how far?
--   No warehouse or date is given — the query finds them.
--
-- OTIF = On Time In Full: delivered by the promised date AND complete.
--   It is the logistics team's headline KPI (Pak Yusuf's number).
--
-- Decisions:
--   - Excluded rows where delivered_date IS NULL (1,672 shipments,
--     FAULT S1: parcel arrived but was never scanned). These are
--     unknown, not late. Counting them as failures would understate
--     OTIF across every week and every warehouse, hiding the one drop
--     that actually matters. The trade-off: if scan failures cluster in
--     a bad week, excluding them flatters that week. I checked — the
--     missing scans are spread evenly, so this does not distort the
--     May signal.
--   - Cast the numerator to numeric. Integer / integer returns an
--     integer in Postgres, so the whole column would have read 0.
--   - Kept a shipments column even though the question does not ask
--     for it. A percentage without its base is misleading, and the
--     final partial week proves it: WH-BDG shows 100% off 3 shipments
--     and WH-CKR shows a -33.2pp swing off 2. Without the count those
--     look like real events.
--   - LAG in a separate layer: otif_pct is created in the SELECT of
--     the

WITH weekly_otif AS (
    SELECT
        DATE_TRUNC('week', ship_date)   AS week,
        warehouse_id,
        COUNT(*)                                     AS shipments,
        ROUND(
            COUNT(*) FILTER (WHERE is_otif)::numeric / COUNT(*) * 100
        , 1)                                          AS otif_pct
    FROM analytics_staging.stg_shipments
    WHERE delivered_date IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    week,
    warehouse_id,
    shipments,
    otif_pct,
    ROUND(
        otif_pct - LAG(otif_pct) OVER (
            PARTITION BY warehouse_id
            ORDER BY week
        )
    , 1)  AS delta_pp
FROM weekly_otif
ORDER BY warehouse_id, week;