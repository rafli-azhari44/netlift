-- =====================================================
-- S3: Top 3 SKUs per warehouse
-- =====================================================
-- Question: ops needs the three best-selling SKUs in each warehouse,
--   measured by shipped quantity, to plan warehouse slotting (fast
--   movers go closest to the picking area).
--
-- Decisions:
--   - Excluded return lines (is_return). Returns carry negative qty,
--     which would quietly deflate the totals.
--   - Used RANK() as the question asks. Note the trade-off: on a tie at
--     position 3, RANK() returns more than 3 rows for that warehouse.
--     If ops needs exactly 3 slots, ROW_NUMBER() would be the safer
--     choice. No tie reaches the top 3 in the current data.
--   - Joined via shipments, not orders. Warehouse is only recorded at
--     shipment level, so cancelled orders (never shipped) drop out on
--     their own. That is correct here: unshipped units occupy no slot.
--
-- Result: 9 rows (3 warehouses x top 3).
--
-- Observations:
--   - WH-CKR dwarfs the others: 11,442 units for its top SKU versus
--     2,311 at WH-BDG and 1,634 at WH-TGR. Cikarang is the primary
--     warehouse, with about 64% of all shipments.
--   - The same two hero SKUs (SGR-LMN-350, KRK-BLD-080) take positions
--     1 and 2 in all three warehouses.
--   - Position 3 differs per warehouse (WH-BDG KRK-PDM-080, WH-CKR
--     SGR-APL-350, WH-TGR KRK-RLA-080), so slotting should not be
--     standardised nationally. This is why ops asked for a
--     per-warehouse breakdown.
--   - Sharp cliff at WH-CKR: ranks 1-2 sit near 11,400 units, rank 3
--     drops to 4,427. Demand at the main warehouse is concentrated on
--     the two hero SKUs, the same pair that ran out of stock in late
--     May (S6).
-- =====================================================

WITH qty_per_warehouse_sku AS (
    -- Step 1: total shipped quantity per SKU per warehouse
    SELECT
        sh.warehouse_id,
        i.sku_code,
        SUM(i.qty)  AS total_qty
    FROM analytics_staging.stg_order_items  i
    JOIN analytics_staging.stg_shipments    sh  ON i.order_id = sh.order_id
    WHERE i.is_return = false
    GROUP BY sh.warehouse_id, i.sku_code
),

ranked_sku AS (
    -- Step 2: rank within each warehouse; PARTITION BY restarts the
    -- numbering per warehouse instead of ranking globally
    SELECT
        warehouse_id,
        sku_code,
        total_qty,
        RANK() OVER (
            PARTITION BY warehouse_id
            ORDER BY total_qty DESC
        )  AS sales_rank
    FROM qty_per_warehouse_sku
)

-- Step 3: keep the top 3. This filter needs its own layer because
-- WHERE runs before SELECT, so sales_rank does not exist yet inside
-- the CTE above.
SELECT
    warehouse_id,
    sku_code,
    total_qty,
    sales_rank
FROM ranked_sku
WHERE sales_rank <= 3
ORDER BY warehouse_id, sales_rank;
