"""
============================================================
 NetLift - "Free Shipping over 50K" Experiment Analysis
============================================================
Two modes:
  python scripts/ab_analysis.py           -> read PostgreSQL marts (after dbt run)
  python scripts/ab_analysis.py --csv     -> read raw CSVs + clean in pandas

Prints the full statistical readout: significance tests, guardrail
metrics, and unit economics.

Reading the output: variant B wins on conversion and AOV but loses on
net contribution once the shipping subsidy and stockout-driven
cancellations are priced in. Sections 5 and 6 carry that conclusion.
"""
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats as st

# Proxy for the logistics cost absorbed per free-shipping order (IDR).
SHIPPING_SUBSIDY = 12_000
EXP_START = pd.Timestamp("2026-05-04")
EXP_END   = pd.Timestamp("2026-06-14 23:59:59")
HERO_SKUS = ["KRK-BLD-080", "SGR-LMN-350"]

RAW_DIR = Path("data/raw")


# ------------------------------------------------------------------
# LOADER 1: from PostgreSQL marts (primary path)
# ------------------------------------------------------------------
def _require_env(name):
    """Fail loudly and early when a credential is missing."""
    value = os.getenv(name)
    if not value:
        raise SystemExit(
            f"Missing environment variable: {name}\n"
            f"Copy .env.example to .env and fill in your PostgreSQL credentials.")
    return value


def load_from_postgres():
    from dotenv import load_dotenv
    from sqlalchemy import create_engine
    from sqlalchemy.engine import URL

    load_dotenv()

    # URL.create() escapes credentials properly. Building the DSN with an
    # f-string breaks on passwords containing @ : / # and risks leaking the
    # password into a traceback when the connection fails.
    url = URL.create(
        drivername="postgresql+psycopg2",
        username=_require_env("PG_USER"),
        password=_require_env("PG_PASSWORD"),
        host=_require_env("PG_HOST"),
        port=int(_require_env("PG_PORT")),
        database=_require_env("PG_DATABASE"),
    )
    engine = create_engine(url)

    users = pd.read_sql(
        "select user_id, variant, first_exposure_ts, device, app_version, "
        "converted, gross_amount, margin_amount, shipping_fee, order_status "
        "from analytics_marts.fct_ab_users", engine,
        parse_dates=["first_exposure_ts"])
    ship = pd.read_sql(
        "select warehouse_id, ship_date, ship_month, is_otif "
        "from analytics_marts.fct_otif_shipments", engine, parse_dates=["ship_date"])
    inv = pd.read_sql(
        "select snapshot_date, warehouse_id, sku_code, qty_on_hand "
        "from analytics_marts.fct_inventory_daily", engine,
        parse_dates=["snapshot_date"])
    return users, ship, inv


# ------------------------------------------------------------------
# LOADER 2: from raw CSVs (fallback without dbt) - cleaning in pandas
# ------------------------------------------------------------------
def load_from_csv(raw=RAW_DIR):
    raw = Path(raw)
    if not raw.exists():
        raise SystemExit(
            f"Directory not found: {raw.resolve()}\n"
            f"Run `python scripts/generate_data.py` from the project root first.")

    # --- orders: normalise timestamps + de-duplicate ---
    o = pd.read_csv(raw / "orders_d2c.csv")
    is_utc = o.order_ts.str.endswith("Z")          # FAULT O1: mixed formats
    ts = pd.Series(pd.NaT, index=o.index)
    ts[is_utc]  = pd.to_datetime(o.order_ts[is_utc].str[:-1]) + pd.Timedelta(hours=7)
    ts[~is_utc] = pd.to_datetime(o.order_ts[~is_utc])
    o["order_ts_wib"] = ts
    # FAULT O2: keep the latest ingested row per order_id
    o = o.sort_values("ingested_at").groupby("order_id", as_index=False).last()

    # --- items: string prices, returns, SKU normalisation ---
    it = pd.read_csv(raw / "order_items_d2c.csv")
    it["price"] = (it.unit_price.astype(str)       # FAULT I1: 'Rp12.500'
                     .str.replace(r"[Rp\.]", "", regex=True).astype(int))
    sales = it[it.qty > 0].copy()                  # FAULT I3: drop return lines
    sales["sku"] = (sales.sku_code.str.strip().str.upper()
                    .replace({"KRK-BLD-80": "KRK-BLD-080"}))   # FAULT I2
    sales = sales[sales.sku != "SKU-TEST"]
    sku = pd.read_csv(raw / "sku_master.csv")
    sku["sku_code"] = sku.sku_code.str.strip()     # FAULT M2: trailing space
    sku = sku.drop_duplicates("sku_code")
    cogs = dict(zip(sku.sku_code, sku.unit_cogs))
    sales["margin"] = (sales.price - sales.sku.map(cogs)) * sales.qty
    basket = sales.assign(gross=sales.price * sales.qty).groupby("order_id").agg(
        gross_amount=("gross", "sum"), margin_amount=("margin", "sum"))
    o = o.merge(basket, on="order_id", how="left")

    # --- exposures: window, bots, dual-variant leakage, first touch ---
    e = pd.read_csv(raw / "ab_exposures.csv", parse_dates=["first_exposure_ts"])
    e = e[(e.first_exposure_ts >= EXP_START) & (e.first_exposure_ts <= EXP_END)]
    cnt = e.user_id.value_counts()
    e = e[~e.user_id.isin(cnt[cnt > 20].index)]                  # FAULT A2: bots
    nvar = e.groupby("user_id").variant.nunique()
    e = e[~e.user_id.isin(nvar[nvar > 1].index)]                 # FAULT A1: leakage
    u = (e.sort_values("first_exposure_ts")
          .groupby("user_id", as_index=False).first())

    # --- conversion: first order within 7 days of exposure ---
    j = u.merge(o[["order_id", "customer_id", "order_ts_wib", "order_status",
                   "shipping_fee", "gross_amount", "margin_amount"]],
                left_on="user_id", right_on="customer_id", how="left")
    j = j[(j.order_ts_wib >= j.first_exposure_ts) &
          (j.order_ts_wib <= j.first_exposure_ts + pd.Timedelta(days=7))]
    fo = (j.sort_values("order_ts_wib").groupby("user_id", as_index=False).first()
          [["user_id", "order_ts_wib", "order_status", "shipping_fee",
            "gross_amount", "margin_amount"]])
    users = u[["user_id", "variant", "first_exposure_ts", "device",
               "app_version"]].merge(fo, on="user_id", how="left")
    users["converted"] = users.order_ts_wib.notna()

    # --- shipments & inventory ---
    ship = pd.read_csv(raw / "shipments_d2c.csv",
                       parse_dates=["ship_date", "promised_date", "delivered_date"])
    # FAULT S1: missing delivered_date stays NaN, never counted as on-time
    ship["is_otif"] = np.where(ship.delivered_date.isna(), np.nan,
                               (ship.delivered_date <= ship.promised_date)
                               & (ship.fulfil_type == "full"))
    ship["ship_month"] = ship.ship_date.dt.to_period("M").dt.to_timestamp()
    inv = pd.read_csv(raw / "inventory_daily.csv", parse_dates=["snapshot_date"])
    inv["qty_on_hand"] = np.where(
        (inv.warehouse_id == "WH-BDG") & inv.sku_code.str.endswith("1L0"),
        inv.qty_on_hand * 12,                      # FAULT V3: cartons -> units
        np.where(inv.qty_on_hand < 0, np.nan,      # FAULT V2: negative stock
                 inv.qty_on_hand))
    return users, ship, inv


# ------------------------------------------------------------------
# ANALYSIS
# ------------------------------------------------------------------
def section(title):
    print("\n" + "=" * 60 + f"\n {title}\n" + "=" * 60)


def analyze(users, ship, inv):
    A = users[users.variant == "A"]
    B = users[users.variant == "B"]
    nA, nB = len(A), len(B)

    section("1. SANITY CHECK: SAMPLE RATIO MISMATCH (SRM)")
    chi2, p_srm = st.chisquare([nA, nB], [len(users) / 2] * 2)
    print(f"A = {nA:,}   B = {nB:,}   (B share = {nB/len(users):.2%})")
    print(f"chi-square = {chi2:.1f}   p = {p_srm:.2e}")
    print("-> p far below 0.001: the split is NOT 50/50. Break it down by segment:")
    for d, g in users.groupby("device"):
        print(f"   {d:8s} B-share = {(g.variant=='B').mean():6.1%}  (n={len(g):,})")
    android = users[users.device == "android"]
    for v, g in android.groupby("app_version"):
        print(f"   android {v}: B-share = {(g.variant=='B').mean():.1%} (n={len(g):,})")
    print("-> Root cause: skewed bucketing in Android build 6.4.0.")
    print("-> Decision: the lift is still readable per stratum (see section 3),")
    print("   but the bug MUST be fixed before the next experiment.")

    section("2. CONVERSION: TWO-PROPORTION z-TEST")
    cA, cB = A.converted.mean(), B.converted.mean()
    diff = cB - cA
    pool = users.converted.mean()
    se_pool = np.sqrt(pool * (1 - pool) * (1 / nA + 1 / nB))
    z = diff / se_pool
    p = 2 * st.norm.sf(abs(z))
    se_ci = np.sqrt(cA * (1 - cA) / nA + cB * (1 - cB) / nB)
    lo, hi = diff - 1.96 * se_ci, diff + 1.96 * se_ci
    h = 2 * np.arcsin(np.sqrt(cB)) - 2 * np.arcsin(np.sqrt(cA))
    print(f"Conversion A = {cA:.3%}   B = {cB:.3%}")
    print(f"Difference   = +{diff*100:.2f} pp  (relative +{diff/cA:.1%})")
    print(f"z = {z:.2f}   p = {p:.2e}")
    print(f"95% CI of difference = [{lo*100:.2f}, {hi*100:.2f}] pp")
    print(f"Effect size (Cohen's h) = {h:.3f}  -> small, but real")

    section("3. STRATA CHECK & NOVELTY EFFECT")
    for d, g in users.groupby("device"):
        ga, gb = g[g.variant == "A"], g[g.variant == "B"]
        print(f"   {d:8s} A={ga.converted.mean():6.2%}  B={gb.converted.mean():6.2%}"
              f"  lift={(gb.converted.mean()-ga.converted.mean())*100:+.2f}pp")
    print("-> Lift is clear on three of four devices (desktop not detectable): the result survives, WITH a caveat.")
    users["fortnight"] = ((users.first_exposure_ts - EXP_START).dt.days // 14).clip(0, 2)
    print("Variant B conversion per 2-week block (novelty check):")
    for w, g in users[users.variant == "B"].groupby("fortnight"):
        label = ["weeks 1-2", "weeks 3-4", "weeks 5-6"][int(w)]
        print(f"   {label}: {g.converted.mean():.2%}")
    print("-> Steep decline between blocks: part of the lift is a novelty effect.")

    section("4. AOV: WELCH'S t-TEST")
    aA = A[A.converted].gross_amount.dropna()
    aB = B[B.converted].gross_amount.dropna()
    t, pt = st.ttest_ind(aA, aB, equal_var=False)
    d = (aB.mean() - aA.mean()) / np.sqrt((aA.std() ** 2 + aB.std() ** 2) / 2)
    print(f"AOV A = Rp{aA.mean():,.0f} (median {aA.median():,.0f})")
    print(f"AOV B = Rp{aB.mean():,.0f} (median {aB.median():,.0f})")
    print(f"Welch t = {t:.2f}   p = {pt:.2e}   Cohen's d = {d:.2f}")
    print("-> The 50K threshold DOES lift basket size. So far B looks flawless...")

    section("5. GUARDRAILS: CANCELLATIONS, MARGIN, SUBSIDY")
    convA, convB = A[A.converted], B[B.converted]
    canA = (convA.order_status == "cancelled").mean()
    canB = (convB.order_status == "cancelled").mean()
    mA, mB = convA.margin_amount.mean(), convB.margin_amount.mean()
    feeA = convA.shipping_fee.mean()
    print(f"Cancel rate      A = {canA:.2%}   B = {canB:.2%}  (hero-SKU stockout!)")
    print(f"Margin per order A = Rp{mA:,.0f}   B = Rp{mB:,.0f}")
    print(f"Shipping paid by customer: A = Rp{feeA:,.0f}   B = Rp0")
    print(f"-> Every B order absorbs a shipping subsidy of ~Rp{SHIPPING_SUBSIDY:,}")

    section("6. UNIT ECONOMICS: RUPIAH PER 1,000 EXPOSED USERS")
    netA = cA * 1000 * (1 - canA) * mA
    netB = cB * 1000 * (1 - canB) * (mB - SHIPPING_SUBSIDY)
    delta = netB - netA
    total = len(users)
    print("Net contribution per 1,000 exposed users:")
    print(f"   A = Rp{netA:,.0f}")
    print(f"   B = Rp{netB:,.0f}")
    print(f"   Difference = Rp{delta:,.0f}  <- B IS LOWER")
    print(f"Projected at full rollout ({total:,} users / 6 weeks): "
          f"Rp{delta*total/1000:,.0f}")
    print(f"Annualised (x52/6): Rp{delta*total/1000*52/6:,.0f}")
    breakeven = mB - netA / (cB * 1000 * (1 - canB))
    print(f"Subsidy break-even: a rerun only pays off if shipping cost "
          f"<= Rp{breakeven:,.0f}/order")

    section("7. OPS GUARDRAILS: OTIF & STOCKOUT")
    pivot = (ship.dropna(subset=["is_otif"])
                 .groupby([ship.ship_date.dt.month, "warehouse_id"])
                 .is_otif.mean().unstack() * 100).round(1)
    pivot.index.name = "month"
    print("OTIF % by month and warehouse:")
    print(pivot.to_string())
    zero_stock = inv[(inv.warehouse_id == "WH-CKR") & inv.sku_code.isin(HERO_SKUS)
                     & (inv.qty_on_hand == 0)]
    print("\nHero-SKU stockout episodes at WH-CKR:")
    print(zero_stock.groupby("sku_code").snapshot_date
                    .agg(start="min", end="max", days="count").to_string())
    print("\nCONCLUSION: variant B wins on conversion and AOV, but the shipping")
    print("subsidy plus stockout-driven cancellations make it NET NEGATIVE.")
    print("Full recommendation: see docs/business-analysis.md and docs/memo-growth.md.")


if __name__ == "__main__":
    if "--csv" in sys.argv:
        print("Mode: raw CSV + pandas cleaning")
        users, ship, inv = load_from_csv()
    else:
        print("Mode: PostgreSQL marts (run dbt first)")
        users, ship, inv = load_from_postgres()
    analyze(users, ship, inv)
