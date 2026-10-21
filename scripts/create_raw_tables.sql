-- =====================================================
-- Raw layer: schema and 11 tables
-- =====================================================
-- Run this once against an empty nusarasa_dw database, before
--   scripts/load_raw.py. The loader truncates and refills these
--   tables, so they must exist first.
--
-- Every column is TEXT on purpose. The raw layer keeps each CSV
--   exactly as delivered, faults included, and all typing and
--   cleaning happens in the dbt staging models.
--
-- Safe to run again: IF NOT EXISTS leaves existing tables untouched.
--
-- How to run:
--   DBeaver: File > Open File..., make nusarasa_dw the active
--     database, then press Alt+X to run the whole script.
--   psql:    psql -U postgres -d nusarasa_dw -f scripts/create_raw_tables.sql
-- =====================================================

CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.sku_master (
    sku_code TEXT, sku_name TEXT, brand TEXT, category TEXT,
    pack_size TEXT, unit_cogs TEXT, list_price TEXT,
    launch_date TEXT, status TEXT);

CREATE TABLE IF NOT EXISTS raw.distributors (
    dist_id TEXT, dist_name TEXT, area TEXT, credit_limit TEXT);

CREATE TABLE IF NOT EXISTS raw.customers_d2c (
    customer_id TEXT, signup_date TEXT, city TEXT, acq_channel TEXT);

CREATE TABLE IF NOT EXISTS raw.ab_exposures (
    exposure_id TEXT, user_id TEXT, variant TEXT,
    first_exposure_ts TEXT, device TEXT, app_version TEXT);

CREATE TABLE IF NOT EXISTS raw.orders_d2c (
    order_id TEXT, customer_id TEXT, order_ts TEXT, channel TEXT,
    payment_method TEXT, shipping_fee TEXT, dest_city TEXT,
    order_status TEXT, ingested_at TEXT);

CREATE TABLE IF NOT EXISTS raw.order_items_d2c (
    item_id TEXT, order_id TEXT, sku_code TEXT, qty TEXT, unit_price TEXT);

CREATE TABLE IF NOT EXISTS raw.shipments_d2c (
    shipment_id TEXT, order_id TEXT, warehouse_id TEXT, courier TEXT,
    ship_date TEXT, promised_date TEXT, delivered_date TEXT,
    fulfil_type TEXT, dest_city TEXT);

CREATE TABLE IF NOT EXISTS raw.inventory_daily (
    snapshot_date TEXT, warehouse_id TEXT, sku_code TEXT, qty_on_hand TEXT);

CREATE TABLE IF NOT EXISTS raw.sales_b2b (
    order_id TEXT, dist_id TEXT, order_date TEXT, sku_code TEXT,
    qty_pcs TEXT, unit_price TEXT);

CREATE TABLE IF NOT EXISTS raw.production_batches (
    batch_id TEXT, prod_date TEXT, line_id TEXT, sku_code TEXT,
    qty_produced TEXT, qty_defect TEXT);

CREATE TABLE IF NOT EXISTS raw.bom (
    parent_code TEXT, component_code TEXT, component_name TEXT,
    qty_per_unit TEXT, uom TEXT);
