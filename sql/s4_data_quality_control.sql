-- =====================================================
-- S4: One-page data quality report
-- =====================================================
-- Runs against RAW on purpose: staging fixes or removes most of these
-- faults, so the same checks would report zero there and hide the
-- problems one layer down.
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