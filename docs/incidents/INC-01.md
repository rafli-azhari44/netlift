# INC-01: Dashboard GMV jumped 40% overnight

> **Simulated incident, written for training.** It did not happen in this project. The current `scripts/load_raw.py` already truncates each table before loading, which is the first prevention item below; the other prevention items are proposals and are not implemented yet.

**Date of incident:** Friday 26 June 2026 (load) to Monday 29 June 2026 (detected)
**Detected by:** Data analyst, after Pak Danu shared a dashboard screenshot
**Time the wrong figure was in circulation:** about 2.5 days (Friday evening to Monday 09:30)

## Impact

- The Growth dashboard showed May GMV about 40% above the figure presented on Friday.
- Pak Danu shared the screenshot in the team group as good news. It could have reached the board slide for the free-shipping experiment and strengthened the case for rollout.
- No decision was taken on the wrong figure before it was corrected.

## Timeline

| Time | Event |
|---|---|
| Fri 14:00 | May GMV presented from the dashboard |
| Fri 16:10 | `load_raw.py` re-run to pick up a corrected CSV. The loader at the time appended rows instead of replacing them |
| Fri 16:20 | The run stops partway through `order_items_d2c` when the database connection drops. The error scrolls past unnoticed; the tables loaded before it, including `orders_d2c`, had already been appended in full |
| Fri 16:40 | `dbt run` completes without errors; dashboard refreshed |
| Mon 08:50 | Pak Danu shares the screenshot: May GMV +40% versus Friday |
| Mon 09:05 | Analyst compares row counts with the source files: `raw.orders_d2c` holds twice the rows of its CSV, and `raw.order_items_d2c` holds far more than the 100,466 in its CSV |
| Mon 09:30 | Raw tables reloaded cleanly, `dbt run`, May GMV back to Friday's figure; correction posted in the group |

## Root cause

The loader appended to whatever was already in the tables, so any rerun, complete or interrupted, duplicated data.

The duplicated orders stayed invisible: staging removes duplicate orders because of the known payment-webhook fault, so `stg_orders_d2c` absorbed them. The duplicated item lines did not: `stg_order_items` has no deduplication, and GMV is the sum of item lines.

No check compared table row counts with the source files. The one test that touches this, the warn-level uniqueness test on `raw.orders_d2c.order_id`, was not run after the reload, and even if it had been, it warns on every run by design (307 known duplicates). A jump to about 44,000 duplicates would have looked like the usual warning.

## Immediate fix

Truncated and reloaded all raw tables, rebuilt the models, confirmed that May GMV matched Friday's figure, and posted a correction with the right number before the board slide was finalised.

## Prevention

- **In place:** the loader truncates each table before loading, so a rerun replaces data instead of adding to it.
- **Proposed:** run the `TRUNCATE` and the insert in one transaction. Today they are committed separately, so an interrupted run leaves a table partly loaded: the opposite failure, with GMV dropping instead of jumping.
- **Proposed:** dbt test `unique` on `stg_order_items.item_id`.
- **Proposed:** post-load check: each raw table's row count must equal its CSV's, or the load fails loudly.
- **Proposed:** give the raw `orders_d2c` uniqueness test a ceiling (`severity: error`, `warn_if: ">0"`, `error_if: ">1000"`), so the expected 307 duplicates still only warn but an abnormal jump fails the build.

## What I learned

A pipeline that is only correct when run exactly once will eventually be run twice. The fix was not to be more careful on Fridays. It was to make a second run harmless, and to add checks that fail loudly when the numbers stop reconciling with the source. A warning that fires on every run teaches everyone to ignore it.
