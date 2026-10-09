-- =====================================================
-- S2: Monthly revenue pivot by brand
-- =====================================================
-- Question: show monthly revenue split across the three brands, with
--   months as rows and brands as columns.
--
-- Exclusions:
--   - Return lines (qty < 0, FAULT I3) would wrongly reduce revenue.
--   - Cancelled orders produce no revenue.
--
-- Why staging instead of raw: the staging layer already fixes the
--   string prices ('Rp12.500', FAULT I1), the mis-padded SKU code
--   (FAULT I2a), the SKU-TEST rows (FAULT I2b) and the webhook
--   duplicates (FAULT O2).
--
-- Revenue uses unit_price (what the customer paid), not list_price.
--
-- Result: 6 rows (Jan-Jun 2026).
--
-- Observation: from April to May, Kriuku revenue rises 60% and Segarin
--   62%, while Renyahku rises only 14%. The jump lines up with the
--   free-shipping experiment window (4 May - 14 Jun).
-- =====================================================

SELECT
    DATE_TRUNC('month', o.order_ts_wib)                           AS month,
    SUM(i.qty * i.unit_price) FILTER (WHERE s.brand = 'Kriuku')    AS Kriuku,
    SUM(i.qty * i.unit_price) FILTER (WHERE s.brand = 'Segarin')   AS Segarin,
    SUM(i.qty * i.unit_price) FILTER (WHERE s.brand = 'Renyahku')  AS Renyahku
FROM analytics_staging.stg_orders_d2c   o
JOIN analytics_staging.stg_order_items  i  ON o.order_id = i.order_id
JOIN analytics_staging.stg_sku_master   s  ON i.sku_code = s.sku_code
WHERE i.is_return = false
  AND o.order_status != 'cancelled'
GROUP BY 1
ORDER BY 1;
