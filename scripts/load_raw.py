"""Loader idempoten: TRUNCATE and then refill all raw tables from CSV."""
import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()
engine = create_engine(
    f"postgresql+psycopg2://{os.getenv('PG_USER')}:{os.getenv('PG_PASSWORD')}"
    f"@{os.getenv('PG_HOST')}:{os.getenv('PG_PORT')}/{os.getenv('PG_DATABASE')}")

TABLES = ["sku_master", "distributors", "customers_d2c", "ab_exposures",
          "orders_d2c", "order_items_d2c", "shipments_d2c", "inventory_daily",
          "sales_b2b", "production_batches", "bom"]

for t in TABLES:
    df = pd.read_csv(f"data/raw/{t}.csv", dtype=str, keep_default_na=False)
    with engine.begin() as con:
        con.execute(text(f"TRUNCATE raw.{t}"))
    df.to_sql(t, engine, schema="raw", if_exists="append",
              index=False, chunksize=5000)
    print(f"  raw.{t:22s} {len(df):>8,} rows loaded")

print("\nDone. This loader is safe to re-run (idempotent).")
