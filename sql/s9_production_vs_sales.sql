-- =====================================================
-- S9: Production versus sales, per SKU per month
-- =====================================================
-- Question: compare net-of-defect production against total sales
--   (D2C + B2B) for every SKU in every month.
--
-- Three sources, three different layers:
--   - production_batches and sales_b2b have NO staging model, so they
--     come from raw: every column is text and needs an explicit cast.
--   - D2C sales come from staging, where types are already correct.
--
-- FAULT B1 handling (this is the trap in the question):
--   In sales_b2b, 17 rows from DST-03 on 9 March appear twice, identical
--   in every column (34 rows in total). Left in, B2B volume reads
--   5,535,000 pcs instead of 5,508,708: an inflation of 26,292 units
--   concentrated in a single month for a single distributor. Removed
--   with SELECT DISTINCT inside the CTE. DISTINCT is safe here precisely
--   because the duplicates are identical; if they had differed in any
--   column I would have needed a dedup rule instead.
--
-- Why FULL JOIN and not JOIN:
--   Only 15 of 40 SKUs have any production record at all. The other 25
--   sell from existing stock with no batch logged in this period. An
--   inner join would have silently dropped 150 of 240 rows (62.5% of
--   the answer), and every one of those rows is a real business fact.
--   COALESCE on the join keys is required for the same reason: when a
--   row exists on one side only, the other side's sku_code and month
--   come back NULL.
--
-- Other decisions:
--   - Excluded returns and cancelled orders from D2C, consistent with
--     S2 and S8.
--   - Sales combined in their own layer before meeting production, so
--     each FULL JOIN handles one mismatch at a time. Joining all three
--     at once would have made the COALESCE chains hard to reason about.
--
-- Result: 240 rows (40 SKUs x 6 months).
--
-- Finding 1: production covers only part of the catalogue.
--   15 SKUs are produced in-house; 25 are not produced at all during
--   Jan-Jun. The produced set is almost entirely Kriuku (14 of 16 KRK
--   SKUs) plus SGR-LMN-350. KRK-DJR in both sizes is the exception: it
--   sells but is never produced.
--
--   This looks like the shape of the business rather than a data
--   error: the plant runs the snack line and one beverage SKU, and the
--   rest of the Segarin and Renyahku range is presumably sourced or
--   co-packed. Worth confirming with the supply chain team rather than
--   assuming.
--
-- Finding 2: production far exceeds recorded sales.
--   Over six months, net production of these 15 SKUs (after defects)
--   is about 6x their combined B2B and D2C sales (4.7x-8.9x by SKU).
--   One example: KRK-BLD-080 in January nets 343,342 units produced
--   against 32,633 sold.
--
--   Units do not explain it. B2B is already recorded in pieces
--   (qty_pcs), and if production were logged in cases the true gap
--   would be even larger. If the figures are right, stock is piling up
--   faster than any channel in this data can sell it, which would tie
--   up serious working capital.
--
--   I cannot settle this from the data alone. It is a question for
--   Mbak Sinta (how is qty_produced recorded?) and for the supply chain
--   team (where does the output go?) before anyone acts on the gap
--   figure.
--
-- Finding 3: two distinct sales channels.
--   15 SKUs have zero B2B sales and reach customers only through D2C:
--   the entire Renyahku range plus seven Segarin SKUs (APL, CCO and GVA
--   in both sizes, and SGR-MKS-1L0). Distributors carry the full Kriuku
--   line and the other nine Segarin SKUs.
--
-- Open question worth raising:
--   KRK-BLD-080 and SGR-LMN-350 are the two SKUs that ran out at WH-CKR
--   in late May (S6), yet both show large positive production gaps that
--   month. If the production figures are right, stock existed somewhere
--   but not at the warehouse that needed it. That points at
--   distribution, not production capacity.
-- =====================================================

WITH production AS (
    -- LAYER 1a: net-of-defect production per SKU per month
    SELECT
        sku_code,
        DATE_TRUNC('month', prod_date::date)        AS month,
        SUM(qty_produced::int - qty_defect::int)    AS qty_produced_net
    FROM raw.production_batches
    GROUP BY 1, 2
),

b2b AS (
    -- LAYER 1b: B2B sales, FAULT B1 duplicates removed
    SELECT
        sku_code,
        DATE_TRUNC('month', order_date::date)       AS month,
        SUM(qty_pcs::int)                           AS qty_b2b
    FROM (SELECT DISTINCT * FROM raw.sales_b2b) s
    GROUP BY 1, 2
),

d2c AS (
    -- LAYER 1c: D2C sales
    SELECT
        i.sku_code,
        DATE_TRUNC('month', o.order_ts_wib)         AS month,
        SUM(i.qty)                                  AS qty_d2c
    FROM analytics_staging.stg_order_items  i
    JOIN analytics_staging.stg_orders_d2c   o  ON i.order_id = o.order_id
    WHERE i.is_return = false
      AND o.order_status <> 'cancelled'
    GROUP BY 1, 2
),

sales AS (
    -- LAYER 2: D2C and B2B combined
    SELECT
        COALESCE(d.sku_code, b.sku_code)  AS sku_code,
        COALESCE(d.month,    b.month)     AS month,
        COALESCE(d.qty_d2c, 0)            AS qty_d2c,
        COALESCE(b.qty_b2b, 0)            AS qty_b2b
    FROM d2c  d
    FULL JOIN b2b  b  ON d.sku_code = b.sku_code AND d.month = b.month
)

-- LAYER 3: production vs sales
SELECT
    COALESCE(p.sku_code, s.sku_code)     AS sku_code,
    COALESCE(p.month,    s.month)        AS month,
    COALESCE(p.qty_produced_net, 0)      AS produced_net,
    COALESCE(s.qty_d2c, 0)               AS sold_d2c,
    COALESCE(s.qty_b2b, 0)               AS sold_b2b,
    COALESCE(s.qty_d2c, 0) + COALESCE(s.qty_b2b, 0)  AS sold_total,
    COALESCE(p.qty_produced_net, 0)
        - (COALESCE(s.qty_d2c, 0) + COALESCE(s.qty_b2b, 0))  AS gap
FROM production  p
FULL JOIN sales  s  ON p.sku_code = s.sku_code AND p.month = s.month
ORDER BY sku_code, month;
