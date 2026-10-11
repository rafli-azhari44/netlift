# Data Quality Findings 

Audit date: [fill in]
Source: weekly CSV export from Mbak Sinta (Data Engineer), pulled [date]
Scope: 11 raw tables in `raw` schema, PostgreSQL `nusarasa_dw`

> Each finding follows the same four-part structure: what was checked,
> what was found, why it matters if it slips through, and the decision
> taken. Severity is rated High / Medium / Low by business impact, not by
> how many rows are affected a single wrong number in a Finance report
> outranks a thousand cosmetic typos.

---

P1:
|baris_raw|order_unik|duplikat|
|---------|----------|--------|
|44200|43893|307|

|order_id|customer_id|order_ts|channel|payment_method|shipping_fee|dest_city|order_status|ingested_at|
|--------|-----------|--------|-------|--------------|------------|---------|------------|-----------|
|D2C-000090|C06143|2026-05-14 17:07:01|TokoRia|cod|13000|Karawang|completed|2026-05-14 17:07:20|
|D2C-000090|C06143|2026-05-14 17:07:01|TokoRia|cod|13000|Karawang|completed|2026-05-14 17:07:23|
|D2C-000177|V04641|2026-06-06 12:25:02|TokoRia|va_bca|13000|Tangerang|completed|2026-06-06 12:25:34|
|D2C-000177|V04641|2026-06-06 12:25:02|TokoRia|va_bca|13000|Tangerang|completed|2026-06-06 12:25:31|

Query       :
Results     :
Impacts     :
Decisions   :

P2:
|format_utc|format_wib|persen_utc|
|----------|----------|----------|
|6603|37597|14.9|

Query       :
Results     :
Impacts     :
Decisions   :

P3:
|unit_price|
|----------|
|Rp14.000|
|Rp12.800|
|Rp11.000|
|Rp5.300|
|Rp6.300|
|Rp6.400|
|Rp12.600|
|Rp11.100|
|Rp12.700|
|Rp7.400|

|count|
|-----|
|3051|

Query       :
Results     :
Impacts     :
Decisions   :

P4:
|order_id|order_status|sku_code|qty|
|--------|------------|--------|---|
|D2C-024072|completed|SGR-LMN-350|-3|
|D2C-005354|completed|SGR-CCO-350|-2|
|D2C-023231|completed|RNK-KOP-150|-2|
|D2C-007813|completed|RNK-SUS-150|-3|
|D2C-009300|completed|RNK-MDU-150|-2|

Query       :
Results     :
Impacts     :
Decisions   :

P5:
|sku_code|n|
|--------|-|
|KRK-BLD-80|120|
|SKU-TEST|30|

Query       :
Results     :
Impacts     :
Decisions   :

P6:
|sku_code|panjang|sku_name|brand|status|
|--------|-------|--------|-----|------|
|KRK-BLD-080|11|Kriuku Balado 80g|Kriuku|active|
|KRK-BLD-080 |12|kriuku balado 80g|Kriuku|active|
|KRK-BLD-180|11|Kriuku Balado 180g|Kriuku|active|
|KRK-DJR-080|11|Kriuku Daun Jeruk 80g|Kriuku|active|
|KRK-DJR-180|11|Kriuku Daun Jeruk 180g|kriuku|active|
|KRK-JGB-080|11|Kriuku Jagung Bakar 80g|Kriuku|active|
|KRK-JGB-180|11|Kriuku Jagung Bakar 180g|Kriuku|active|
|KRK-KJU-080|11|Kriuku Keju 80g|Kriuku|active|
|KRK-KJU-180|11|Kriuku Keju 180g|Kriuku|active|
|KRK-ORI-080|11|Kriuku Original 80g|Kriuku|active|
|KRK-ORI-180|11|Kriuku Original 180g|Kriuku|active|
|KRK-PDM-080|11|Kriuku Pedas Manis 80g|Kriuku|active|
|KRK-PDM-180|11|Kriuku Pedas Manis 180g|Kriuku|active|
|KRK-RLA-080|11|Kriuku Rumput Laut 80g|Kriuku|active|
|KRK-RLA-180|11|Kriuku Rumput Laut 180g|Kriuku|active|
|KRK-SPG-080|11|Kriuku Sapi Panggang 80g|Kriuku|active|
|KRK-SPG-180|11|Kriuku Sapi Panggang 180g|Kriuku|active|
|RNK-CKL-150|11|Renyahku Cokelat 150g|Renyahku|active|
|RNK-GRN-150|11|Renyahku Green Tea 150g|Renyahku|active|
|RNK-KLP-150|11|Renyahku Kelapa 150g|renyahku|active|
|RNK-KOP-150|11|Renyahku Kopi 150g|renyahku|active|
|RNK-MDU-150|11|Renyahku Madu 150g|Renyahku|active|
|RNK-STR-150|11|Renyahku Stroberi 150g|Renyahku|active|
|RNK-SUS-150|11|Renyahku Susu 150g|Renyahku|active|
|RNK-VNL-150|11|Renyahku Vanila 150g|Renyahku|active|
|SGR-APL-1L0|11|Segarin Apel 1L|Segarin|active|
|SGR-APL-350|11|Segarin Apel 350ml|Segarin|discontinued|
|SGR-CCO-1L0|11|Segarin Coco 1L|Segarin|active|
|SGR-CCO-350|11|Segarin Coco 350ml|Segarin|active|
|SGR-GVA-1L0|11|Segarin Guava 1L|Segarin|active|
|SGR-GVA-350|11|Segarin Guava 350ml|Segarin|active|
|SGR-JRK-1L0|11|Segarin Jeruk 1L|Segarin|active|
|SGR-JRK-350|11|Segarin Jeruk 350ml|Segarin|active|
|SGR-LCI-1L0|11|Segarin Leci 1L|Segarin|active|
|SGR-LCI-350|11|Segarin Leci 350ml|segarin|active|
|SGR-LMN-1L0|11|Segarin Lemon 1L|Segarin|active|
|SGR-LMN-350|11|Segarin Lemon 350ml|Segarin|active|
|SGR-MKS-1L0|11|Segarin Markisa 1L|Segarin|active|
|SGR-MKS-350|11|Segarin Markisa 350ml|segarin|active|
|SGR-TMJ-1L0|11|Segarin Teh Melati 1L|Segarin|active|
|SGR-TMJ-350|11|Segarin Teh Melati 350ml|Segarin|active|

|count|
|-----|
|2689|

Query       :
Results     :
Impacts     :
Decisions   :

P7:
|city|count|
|----|-----|
|Bandng|13|
|bandung|8|
|Bandung|1441|
|bekasi|12|
|Bekasi|2343|
|BEKASI|11|
|Bekasii|12|
|Bogor|935|
|Cikarang|1877|
|CIKARANG|14|
|Cikarang |14|
|Depok|1085|
|Jakarta Timur|1764|
|Karawang|862|
|Tangerang|1609|

Query       :
Results     :
Impacts     :
Decisions   :

P8:
|warehouse_id|rata_stok_1l|
|------------|------------|
|WH-BDG|31|
|WH-CKR|929|
|WH-TGR|204|

|tanggal_hilang|
|--------------|
|2026-05-03|
|2026-05-04|
|2026-05-05|

|count|
|-----|
|15|

Query       :
Results     :
Impacts     :
Decisions   :

P9:
|count|
|-----|
|320|

|user_id|n_exposure|
|-------|----------|
|V90002|120|
|V90006|120|
|V90004|120|
|V90005|120|
|V90001|120|
|V90007|120|
|V90003|120|
|V31300|2|
|V56858|2|
|V25987|2|

|count|
|-----|
|457|

Query       :
Results     :
Impacts     :
Decisions   :

P10:
|count|
|-----|
|1672|

|dist_id|order_date|sku_code|qty_pcs|unit_price|count|
|-------|----------|--------|-------|----------|-----|
|DST-03|2026-03-09|KRK-DJR-180|996|8300|2|
|DST-03|2026-03-09|KRK-PDM-080|624|4000|2|
|DST-03|2026-03-09|KRK-ORI-080|240|3300|2|
|DST-03|2026-03-09|SGR-LMN-1L0|1236|7900|2|
|DST-03|2026-03-09|KRK-KJU-180|2172|7900|2|
|DST-03|2026-03-09|KRK-DJR-080|2640|4600|2|
|DST-03|2026-03-09|KRK-RLA-180|3528|8500|2|
|DST-03|2026-03-09|KRK-JGB-180|1020|8900|2|
|DST-03|2026-03-09|SGR-MKS-350|1536|3200|2|
|DST-03|2026-03-09|KRK-PDM-180|1248|6900|2|
|DST-03|2026-03-09|KRK-ORI-180|2064|9100|2|
|DST-03|2026-03-09|SGR-JRK-1L0|1200|7600|2|
|DST-03|2026-03-09|SGR-LCI-350|432|3000|2|
|DST-03|2026-03-09|KRK-KJU-080|1584|4500|2|
|DST-03|2026-03-09|SGR-TMJ-350|972|3600|2|
|DST-03|2026-03-09|KRK-BLD-080|1788|3500|2|
|DST-03|2026-03-09|SGR-TMJ-1L0|3012|6900|2|

|order_id|dist_id|order_date|sku_code|qty_pcs|unit_price|list_price|
|--------|-------|----------|--------|-------|----------|----------|
|B2B-02309|DST-08|2026-05-25|KRK-PDM-080|756|40000|6400|
|B2B-01985|DST-02|2026-05-11|SGR-TMJ-1L0|1764|69000|11100|
|B2B-01213|DST-02|2026-03-23|SGR-TMJ-1L0|2304|69000|11100|
|B2B-02096|DST-02|2026-05-18|SGR-TMJ-350|3084|36000|5800|
|B2B-01706|DST-06|2026-04-20|KRK-ORI-180|3564|91000|14600|












## Note — how the staging layer treats faults

Staging does not remove every fault. It uses three strategies:
- FIX: repair the value (string prices, SKU padding, carton units)
- REMOVE: drop the row (webhook duplicates, SKU-TEST)
- FLAG: keep the row, mark it (is_return, is_scan_missing, is_bot,
  is_invalid_negative, is_multi_variant)

Flagging is deliberate: a return is a real business event, so deleting
it would lose information Finance needs. Flagging keeps the record and
lets the analyst decide.

Practical consequence: quality checks must run against raw. Verified
by running the same check on both layers.