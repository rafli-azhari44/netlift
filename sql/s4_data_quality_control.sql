-- =====================================================
-- S4: One-page data quality report
-- =====================================================
-- Question: combine the Phase 3 profiling findings into ONE result
--   (issue | total) with UNION ALL, covering six checks: duplicate
--   orders, negative qty, string prices, orphan SKUs, missing delivery
--   dates and negative stock. A query like this can run daily as a
--   data quality dashboard.
--
-- Runs against RAW on purpose: staging fixes or removes most of these
--   faults, so the same checks would report zero there and hide the
--   problems one layer down.
--
-- Result: 6 rows.
--   duplicate orders       307   FAULT O2
--   negative qty           250   FAULT I3 (returns)
--   string prices        3,051   FAULT I1
--   orphan SKUs            150   FAULT I2a KRK-BLD-80 (120) and
--                                FAULT I2b SKU-TEST (30)
--   missing delivered    1,672   FAULT S1
--   negative stock          15   FAULT V2
-- =====================================================

SELECT 'duplicate orders'  AS issue,
       COUNT(*) - COUNT(DISTINCT order_id)  AS total
FROM raw.orders_d2c

UNION ALL

SELECT 'negative qty',
       COUNT(*)
FROM raw.order_items_d2c
WHERE qty::int < 0

UNION ALL

SELECT 'string prices',
       COUNT(*)
FROM raw.order_items_d2c
WHERE unit_price LIKE 'Rp%'

UNION ALL

SELECT 'orphan SKUs',
       COUNT(*)
FROM raw.order_items_d2c
WHERE sku_code NOT IN (SELECT sku_code FROM raw.sku_master)

UNION ALL

SELECT 'missing delivered',
       COUNT(*)
FROM raw.shipments_d2c
WHERE delivered_date IS NULL OR delivered_date = ''

UNION ALL

SELECT 'negative stock',
       COUNT(*)
FROM raw.inventory_daily
WHERE qty_on_hand::int < 0;
