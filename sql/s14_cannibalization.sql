-- =====================================================
-- S14: Cannibalisation check on the Kriuku range
-- =====================================================
-- Question: did the hero SKU's promo lift come from new demand, or from
--   customers switching away from other Kriuku flavours?
--
-- Compared share of quantity, not raw quantity. Everything rises during
--   a promo because the basket grows; only share reveals what moved
--   relative to what. Shares always sum to 100%, so a gain in one SKU has
--   to come out of another.
--
-- Date handling: used >= start AND < next_day rather than BETWEEN.
--   order_ts_wib is a timestamp, so BETWEEN '2026-05-03' would cut the
--   comparison window at midnight and silently drop that whole day.
--
-- Windows: 1 Mar - 3 May (before) vs 4 May - 14 Jun (promo). March was
--   chosen as the start, not January, to keep the comparison close in
--   time and avoid seasonal drift.
--
-- Result: 16 rows.
--
-- Finding: not flavour cannibalisation. All seven non-hero 80g SKUs GAIN
--   share (+0.90 to +1.88pp) alongside the hero (+5.43pp), while all
--   eight 180g SKUs LOSE share (-1.74 to -2.08pp), including
--   KRK-BLD-180, the same flavour as the hero. If customers were
--   switching on flavour, the 180g Balado would have risen too.
--
--   The split is by pack size, and the likely cause is the 50K free
--   shipping threshold. Small packs (Rp5,300-7,400) let shoppers top up
--   a basket to just over Rp50,000 in small steps. Three 180g packs come
--   to only Rp33,600-43,800; four clear the bar for every flavour except
--   KRK-PDM-180, which needs five. Margin per rupiah is about the same
--   for both sizes (around 42%), so the mix shift does not erode margin
--   on its own.
-- =====================================================

WITH kriuku_sales AS (
    -- LAYER 1: Kriuku sales, with the period indicated
    SELECT
        i.sku_code,
        i.qty,
        CASE
            WHEN o.order_ts_wib >= '2026-03-01' AND o.order_ts_wib < '2026-05-04' THEN 'before'
            WHEN o.order_ts_wib >= '2026-05-04' AND o.order_ts_wib < '2026-06-15' THEN 'promo'
        END  AS period
    FROM analytics_staging.stg_order_items  i
    JOIN analytics_staging.stg_orders_d2c   o  ON i.order_id = o.order_id
    JOIN analytics_staging.stg_sku_master   s  ON i.sku_code = s.sku_code
    WHERE s.brand        = 'Kriuku'
      AND i.is_return    = FALSE
      AND o.order_status <> 'cancelled'
),

by_sku AS (
    -- LAYER 2: Total qty per SKU for each period
    SELECT
        sku_code,
        SUM(qty) FILTER (WHERE period = 'before')  AS qty_before,
        SUM(qty) FILTER (WHERE period = 'promo')   AS qty_promo
    FROM kriuku_sales
    WHERE period IS NOT NULL
    GROUP BY sku_code
)

-- LAYER 3: convert to share, calculate the difference
SELECT
    sku_code,
    qty_before,
    qty_promo,
    ROUND(qty_before::numeric / SUM(qty_before) OVER () * 100, 2)  AS share_before_pct,
    ROUND(qty_promo::numeric  / SUM(qty_promo)  OVER () * 100, 2)  AS share_promo_pct,
    ROUND(
        qty_promo::numeric  / SUM(qty_promo)  OVER () * 100
      - qty_before::numeric / SUM(qty_before) OVER () * 100
    , 2)  AS delta_pp
FROM by_sku
ORDER BY delta_pp DESC;
