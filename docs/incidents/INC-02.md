# INC-02: OTIF moved after a fix to `stg_shipments`

> **Simulated incident, written for training.** The two OTIF figures are real: they are what this project's data produces under each rule. The response steps below are part of the simulation: the dashboard note and `docs/metric-changelog.md` do not exist in the repository.

**Date of incident:** Tuesday 7 July 2026
**Detected by:** Data analyst, while reviewing the change
**Time the old figure was in circulation:** one week (quoted to the board the previous week)

## Impact

- Overall OTIF moved from **78.9% to 82.2%** in a single commit.
- Pak Yusuf had already quoted 78.9% to the board the week before. Without a heads-up, he would have found a different number for his own team's KPI on the dashboard, with no explanation.
- The old figure understated performance: it counted 1,672 parcels that were delivered but never scanned as failures.

## Timeline

| Time | Event |
|---|---|
| Previous week | Dashboard shows 78.9%; Pak Yusuf quotes it to the board |
| Tue 10:00 | Analyst changes `stg_shipments`: a missing `delivered_date` now gives `is_otif = NULL` instead of `FALSE` |
| Tue 10:20 | `dbt run`; dashboard OTIF now reads 82.2% |
| Tue 10:30 | Analyst notices the shift while checking the change |
| Tue 11:00 | Message to Pak Yusuf, before he sees it elsewhere, with a one-line explanation he can reuse |

## Root cause

The change itself was correct: a parcel with no delivery scan is unknown, not late. The problem was that a metric's definition could change through an ordinary code commit, with nothing to signal that a published number would move. There was no changelog for metric definitions, no record of who relies on which number, and no step that compares headline metrics before and after a model change.

## Immediate fix

- Kept the corrected definition.
- Told Pak Yusuf directly, with a sentence for the board: *"OTIF has been restated from 78.9% to 82.2% after excluding 1,672 delivered parcels that were never scanned; the earlier figure understated performance."*
- Added a note to the dashboard's OTIF card with the definition and the restatement date.

## Prevention

- `docs/metric-changelog.md`: every change to a metric definition gets an entry: old rule, new rule, effect on the number, date.
- Before merging a change to a staging model, rerun the headline metrics (OTIF, GMV, conversion) and compare them with the last published values. Any shift above one percentage point requires a note to the metric's owner.
- Each headline metric has a named owner who hears about definition changes first.

## What I learned

Being right about a definition is not enough when someone has already quoted the old number. The data team controls the definition; stakeholders carry the consequences in front of their own leadership. The explanation has to reach them before the new number does.
