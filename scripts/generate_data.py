"""
============================================================
 NetLift - Synthetic Data Generator
 PT Nusa Rasa Abadi (fictional) - FMCG Cikarang + D2C TokoRia
============================================================
Builds an intentionally "dirty" dataset for the NetLift portfolio
project. Every value is deterministic (seed=42), so the output on
any machine matches the documentation exactly.

Run    :  python scripts/generate_data.py   (from the project root)
Output :  data/raw/ containing 11 CSV files

Data-quality faults are injected on purpose and tagged with a
`FAULT <id>` comment. Each one mirrors a failure mode seen in real
production pipelines; the dbt models and ab_analysis.py are expected
to detect and handle them.

Naming convention: code is English, but business entities (brands,
product names, cities, couriers, payment providers) stay Indonesian
because they are the fictional company's real-world domain.
"""

import numpy as np
import pandas as pd
from pathlib import Path
from datetime import datetime, timedelta

rng = np.random.default_rng(42)
OUT = Path("data/raw")
OUT.mkdir(parents=True, exist_ok=True)

# ------------------------------------------------------------
# 0. SCENARIO CONSTANTS
# ------------------------------------------------------------
PERIOD_START = datetime(2026, 1, 1)
PERIOD_END   = datetime(2026, 6, 30)
EXP_START    = datetime(2026, 5, 4)    # "free shipping over 50K" experiment
EXP_END      = datetime(2026, 6, 14)   # 6-week run
FREESHIP_MIN = 50_000

WAREHOUSES = ["WH-CKR", "WH-BDG", "WH-TGR"]
CITIES = ["Bekasi", "Cikarang", "Jakarta Timur", "Bandung",
          "Tangerang", "Depok", "Bogor", "Karawang"]
JABODETABEK = {"Bekasi", "Cikarang", "Jakarta Timur", "Tangerang", "Depok", "Bogor"}

HERO_SKUS = ["KRK-BLD-080", "SGR-LMN-350"]   # the two best-selling SKUs

def days(n): return timedelta(days=int(n))

# ------------------------------------------------------------
# 1. SKU MASTER (40 SKUs + master-data faults)
# ------------------------------------------------------------
kriuku_flavors  = [("BLD","Balado"),("ORI","Original"),("KJU","Keju"),
                   ("RLA","Rumput Laut"),("SPG","Sapi Panggang"),("PDM","Pedas Manis"),
                   ("JGB","Jagung Bakar"),("DJR","Daun Jeruk")]
segarin_flavors = [("LMN","Lemon"),("LCI","Leci"),("JRK","Jeruk"),
                   ("TMJ","Teh Melati"),("MKS","Markisa"),("GVA","Guava"),
                   ("APL","Apel"),("CCO","Coco")]
renyahku_items  = [("CKL","Cokelat"),("VNL","Vanila"),("KLP","Kelapa"),("SUS","Susu"),
                   ("GRN","Green Tea"),("KOP","Kopi"),("STR","Stroberi"),("MDU","Madu")]

skus = []
for code, name in kriuku_flavors:
    for size, cogs_rng in [("080",(3300,4300)),("180",(6800,8400))]:
        cogs = int(rng.integers(*cogs_rng))
        skus.append(dict(sku_code=f"KRK-{code}-{size}", sku_name=f"Kriuku {name} {int(size)}g",
                         brand="Kriuku", category="Snack",
                         pack_size=f"{int(size)}g", unit_cogs=cogs,
                         list_price=int(round(cogs*rng.uniform(1.55,1.85),-2)),
                         launch_date="2023-03-01", status="active"))
for code, name in segarin_flavors:
    for size, cogs_rng in [("350",(2700,3500)),("1L0",(6300,7900))]:
        cogs = int(rng.integers(*cogs_rng))
        label = "350ml" if size=="350" else "1L"
        skus.append(dict(sku_code=f"SGR-{code}-{size}", sku_name=f"Segarin {name} {label}",
                         brand="Segarin", category="Beverage",
                         pack_size=label, unit_cogs=cogs,
                         list_price=int(round(cogs*rng.uniform(1.55,1.85),-2)),
                         launch_date="2022-08-01", status="active"))
for code, name in renyahku_items:
    cogs = int(rng.integers(4800, 8600))
    skus.append(dict(sku_code=f"RNK-{code}-150", sku_name=f"Renyahku {name} 150g",
                     brand="Renyahku", category="Biscuit",
                     pack_size="150g", unit_cogs=cogs,
                     list_price=int(round(cogs*rng.uniform(1.55,1.85),-2)),
                     launch_date="2024-02-01", status="active"))

sku_df = pd.DataFrame(skus)
# FAULT M1: SKU marked discontinued but still being sold
sku_df.loc[sku_df.sku_code=="SGR-APL-350", "status"] = "discontinued"
# FAULT M2: duplicate row carrying a trailing space and a lowercased name
dup_row = sku_df[sku_df.sku_code=="KRK-BLD-080"].copy()
dup_row["sku_code"] = "KRK-BLD-080 "
dup_row["sku_name"] = "kriuku balado 80g"
sku_df = pd.concat([sku_df, dup_row], ignore_index=True)
# FAULT M3: inconsistent brand casing (5 rows)
idx = rng.choice(sku_df.index[:40], 5, replace=False)
sku_df.loc[idx, "brand"] = sku_df.loc[idx, "brand"].str.lower()

PRICE  = dict(zip(sku_df.sku_code.str.strip(), sku_df.list_price))
COGS   = dict(zip(sku_df.sku_code.str.strip(), sku_df.unit_cogs))
ALL_SKUS   = [s for s in sku_df.sku_code.str.strip().unique()]
CHEAP_SKUS = [s for s in ALL_SKUS if s.endswith(("080","350"))]

# ------------------------------------------------------------
# 2. DISTRIBUTORS & CUSTOMERS
# ------------------------------------------------------------
dist_df = pd.DataFrame([
    dict(dist_id=f"DST-{i:02d}", dist_name=n, area=a,
         credit_limit=int(rng.integers(15,60))*10_000_000)
    for i,(n,a) in enumerate([
        ("PT Maju Sentosa Distribusi","Bekasi"),("CV Berkah Niaga","Cikarang"),
        ("PT Tirta Kencana","Jakarta Timur"),("PT Sinar Jaya Abadi","Bandung"),
        ("CV Karya Mandiri","Tangerang"),("PT Delta Prima","Karawang"),
        ("PT Lestari Utama","Depok"),("CV Griya Pangan","Bogor")], start=1)
])

N_CUST = 12_000
cust_df = pd.DataFrame(dict(
    customer_id=[f"C{i:05d}" for i in range(1, N_CUST+1)],
    signup_date=[(PERIOD_START - days(rng.integers(0, 730))).strftime("%Y-%m-%d")
                 for _ in range(N_CUST)],
    city=rng.choice(CITIES, N_CUST, p=[.20,.16,.15,.12,.13,.09,.08,.07]),
    acq_channel=rng.choice(["organic","ads_meta","ads_tiktok","referral"],
                           N_CUST, p=[.38,.30,.22,.10]),
))
# FAULT C1: misspelled city names (~1.5% of rows)
typos = {"Bekasi":["Bekasii","BEKASI","bekasi"],
         "Cikarang":["Cikarang ","CIKARANG"],
         "Bandung":["bandung","Bandng"]}
for i in rng.choice(cust_df.index, int(N_CUST*0.015), replace=False):
    c = cust_df.at[i,"city"]
    if c in typos:
        cust_df.at[i,"city"] = str(rng.choice(typos[c]))

# ------------------------------------------------------------
# 3. A/B EXPOSURES (SRM bug, bots, leakage, pre-window rows)
# ------------------------------------------------------------
N_USERS   = 67_000
N_EXP_CUST = 8_500          # existing customers active during the experiment
user_ids = ([f"C{int(i):05d}" for i in rng.choice(np.arange(1,N_CUST+1),
                                                  N_EXP_CUST, replace=False)]
            + [f"V{i:05d}" for i in range(1, N_USERS-N_EXP_CUST+1)])
rng.shuffle(user_ids)

devices = rng.choice(["android","ios","mweb","desktop"], N_USERS, p=[.35,.18,.32,.15])
app_ver = np.where(devices=="android",
                   rng.choice(["6.3.2","6.4.0"], N_USERS, p=[.40,.60]), "")
# SRM BUG: Android build 6.4.0 skews bucketing toward variant B
p_B = np.where((devices=="android") & (app_ver=="6.4.0"), 0.63,
      np.where(devices=="android", 0.50, 0.50))
variants = np.where(rng.random(N_USERS) < p_B, "B", "A")

exp_span = int((EXP_END - EXP_START).total_seconds()) - 3600
def rand_exp_ts(n):
    secs = rng.integers(0, exp_span, n)
    hours = rng.choice(range(8,23), n, p=np.array([3,4,5,6,6,7,7,7,8,8,9,9,8,7,6])/100)
    base = [EXP_START + timedelta(seconds=int(s)) for s in secs]
    return [b.replace(hour=int(h), minute=int(rng.integers(0,60)),
                      second=int(rng.integers(0,60))) for b,h in zip(base,hours)]

exp_rows = pd.DataFrame(dict(user_id=user_ids, variant=variants,
                             first_exposure_ts=rand_exp_ts(N_USERS),
                             device=devices, app_version=app_ver))

# FAULT A1: 450 users leak into both variants (they switched device)
leak = exp_rows.sample(450, random_state=7).copy()
leak["variant"] = np.where(leak.variant=="A","B","A")
leak["first_exposure_ts"] = leak.first_exposure_ts + pd.to_timedelta(
    rng.integers(1,5,len(leak)), unit="D")
leak["device"] = "mweb"; leak["app_version"] = ""
# FAULT A2: 7 bots with hundreds of exposures and zero conversions
bots = pd.DataFrame([dict(user_id=f"V9{j:04d}", variant=rng.choice(["A","B"]),
                          first_exposure_ts=t, device="mweb", app_version="")
                     for j in range(1,8) for t in rand_exp_ts(120)])
# FAULT A3: 300 log rows leaked in BEFORE the experiment started
pre = pd.DataFrame(dict(
    user_id=[f"V8{j:04d}" for j in range(1,301)],
    variant=rng.choice(["A","B"], 300),
    first_exposure_ts=[EXP_START - days(rng.integers(4,14)) for _ in range(300)],
    device=rng.choice(["android","ios","mweb"], 300), app_version=""))

exposures = pd.concat([exp_rows, leak, bots, pre], ignore_index=True)
exposures = exposures.sample(frac=1, random_state=3).reset_index(drop=True)
exposures.insert(0, "exposure_id", [f"EXP-{i:06d}" for i in range(1, len(exposures)+1)])
exposures["first_exposure_ts"] = pd.to_datetime(exposures.first_exposure_ts)\
                                    .dt.strftime("%Y-%m-%d %H:%M:%S")
exposures.to_csv(OUT/"ab_exposures.csv", index=False)

# ------------------------------------------------------------
# 4. EXPERIMENT CONVERSIONS (novelty effect in variant B)
# ------------------------------------------------------------
week_idx = ((exp_rows.first_exposure_ts - EXP_START).dt.days // 14).clip(0,2)
RATE_B = {0:0.073, 1:0.064, 2:0.061}     # weeks 1-2, 3-4, 5-6
conv_p = np.where(exp_rows.variant=="A", 0.059, week_idx.map(RATE_B))
exp_rows["converted"] = rng.random(N_USERS) < conv_p
converters = exp_rows[exp_rows.converted].copy()
converters["order_ts"] = converters.first_exposure_ts + pd.to_timedelta(
    np.minimum(rng.exponential(1.4, len(converters)), 6.9), unit="D")

# ------------------------------------------------------------
# 5. D2C ORDERS (background + experiment) + ORDER ITEMS
# ------------------------------------------------------------
exposed_cust = set(u for u in exp_rows.user_id if u.startswith("C"))
non_exposed  = [c for c in cust_df.customer_id if c not in exposed_cust]

orders, items = [], []
oid = 0
def new_oid():
    global oid; oid += 1
    return f"D2C-{oid:06d}"

def build_basket(order_id, mode):
    """mode: 'normal'    -> variant A and background traffic
       'threshold' -> variant B, basket pushed toward the 50K free-shipping bar
    """
    subtotal = 0
    if mode == "threshold":
        pool, w = CHEAP_SKUS, np.array(
            [3.0 if s in HERO_SKUS else 1.0 for s in CHEAP_SKUS])
        while True:
            sku = str(rng.choice(pool, p=w/w.sum()))
            qty = int(rng.choice([1,2,3,4], p=[.25,.35,.25,.15]))
            items.append(dict(order_id=order_id, sku_code=sku, qty=qty,
                              unit_price=PRICE[sku]))
            subtotal += PRICE[sku]*qty
            if subtotal >= FREESHIP_MIN and rng.random() < 0.75: break
            if subtotal > 140_000: break
    else:
        w = np.array([2.2 if s in HERO_SKUS else 1.0 for s in ALL_SKUS])
        n_lines = int(rng.choice([1,2,3,4], p=[.30,.35,.25,.10]))
        for _ in range(n_lines):
            sku = str(rng.choice(ALL_SKUS, p=w/w.sum()))
            qty = int(rng.choice([1,2,3,4,6], p=[.22,.30,.24,.14,.10]))
            items.append(dict(order_id=order_id, sku_code=sku, qty=qty,
                              unit_price=PRICE[sku]))
            subtotal += PRICE[sku]*qty
    return subtotal

def ship_fee(city):
    return int(rng.choice([9000,11000,13000,16000],
               p=[.35,.30,.20,.15] if city in JABODETABEK else [.10,.20,.35,.35]))

# 5a. orders placed by experiment converters
for _, r in converters.iterrows():
    o = new_oid()
    mode = "threshold" if r.variant=="B" else "normal"
    sub = build_basket(o, mode)
    city = str(rng.choice(CITIES))
    fee = 0 if (r.variant=="B" and sub>=FREESHIP_MIN) else ship_fee(city)
    orders.append(dict(order_id=o, customer_id=r.user_id, order_ts=r.order_ts,
                       channel="TokoRia", payment_method=str(rng.choice(
                           ["gopay","ovo","va_bca","cod"], p=[.34,.22,.30,.14])),
                       shipping_fee=fee, dest_city=city))

# 5b. background orders (non-exposed customers and guests)
for d in pd.date_range(PERIOD_START, PERIOD_END):
    n = int(rng.poisson(185 * (1.25 if d.weekday()>=5 else 1.0)
                        * (1 + 0.0012*(d - PERIOD_START).days)))
    in_window = EXP_START <= d <= EXP_END + days(7)
    for _ in range(n):
        o = new_oid()
        guest = rng.random() < 0.15
        cust = (f"G{int(rng.integers(1,99999)):05d}" if guest
                else str(rng.choice(non_exposed if in_window else cust_df.customer_id)))
        build_basket(o, "normal")
        ts = d + timedelta(hours=int(rng.choice(range(8,23))),
                           minutes=int(rng.integers(0,60)),
                           seconds=int(rng.integers(0,60)))
        city = str(rng.choice(CITIES))
        orders.append(dict(order_id=o, customer_id=cust, order_ts=ts,
                           channel="TokoRia", payment_method=str(rng.choice(
                               ["gopay","ovo","va_bca","cod"], p=[.34,.22,.30,.14])),
                           shipping_fee=ship_fee(city), dest_city=city))

orders_df = pd.DataFrame(orders)
items_df  = pd.DataFrame(items)

# ------------------------------------------------------------
# 6. ORDER STATUS, CANCELLATIONS & SHIPMENTS (OTIF storyline)
# ------------------------------------------------------------
hero_orders = set(items_df[items_df.sku_code.isin(HERO_SKUS)].order_id)
wh_pick = np.where(
    orders_df.order_id.isin(hero_orders),
    rng.choice(WAREHOUSES, len(orders_df), p=[.75,.15,.10]),
    rng.choice(WAREHOUSES, len(orders_df), p=[.60,.25,.15]))
orders_df["_wh"] = wh_pick
odate = pd.to_datetime(orders_df.order_ts).dt.normalize()

stockout_win = (odate >= "2026-05-18") & (odate <= "2026-05-31")
cancel_p = np.where(orders_df.order_id.isin(hero_orders)
                    & (orders_df._wh=="WH-CKR") & stockout_win, 0.20, 0.020)
status = np.where(rng.random(len(orders_df)) < cancel_p, "cancelled", "completed")
status = np.where((status=="completed") & (rng.random(len(orders_df))<0.012),
                  "refunded", status)
status = np.where((status=="completed") & (odate >= "2026-06-27"),
                  "processing", status)
orders_df["order_status"] = status

ship_rows = []
shippable = orders_df[orders_df.order_status.isin(["completed","refunded"])]
for _, r in shippable.iterrows():
    od = pd.to_datetime(r.order_ts).normalize()
    ship_d = od + days(rng.integers(0,2))
    promised = od + days(3 if r.dest_city in JABODETABEK else 5)
    transit = int(rng.integers(1,4))
    if r._wh=="WH-CKR" and datetime(2026,5,18) <= ship_d <= datetime(2026,6,3) \
       and rng.random() < 0.45:
        transit += int(rng.integers(2,7))            # warehouse backlog
    delivered = ship_d + days(transit)
    ship_rows.append(dict(
        shipment_id=f"SHP-{len(ship_rows)+1:06d}", order_id=r.order_id,
        warehouse_id=r._wh, courier=str(rng.choice(
            ["JNE","SiCepat","AnterAja","GoSend"], p=[.35,.30,.22,.13])),
        ship_date=ship_d.date(), promised_date=promised.date(),
        delivered_date=delivered.date(),
        fulfil_type=str(rng.choice(["full","partial"], p=[.97,.03])),
        dest_city=r.dest_city))
ship_df = pd.DataFrame(ship_rows)
# FAULT S1: 4% of delivered_date values missing (parcel arrived, never scanned)
ship_df.loc[ship_df.sample(frac=0.04, random_state=11).index, "delivered_date"] = None

orders_df = orders_df.drop(columns=["_wh"])

# ------------------------------------------------------------
# 7. FAULT INJECTION: orders & items
# ------------------------------------------------------------
# FAULT O1: mixed timestamp formats (15% written as ISO-UTC, i.e. WIB minus 7h)
ts = pd.to_datetime(orders_df.order_ts)
iso_mask = rng.random(len(orders_df)) < 0.15
orders_df["order_ts"] = np.where(
    iso_mask, (ts - pd.Timedelta(hours=7)).dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
    ts.dt.strftime("%Y-%m-%d %H:%M:%S"))
orders_df["ingested_at"] = (ts + pd.to_timedelta(
    rng.integers(2,40,len(orders_df)), unit="s")).dt.strftime("%Y-%m-%d %H:%M:%S")

# FAULT O2: 0.7% of orders duplicated (payment webhook fired twice)
dups = orders_df.sample(frac=0.007, random_state=5).copy()
dups["ingested_at"] = (pd.to_datetime(dups.ingested_at)
                       + pd.Timedelta(seconds=3)).dt.strftime("%Y-%m-%d %H:%M:%S")
orders_df = pd.concat([orders_df, dups], ignore_index=True)\
              .sample(frac=1, random_state=9).reset_index(drop=True)

# FAULT I1: 3% of unit_price values stored as the string 'Rp12.500'
items_df["unit_price"] = items_df.unit_price.astype(object)
m = rng.random(len(items_df)) < 0.03
items_df.loc[m, "unit_price"] = items_df.loc[m, "unit_price"].map(
    lambda v: "Rp" + f"{int(v):,}".replace(",", "."))
# FAULT I2: 120 rows with a mis-padded SKU 'KRK-BLD-80' + 30 SKU-TEST rows
hero_idx = items_df.index[items_df.sku_code=="KRK-BLD-080"]
items_df.loc[rng.choice(hero_idx, 120, replace=False), "sku_code"] = "KRK-BLD-80"
junk = items_df.sample(30, random_state=13).copy()
junk["sku_code"], junk["qty"], junk["unit_price"] = "SKU-TEST", 1, 0
items_df = pd.concat([items_df, junk], ignore_index=True)
# FAULT I3: 250 completed orders carry a NEGATIVE-qty return line (status unchanged)
done = orders_df[orders_df.order_status=="completed"].order_id
ret_src = items_df[items_df.order_id.isin(set(done))].sample(250, random_state=17).copy()
ret_src["qty"] = -ret_src.qty
items_df = pd.concat([items_df, ret_src], ignore_index=True)
items_df.insert(0, "item_id", [f"ITM-{i:06d}" for i in range(1, len(items_df)+1)])

orders_df.to_csv(OUT/"orders_d2c.csv", index=False)
items_df.to_csv(OUT/"order_items_d2c.csv", index=False)
ship_df.to_csv(OUT/"shipments_d2c.csv", index=False)
cust_df.to_csv(OUT/"customers_d2c.csv", index=False)
dist_df.to_csv(OUT/"distributors.csv", index=False)
sku_df.to_csv(OUT/"sku_master.csv", index=False)

# ------------------------------------------------------------
# 8. DAILY INVENTORY (hero-SKU stockout at WH-CKR)
# ------------------------------------------------------------
pop_w = {s: (3.0 if s in HERO_SKUS else 1.0) for s in ALL_SKUS}
wh_share = {"WH-CKR":.60, "WH-BDG":.25, "WH-TGR":.15}
inv_rows = []
for wh in WAREHOUSES:
    for sku in ALL_SKUS:
        mean_d = 55 * pop_w[sku] * wh_share[wh]
        stock = int(mean_d * 25)
        for i, d in enumerate(pd.date_range(PERIOD_START, PERIOD_END)):
            boost = 1.9 if (sku in HERO_SKUS and wh=="WH-CKR"
                            and EXP_START <= d <= EXP_END) else 1.0
            demand = rng.poisson(mean_d * boost)
            if i % 7 == 3:                                # weekly replenishment
                skip = (sku in HERO_SKUS and wh=="WH-CKR"
                        and datetime(2026,5,14) <= d <= datetime(2026,5,27))
                if not skip:
                    catchup = 2.3 if (sku in HERO_SKUS and wh=="WH-CKR"
                                      and datetime(2026,5,28)<=d<=datetime(2026,6,10)) else 1.0
                    stock += int(mean_d * 7 * rng.uniform(.9,1.15) * catchup)
            stock = max(stock - demand, 0)
            inv_rows.append((d.date(), wh, sku, stock))
inv_df = pd.DataFrame(inv_rows, columns=["snapshot_date","warehouse_id",
                                         "sku_code","qty_on_hand"])
# FAULT V1: 3-5 May snapshots missing (scheduled job failed)
inv_df = inv_df[~inv_df.snapshot_date.astype(str).isin(
    ["2026-05-03","2026-05-04","2026-05-05"])]
# FAULT V2: 15 rows with negative stock (bad manual adjustment)
neg_i = rng.choice(inv_df.index, 15, replace=False)
inv_df.loc[neg_i, "qty_on_hand"] = -rng.integers(3, 40, 15)
# FAULT V3: WH-BDG reports every 1L SKU in CARTONS, not units (divided by 12)
mask_1l = (inv_df.warehouse_id=="WH-BDG") & (inv_df.sku_code.str.endswith("1L0"))
inv_df.loc[mask_1l, "qty_on_hand"] = (inv_df.loc[mask_1l, "qty_on_hand"]/12).astype(int)
inv_df.to_csv(OUT/"inventory_daily.csv", index=False)

# ------------------------------------------------------------
# 9. B2B SELL-IN TO DISTRIBUTORS
# ------------------------------------------------------------
b2b_rows = []
top25 = ALL_SKUS[:25]
for wk in pd.date_range("2026-01-05", "2026-06-29", freq="7D"):
    for dist in dist_df.dist_id:
        for sku in rng.choice(top25, int(rng.integers(10,19)), replace=False):
            b2b_rows.append(dict(
                order_id=f"B2B-{len(b2b_rows)+1:05d}", dist_id=dist,
                order_date=wk.date(), sku_code=sku,
                qty_pcs=int(rng.integers(20,300))*12,
                unit_price=int(round(PRICE[sku]*0.62, -2))))
b2b_df = pd.DataFrame(b2b_rows)
# FAULT B1: DST-03's entire 9 March week duplicated verbatim
dup_b = b2b_df[(b2b_df.dist_id=="DST-03") &
               (b2b_df.order_date.astype(str)=="2026-03-09")]
b2b_df = pd.concat([b2b_df, dup_b], ignore_index=True)
# FAULT B2: 5 rows with a 10x price typo
b2b_df.loc[rng.choice(b2b_df.index, 5, replace=False), "unit_price"] *= 10
b2b_df.to_csv(OUT/"sales_b2b.csv", index=False)

# ------------------------------------------------------------
# 10. PRODUCTION & BILL OF MATERIALS (recursive-CTE practice data)
# ------------------------------------------------------------
prod_skus = HERO_SKUS + [s for s in ALL_SKUS if s not in HERO_SKUS][:13]
prod_rows = []
for d in pd.date_range(PERIOD_START, PERIOD_END):
    for sku in prod_skus:
        if rng.random() < 0.5:
            line = str(rng.choice(["L1","L2","L3"]))
            qty = int(rng.integers(4000, 28000))
            p_def = 0.045 if (line=="L2" and d.month==4) else 0.012
            prod_rows.append(dict(
                batch_id=f"B{d:%y%m%d}-{line}-{len(prod_rows)%97:02d}",
                prod_date=d.date(), line_id=line, sku_code=sku,
                qty_produced=qty, qty_defect=int(rng.binomial(qty, p_def))))
pd.DataFrame(prod_rows).to_csv(OUT/"production_batches.csv", index=False)

bom = [
 ("KRK-BLD-080","MIX-BLD","Balado Seasoning Mix",0.012,"kg"),
 ("KRK-BLD-080","POT-SLC","Sliced Potato",0.070,"kg"),
 ("KRK-BLD-080","OIL-PLM","Frying Oil",0.008,"liter"),
 ("KRK-BLD-080","FLM-080","Packaging Film 80g",1,"pcs"),
 ("MIX-BLD","RAW-CBE","Chili Powder",0.40,"kg"),
 ("MIX-BLD","RAW-BWG","Onion Powder",0.30,"kg"),
 ("MIX-BLD","RAW-GRM","Salt",0.10,"kg"),
 ("MIX-BLD","RAW-GLA","Caster Sugar",0.20,"kg"),
 ("SGR-LMN-350","CON-LMN","Lemon Concentrate",0.040,"liter"),
 ("SGR-LMN-350","RAW-GLC","Liquid Sugar",0.030,"liter"),
 ("SGR-LMN-350","RAW-AIR","RO Water",0.310,"liter"),
 ("SGR-LMN-350","BTL-350","PET Bottle 350ml",1,"pcs"),
 ("SGR-LMN-350","CAP-STD","Bottle Cap",1,"pcs"),
 ("CON-LMN","RAW-LMN","Imported Lemon Juice",0.60,"liter"),
 ("CON-LMN","RAW-CTA","Citric Acid",0.05,"kg"),
]
pd.DataFrame(bom, columns=["parent_code","component_code","component_name",
                           "qty_per_unit","uom"]).to_csv(OUT/"bom.csv", index=False)

# ------------------------------------------------------------
# 11. SELF-CHECK: key metrics must match the scenario design
# ------------------------------------------------------------
print("="*58)
print(" NetLift DATASET SUMMARY")
print("="*58)
for f in sorted(OUT.glob("*.csv")):
    print(f"  {f.name:26s} {sum(1 for _ in open(f))-1:>8,} rows")

from scipy import stats as st
clean = exp_rows  # ground truth: free of bots, leakage, and pre-window rows
nA, nB = (clean.variant=="A").sum(), (clean.variant=="B").sum()
chi2, p_srm = st.chisquare([nA,nB], [len(clean)/2]*2)
cA = clean[clean.variant=="A"].converted.mean()
cB = clean[clean.variant=="B"].converted.mean()
pooled = clean.converted.mean()
se = np.sqrt(pooled*(1-pooled)*(1/nA+1/nB))
zval = (cB-cA)/se
print(f"\n  A/B split (clean)   : {nA:,} / {nB:,}  (B={nB/(nA+nB):.1%})")
print(f"  SRM chi2 p-value    : {p_srm:.2e}")
print(f"  Conversion A vs B   : {cA:.2%} vs {cB:.2%}  (z={zval:.2f})")
hero_ckr = inv_df[(inv_df.warehouse_id=='WH-CKR') &
                  (inv_df.sku_code.isin(HERO_SKUS)) & (inv_df.qty_on_hand==0)]
print(f"  Hero stockout rows  : {len(hero_ckr)} rows (WH-CKR)")
print("\n  Done. Data is ready to load into PostgreSQL.")
