-- =====================================================
-- S5: Days of cover for KRK-BLD-080 at WH-CKR
-- =====================================================
-- Question: per day, show stock on hand, 7-day average usage, and how
--   many days the remaining stock would last. Window: 10-25 May 2026.
--
-- The hard part: stg_inventory_daily has no "usage" column. I had to
--   define the metric myself. Two options were available:
--
--   (a) Stock delta via LAG: yesterday's stock minus today's.
--       Rejected. Weekly replenishment makes stock jump upward (e.g.
--       1,754 -> 2,245 on 10 May), producing negative "usage". Worse,
--       once stock hits zero the delta reads 0, implying no demand —
--       but shipments show 150 units still moved on 23 May. That would
--       hide the very problem this query exists to expose.
--
--   (b) Units actually shipped out, from shipments joined to items.
--       Chosen. This measures demand rather than stock movement, which
--       is what a replenishment decision needs.
--
-- Other decisions:
--   - Excluded returns: a return is stock coming back IN, the opposite
--     of usage.
--   - LEFT JOIN on usage so days with no shipment still appear; an
--     inner join would silently drop them and shorten the series.
--   - Date filter applied in the final layer, not the CTEs. The 7-day
--     average for 10 May needs data from 4-10 May; filtering earlier
--     would starve the window and understate early usage.
--   - NULLIF guards against division by zero if average usage is 0.
--
-- Known limitation:
--   ROWS BETWEEN 6 PRECEDING counts 6 ROWS, not 6 calendar days. The
--   3-5 May snapshots are missing (FAULT V1), so the window for 10-11
--   May silently reaches back to 1 May and averages 102.0 instead of
--   127.4. From 12 May onward the values are unaffected. RANGE BETWEEN
--   INTERVAL '6 days' PRECEDING would fix this; I kept ROWS as the
--   conventional reading of "7-day moving average" and noted the gap
--   here instead.
--
-- Result: 16 rows (10-25 May 2026)
--
-- Finding:
--   Days of cover falls from 22.0 on 10 May to 1.9 on 21 May and 0.5 on
--   22 May, hitting zero on 23 May. Stock stayed at zero through 30 May
--   — eight days of stockout on a hero SKU during the free-shipping
--   experiment. Demand did not stop: shipments continued at ~110-150
--   units/day throughout.
--
--   This was visible and preventable. Cover dropped below 7 days on
--   16 May, a full week before the stockout. A daily alert on this
--   metric would have triggered with time to reorder.
--
--   Downstream impact: this stockout is the likely driver of the
--   elevated cancellation rate in variant B, and of the WH-CKR May
--   delay spike investigated in S15.
-- =====================================================

WITH daily_usage AS (
    -- LAYER 1: units shipped out per day for this SKU at this warehouse
    SELECT
        sh.ship_date              AS usage_date,
        SUM(i.qty)                AS units_out
    FROM analytics_staging.stg_order_items  i
    JOIN analytics_staging.stg_shipments    sh  ON i.order_id = sh.order_id
    WHERE sh.warehouse_id = 'WH-CKR'
      AND i.sku_code      = 'KRK-BLD-080'
      AND i.is_return     = false
    GROUP BY sh.ship_date
),

stock_and_usage AS (
    -- LAYER 2: attach daily stock to daily usage, then 7-day moving average
    SELECT
        inv.snapshot_date,
        inv.qty_on_hand,
        u.units_out,
        AVG(u.units_out) OVER (
            ORDER BY inv.snapshot_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )  AS avg_usage_7d
    FROM analytics_staging.stg_inventory_daily  inv
    LEFT JOIN daily_usage  u  ON inv.snapshot_date = u.usage_date
    WHERE inv.warehouse_id = 'WH-CKR'
      AND inv.sku_code     = 'KRK-BLD-080'
)

-- LAYER 3: days of cover, limited to the requested window
SELECT
    snapshot_date,
    qty_on_hand,
    ROUND(avg_usage_7d, 1)                          AS avg_usage_7d,
    ROUND(qty_on_hand / NULLIF(avg_usage_7d, 0), 1) AS days_of_cover
FROM stock_and_usage
WHERE snapshot_date BETWEEN '2026-05-10' AND '2026-05-25'
ORDER BY snapshot_date;