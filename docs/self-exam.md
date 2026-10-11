# Self-Exam: Honest Score

This page records what was found independently and what needed help. It is here on purpose: a portfolio that only shows final answers hides how the work was actually done.

## How this project was built

I built NetLift with a written project guide and an AI assistant (Claude) as a reviewer.

- **Hands-on, by me:** setting up the PostgreSQL database and loading the raw data, running the dbt pipeline and its tests, running every SQL query in DBeaver, building the Power BI dashboard, and re-running 23 verification queries against the database before publishing. Every figure matched.
- **With the assistant:** reviewing and correcting my queries, drafting most of the written documents, and re-checking every number in them against the data.

Every figure in this repository was checked against the data before it was published.

## Phase 3: hunting the planted data faults

- **Score:** 19 of the 20 fault codes in the answer key appear in my profiling notes, but they are not independent finds. I ran the profiling queries from the project guide, and the guide also showed what each query should reveal. The notes prove that I could run and read the checks, not that I could have designed them.
- **Missed:** SRM, the only code that never appeared in my notes.
- **Why I missed it:** every check I ran looked at one column or one table at a time. SRM only shows when the variant split is compared across device and app version groups. The `assert_ab_srm` dbt test raised the alarm later, and S11 traced it to Android build 6.4.0.
- **Write-ups:** the impact and decision for each fault in `profiling-findings.md` were completed later with the assistant and checked against the data.
- **Next time:** design my own checks before reading any expected result, and compare groups (warehouse against warehouse, build against build), not only single columns. The guide names V3 and SRM as the faults most often missed, and both are comparison faults.

## Phase 5: SQL bank

- **Score:** no number claimed. I did not keep count of which problems I solved without help, so I am not putting a number here.
- **How:** all 15 problems are complete. The assistant reviewed every query, fixed the errors in my attempts and checked each result against the data.
- **Errors caught in my attempts:** a query in S12 that never finished until it was rewritten with a temporary table and an index, a recursive join in S13 that used the wrong join and multiplier columns, `BETWEEN` on a timestamp in S14, and syntax errors in S11 and S15.

## Conclusions corrected during re-checking

Several conclusions in early drafts changed when the numbers were re-run against the data. Each correction is now reflected in the SQL comments and documents.

| First reading | After re-checking |
|---|---|
| The May OTIF drop at WH-CKR was caused by the hero-SKU stockout | Almost all failures were late but complete shipments (1,615 of 1,806), and at WH-CKR between 18 May and 3 June, orders with and without the hero SKUs were late at nearly the same rate (47.0% vs 48.8%). The cause was warehouse load during the promo. |
| Days of cover for KRK-BLD-080 fell below 7 on 16 May, a week before the stockout | 17 May (6.8 days), six days before |
| Production was about 10x sales because of a unit mismatch | About 6x net of defects (4.7x-8.9x by SKU). Units do not explain it, and the gap is still open. |
| SGR-LMN-350 falls into class C by revenue | It ranks 2nd (class A). Class C is four other 350ml Segarin SKUs. |
| `BETWEEN` on a timestamp in S14 was safe | It dropped the last day of each window (75 units of KRK-BLD-080). Replaced with `>= start AND < next day`. |
| Staging set every negative stock value to NULL | 2 of the 15 negative rows (WH-BDG 1L SKUs) were multiplied by 12 first, because the carton conversion came before the negative check in the same `CASE`. The order is now swapped, so all 15 become NULL. |
| Targeting new and lapsed customers would make the subsidy more efficient | New and existing customers responded alike (+0.92 vs +0.89 points). Targeting stays a hypothesis. |

## What the dbt tests prove

`dbt test` ends with PASS=8, WARN=1, ERROR=1, and both alarms are intended:

- `source_unique_raw_orders_d2c_order_id` warns on 307 duplicate order IDs in raw, while `unique_fct_orders_order_id` passes in the mart. The duplicates exist at the source and are removed by the cleaning layer.
- `assert_ab_srm` fails on purpose. It catches the Android 6.4.0 bucketing bug (62.9% of that build's users in variant B).

One observation for later: `fct_ab_users` takes about 4 minutes to build (245 seconds) while every other model finishes in seconds. The result is correct, but the model is worth optimising.
