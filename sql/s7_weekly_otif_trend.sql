-- =====================================================
-- S7: Weekly OTIF trend by warehouse
-- =====================================================
-- Question: OTIF percentage per warehouse per week, plus the change
--   versus the previous week. Which warehouse dropped, when, how far?
--   No warehouse or date is given; the query finds them.
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
--     a bad week, excluding them flatters that week. I checked: missing
--     scans run at 3.5-4.5% in every warehouse and every month, so this
--     does not distort the May signal.
--   - Cast the numerator to numeric. Integer / integer returns an
--     integer in Postgres, so the whole column would have read 0.
--   - Kept a shipments column even though the question does not ask
--     for it. A percentage without its base is misleading, and the
--     final partial week proves it: WH-BDG shows 100% off 3 shipments
--     and WH-CKR shows a -33.2pp swing off 2. Without the count those
--     look like real events.
--   - LAG in a separate layer: otif_pct is created in the SELECT of
--     the CTE, so it cannot be referenced in the same layer.
--   - PARTITION BY warehouse_id so each warehouse compares against its
--     own previous week, not against whichever row happens to precede
--     it.
--
-- Result: 80 rows (26-27 weeks per warehouse; the weeks of 29 Dec and
--   29 Jun are partial).
--
-- Finding:
--   WH-CKR collapses in the week of 18 May: 83.8% -> 50.0%, a 33.8
--   point drop over 1,335 shipments. It stays at 49.8% the following
--   week, recovers partially to 69.3% in the week of 1 June, and is
--   back to normal (85.4%) by 8 June.
--
--   WH-BDG and WH-TGR stay inside their usual 79-89% band throughout,
--   apart from the partial final week. The failure is isolated to one
--   warehouse and one three-week window, which rules out a courier-wide
--   or seasonal cause.
--
--   The drop starts in the week of 18 May, a few days before the S6
--   stockouts (22/23-30 May), and lasts into early June. It is almost
--   entirely lateness: incomplete shipments stayed near 3% while late
--   deliveries rose. Orders with and without the hero SKUs were late at
--   nearly the same rate (47.0% vs 48.8%), which points to warehouse
--   load during the promo rather than to the stockout itself.
--
--   Note the volume column: WH-CKR ran 1,262-1,482 scanned shipments a
--   week during the promo (weeks of 4 May - 8 June), versus about 920 in
--   the five weeks before.
-- =====================================================

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


-- =====================================================
-- Supporting checks for the Finding above
-- =====================================================
-- Check 1: WH-CKR May OTIF failures by type.
--   Result: 1,806 failed = 1,615 late only + 142 partial only + 49 both.
--
-- Check 2: late share 18 May - 3 June, orders with vs without the hero
--   SKUs. ship_date is a DATE, so BETWEEN includes both end days.
--   Result: without hero SKUs 48.8% late, with hero SKUs 47.0%.
-- =====================================================

-- Check 1
SELECT
    COUNT(*) FILTER (WHERE NOT is_otif)                                              AS failed,
    COUNT(*) FILTER (WHERE delivered_date >  promised_date AND fulfil_type =  'full') AS late_only,
    COUNT(*) FILTER (WHERE delivered_date <= promised_date AND fulfil_type <> 'full') AS partial_only,
    COUNT(*) FILTER (WHERE delivered_date >  promised_date AND fulfil_type <> 'full') AS late_and_partial
FROM analytics_marts.fct_otif_shipments
WHERE warehouse_id = 'WH-CKR'
  AND ship_date >= '2026-05-01' AND ship_date < '2026-06-01'
  AND is_otif IS NOT NULL;

-- Check 2
SELECT
    o.has_hero,
    COUNT(*)                                                                         AS shipments,
    ROUND(AVG(CASE WHEN s.delivered_date > s.promised_date THEN 1 ELSE 0 END) * 100, 1) AS late_pct
FROM analytics_marts.fct_otif_shipments s
JOIN analytics_marts.fct_orders o ON o.order_id = s.order_id
WHERE s.warehouse_id = 'WH-CKR'
  AND s.ship_date BETWEEN '2026-05-18' AND '2026-06-03'
  AND s.delivered_date IS NOT NULL
GROUP BY o.has_hero;
