-- =====================================================
-- S8: ABC classification of the SKU catalogue
-- =====================================================
-- Question: classify all 40 SKUs by revenue contribution. Class A
--   covers the first 80% of cumulative revenue, B up to 95%, C the
--   rest. Which SKUs fall where is what the query finds; only the two
--   thresholds come from the question.
--
-- Why it matters: ops cannot watch 40 SKUs with equal attention. ABC
--   tells them where to spend it — class A items should never run out.
--
-- Decisions:
--   - Excluded returns and cancelled orders, same as S2. Both would
--     inflate or deflate revenue without reflecting money earned.
--   - Ranked by revenue, not quantity. A SKU can sell many units at a
--     thin margin; revenue is what the classification is meant to
--     protect.
--   - SUM(revenue) OVER (ORDER BY revenue DESC) gives the running
--     total; SUM(revenue) OVER () with an empty window gives the grand
--     total, repeated on every row, so the ratio works per row.
--   - Cast to numeric before dividing. Integer division would have
--     returned 0 for every cum_pct and put all 40 SKUs in class A.
--   - Classification lives in its own layer: cum_pct is created in the
--     SELECT of the CTE, so CASE cannot reference it there.
--
-- Result: 40 rows — 28 class A, 8 class B, 4 class C
--
-- Finding 1 — the catalogue does not follow Pareto:
--   Classic ABC expects ~20% of SKUs to drive 80% of revenue. Here it
--   takes 28 of 40 SKUs (70%) to reach 80%. The top SKU contributes
--   only 3.7% of total revenue, and the weakest still contributes 1.4%
--   — a spread of just 2.7x between best and worst.
--
--   Implication: there is no small set of critical SKUs to protect.
--   Ops cannot narrow their attention the way ABC is supposed to allow.
--   It also means dropping class C items would save little; those four
--   SKUs still carry ~4% of revenue between them.
--
--   Worth flagging to the team: a flat revenue curve is either a very
--   balanced portfolio or a sign that no product has been given the
--   marketing support to break away.
--
-- Finding 2 — pack size drives revenue, not units:
--   Large formats (-180, -1L0) dominate the top of the list; the small
--   350ml variants fill class C entirely. But S3 showed SGR-LMN-350 is
--   the single best seller by quantity at every warehouse.
--
--   So the highest-volume SKU sits in class C by revenue. Volume and
--   value point in opposite directions here, and warehouse slotting
--   (S3, driven by quantity) should not be confused with commercial
--   priority (this query, driven by revenue).
--
-- Finding 3 — the promo SKUs:
--   KRK-BLD-080 and SGR-LMN-350 rank 1 and 2 by revenue, and are the
--   same two SKUs that ran out of stock at WH-CKR in late May (S6).
--   The stockout hit the two highest-revenue items in the catalogue.
-- =====================================================

WITH sku_revenue AS (
    -- LAYER 1
    SELECT
        i.sku_code,
        SUM(i.qty * i.unit_price)  AS revenue
    FROM analytics_staging.stg_order_items  i
    JOIN analytics_staging.stg_orders_d2c   o  ON i.order_id = o.order_id
    WHERE i.is_return = false
      AND o.order_status <> 'cancelled'
    GROUP BY i.sku_code
),

cumulative AS (
    -- LAYER 2
    SELECT
        sku_code,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC)              AS cum_revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC)::numeric
            / SUM(revenue) OVER ()                             AS cum_pct
    FROM sku_revenue
)

-- LAYER 3
SELECT
    sku_code,
    revenue,
    ROUND(cum_pct * 100, 1)  AS cum_pct,
    CASE
        WHEN cum_pct <= 0.80 THEN 'A'
        WHEN cum_pct <= 0.95 THEN 'B'
        ELSE 'C'
    END  AS abc_class
FROM cumulative
ORDER BY revenue DESC;