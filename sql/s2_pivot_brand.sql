-- =====================================================
-- S2: Monthly revenue pivot by brand
-- =====================================================
-- Question: show monthly revenue split across the three brands,
--   with months as rows and brands as columns.
--
-- Exclusions:
--   - return lines (qty < 0, FAULT I3) would wrongly reduce revenue
--   - cancelled orders produce no revenue
--
-- Why staging, instead of raw: the staging layer already fixes string prices
--   ('Rp12.500'), mis-padded SKUs, and webhook duplicates.
--
-- Result: 6 rows (Jan-Jun 2026)
-- Observation: Kriuku jumps ~60% in May, matching the free-shipping
--   experiment window (4 May - 14 Jun).
-- =====================================================

-- S2: Monthly revenue pivot by brand
-- Rows = month, columns = Kriuku / Segarin / Renyahku, values = revenue.
-- Excludes return lines and cancelled orders.

SELECT 
	DATE_TRUNC('month', o.order_ts_wib)									AS month,
	SUM(i.qty * i.unit_price) FILTER (WHERE s.brand = 'Kriuku')			AS Kriuku,
	SUM(i.qty * i.unit_price) FILTER (WHERE s.brand = 'Segarin')		AS Segarin,
	SUM(i.qty * i.unit_price) FILTER (WHERE s.brand = 'Renyahku')		AS Renyahku
FROM analytics_staging.stg_orders_d2c   o										
JOIN analytics_staging.stg_order_items  i  ON o.order_id = i.order_id	
JOIN analytics_staging.stg_sku_master   s  ON i.sku_code = s.sku_code
WHERE i.is_return = false
  AND o.order_status != 'cancelled'
GROUP BY 1
ORDER BY 1;

-- Note: revenue uses unit_price (what the customer paid), not list_price.