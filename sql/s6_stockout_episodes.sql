-- =====================================================
-- S6: Stockout episodes lasting 3+ consecutive days
-- =====================================================
-- Question: find every run of zero stock lasting three days or more,
--   and report warehouse, SKU, start date, end date, and duration.
--   Which SKU and which warehouse are not given; the query finds them.
--
-- The problem: SQL has no concept of "consecutive". The data holds 17
--   separate zero-stock rows; management needs two sentences, not 17
--   dates.
--
-- The technique (gaps and islands):
--   For a run of consecutive dates, (date - row_number) is constant,
--   because both increase by 1 each step. The moment a day is skipped,
--   that value jumps, so it works as an automatic group key.
--
--     23 May - 1 = 22 May  |
--     24 May - 2 = 22 May  |  same key -> one island
--     25 May - 3 = 22 May  |
--     28 May - 4 = 24 May  <- gap, new island
--
--   PARTITION BY warehouse_id, sku_code restarts the numbering per
--   SKU per warehouse; without it the sequences would interleave and
--   the keys would be meaningless.
--
-- Decisions:
--   - HAVING, not WHERE, for the 3-day threshold: it filters on
--     COUNT(*), which does not exist until after GROUP BY.
--   - island_key appears in GROUP BY but not in SELECT. It is
--     machinery, not information the reader needs.
--   - qty_on_hand = 0 only. Negative stock was converted to NULL by
--     staging (FAULT V2) and NULL is not zero, so those rows are
--     correctly excluded.
--
-- Known assumption:
--   This technique assumes daily snapshots are never missing. They are:
--   3-5 May have no rows (FAULT V1). An episode spanning those dates
--   would be split into two shorter episodes and could fall below the
--   3-day threshold. Both episodes found here fall in late May, well
--   clear of the gap, so the result holds. The assumption is still
--   worth stating rather than relying on luck.
--
-- Result: 2 rows.
--
-- Finding:
--   Both episodes hit WH-CKR, and both involve the hero SKUs that rank
--   1 and 2 in every warehouse (see S3):
--     SGR-LMN-350  22-30 May  9 days
--     KRK-BLD-080  23-30 May  8 days
--   Together they account for all 17 zero-stock rows; no other SKU ever
--   hit zero.
--
--   S5 shows this was foreseeable: days of cover for KRK-BLD-080 fell
--   below 7 on 17 May, six days before stock hit zero.
--
--   This is the operational failure behind variant B's higher
--   cancellation rate: the two SKUs the free-shipping promo drove
--   demand toward were the two that ran out, at the main warehouse
--   (about 64% of all shipments). The WH-CKR delay spike in the same
--   weeks (S7, S15) is a separate effect: late deliveries hit orders
--   with and without these SKUs equally.
-- =====================================================

WITH zero_days AS (
    SELECT
        warehouse_id,
        sku_code,
        snapshot_date
    FROM analytics_staging.stg_inventory_daily
    WHERE qty_on_hand = 0
),

grouped AS (
    SELECT
        warehouse_id,
        sku_code,
        snapshot_date,
        snapshot_date - (ROW_NUMBER() OVER (
            PARTITION BY warehouse_id, sku_code
            ORDER BY snapshot_date
        ))::int  AS island_key
    FROM zero_days
)

SELECT
    warehouse_id,
    sku_code,
    MIN(snapshot_date)  AS start_date,
    MAX(snapshot_date)  AS end_date,
    COUNT(*)            AS days
FROM grouped
GROUP BY warehouse_id, sku_code, island_key
HAVING COUNT(*) >= 3
ORDER BY days DESC;
