-- =====================================================
-- S8: ABC classification of the SKU catalogue
-- =====================================================
-- Question: classify all 40 SKUs by revenue contribution. Class A
--   covers the first 80% of cumulative revenue, B up to 95%, C the
--   rest. Which SKUs fall where is what the query finds; only the two
--   thresholds come from the question.
--
-- Why it matters: ops cannot watch 40 SKUs with equal attention. ABC
--   tells them where to spend it: class A items should never run out.
--
-- Decisions:
--   - Excluded returns and cancelled orders, same as S2. Both would
--     inflate or deflate revenue without reflecting money earned.
--   - Ranked by revenue, not quantity. A SKU can sell many units at a
--     low price; revenue is what the classification is meant to
--     protect. Units are shown next to revenue so the two can be
--     compared (Finding 2).
--   - SUM(revenue) OVER (ORDER BY revenue DESC) gives the running
--     total; SUM(revenue) OVER () with an empty window gives the grand
--     total, repeated on every row, so the ratio works per row.
--   - Cast to numeric before dividing. Integer division would have
--     returned 0 for every cum_pct and put all 40 SKUs in class A.
--   - Classification lives in its own layer: cum_pct is created in the
--     SELECT of the CTE, so CASE cannot reference it there.
--
-- Result: 40 rows: 28 class A, 8 class B, 4 class C.
--
-- Finding 1: the catalogue does not follow Pareto.
--   Classic ABC expects ~20% of SKUs to drive 80% of revenue. Here it
--   takes 28 of 40 SKUs (70%) to reach 80%. The top SKU contributes
--   only 3.7% of total revenue, and the weakest still contributes 1.4%,
--   a spread of just 2.7x between best and worst.
--
--   Implication: there is no small set of critical SKUs to protect.
--   Ops cannot narrow their attention the way ABC is supposed to allow.
--   Dropping class C would not simplify much either: those four SKUs
--   still carry about 5.7% of revenue between them.
--
--   Worth flagging to the team: a flat revenue curve can mean a
--   balanced portfolio, or that no product has had the marketing
--   support to break away.
--
-- Finding 2: volume and value point in opposite directions.
--   The small packs (80g Kriuku, 350ml Segarin) sell more units than
--   the other formats (about 6,500-7,000 each versus 5,300-5,800), yet
--   they sit at the bottom of the revenue list: 14 of the last 16
--   places, and all four class C SKUs are 350ml Segarin. Ranks 3-24 are
--   all 180g Kriuku, 1L Segarin or 150g Renyahku.
--
--   So warehouse slotting (S3, driven by quantity) and commercial
--   priority (this query, driven by revenue) should not be confused.
--
-- Finding 3: the promo SKUs.
--   KRK-BLD-080 and SGR-LMN-350 are the exception to Finding 2: small
--   packs that rank 1 and 2 by revenue on sheer volume (about 15,600
--   units each). They are the same two SKUs that ran out of stock at
--   WH-CKR in late May (S6), so the stockout hit the two
--   highest-revenue items in the catalogue.
-- =====================================================

WITH sku_revenue AS (
    -- LAYER 1: units and revenue per SKU
    SELECT
        i.sku_code,
        SUM(i.qty)                 AS units,
        SUM(i.qty * i.unit_price)  AS revenue
    FROM analytics_staging.stg_order_items  i
    JOIN analytics_staging.stg_orders_d2c   o  ON i.order_id = o.order_id
    WHERE i.is_return = false
      AND o.order_status <> 'cancelled'
    GROUP BY i.sku_code
),

cumulative AS (
    -- LAYER 2: running total and its share of the grand total
    SELECT
        sku_code,
        units,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC)              AS cum_revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC)::numeric
            / SUM(revenue) OVER ()                             AS cum_pct
    FROM sku_revenue
)

-- LAYER 3: classification
SELECT
    sku_code,
    units,
    revenue,
    ROUND(cum_pct * 100, 1)  AS cum_pct,
    CASE
        WHEN cum_pct <= 0.80 THEN 'A'
        WHEN cum_pct <= 0.95 THEN 'B'
        ELSE 'C'
    END  AS abc_class
FROM cumulative
ORDER BY revenue DESC;
