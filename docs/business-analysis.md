# Business Analysis: "Free Shipping over 50K" Experiment

**To:** Pak Danu, Head of Growth  
**From:** Data Team  
**Test period:** 4 May - 14 June 2026 (6 weeks, 66,570 users)

> **Currency and number format**
> - All amounts are in Indonesian Rupiah. *Rp* is the local symbol and *IDR* is the ISO 4217 currency code; both refer to the same currency.
> - Figures follow the international convention so they read the same for every audience: comma for thousands, period for decimals (Rp1,000,000.00).
> - In the Indonesian local format, the same amount is written as Rp1.000.000,00.

---

## Summary

Variant B (free shipping on orders over Rp50,000) outperformed variant A on both headline metrics: conversion rose from 5.893% to 6.809% (58.9 versus 68.1 orders per 1,000 users), and average order value rose from Rp55,440 to Rp62,301. But at full rollout under the current cost structure, the promo would return roughly **Rp255M less contribution per year** than not running it.

Recommendation: **hold the rollout**, fix the two problems that compromised this test, and re-test a revised design.

---

## What the dashboard shows

| Metric | A | B | Change |
|---|---|---|---|
| Conversion | 5.893% | 6.809% | **+15.5%** relative |
| AOV | Rp55,440 | Rp62,301 | **+12.4%** |

Both are statistically significant (p < 0.001). Stopping here, the decision looks obvious: roll it out.

## What the dashboard does not show

Three costs sit outside the growth dashboard:

**1. Shipping subsidy: Rp12,000 per order.** Variant A customers pay their own shipping (Rp11,829 on average). Variant B customers pay nothing; the company absorbs it.

**2. Cancellations nearly double. A = 2.91%, B = 5.45%.** The extra cancellations come from orders containing the two hero SKUs placed 18-31 May, while their stock at WH-CKR ran low and then out (zero from 22/23 to 30 May). Variant B's baskets contained those SKUs far more often (78% of orders versus 20%), so B took most of the hit. Outside those orders, cancellation was about 2% in both variants.

**3. Novelty effect.** Variant B conversion falls from 7.53% (weeks 1-2) to 6.11% (weeks 5-6). Part of the lift is curiosity, not a permanent behaviour change. Many teams stop a test as soon as the results read "significant". Stopped at week 2, this one would have projected far too optimistically.

---

## Where the money goes

Four metrics decide the outcome. Two favour B, two work against it.

| Metric | Favours | Gap | Rupiah effect per 1,000 users |
|---|---|---|---|
| Conversion rate | B | +0.92pp | +164,131 |
| Margin per order | B | +Rp2,577 | +147,419 |
| Cancellation rate | A | +2.54pp | included above |
| **Shipping subsidy** | **A** | **Rp12,000** | **-686,596** |
| Overlap: B's extra orders also carry the subsidy, partly offset by their higher margin | A | - | -67,498 |
| **Total** | | | **-442,543** |

The subsidy alone erases more than twice the combined value of B's two advantages. Per 1,000 users, the offer added about 9 orders; the other 59 would likely have been placed anyway, yet every one of them carries the subsidy.

### The funnel, step by step

| Step | Variant A | Variant B |
|---|---|---|
| Users exposed | 1,000 | 1,000 |
| Place an order | 58.9 (5.893%) | **68.1 (6.809%)** |
| Order survives cancellation | 57.2 (2.91% cancelled) | 64.4 (**5.45%** cancelled) |
| Margin per order | Rp22,915 | **Rp25,491** |
| Less shipping subsidy | Rp0 | **-Rp12,000** |
| Net value per order | **Rp22,915** | Rp13,491 |
| **Net contribution** | **Rp1,311,091** | Rp868,548 |

B wins 7.2 more completed orders, but each one returns 41% less. The deficit per order outweighs the surplus in volume.

**Difference: -Rp442,543 per 1,000 users, or -Rp255.3M a year.**

### Why this was easy to miss

The first three metrics live on the growth dashboard. The fourth does not: shipping cost sits in the ops and finance reports. A team reading only their own dashboard would have seen this promo as a clear win. The failure was not misreading the numbers; it was that the deciding number was on a different screen.

### One is fixable, one is structural

Cancellations are driven by the hero-SKU stockout at WH-CKR. Fix the stock and B's cancellation rate should fall toward A's: outside the affected orders it was already about 2%, in line with A.

The subsidy is structural. Free shipping means someone pays the courier, and that someone is the company. It can be reduced by raising the threshold, capping the subsidy or negotiating carrier rates, but it cannot be removed while the offer exists.

This is why fixing the warehouse alone does not rescue the promo: modelled with A's cancellation rate, B still returns only about Rp892,000 against A's Rp1,311,091.

---

## Break-even

The promo breaks even if shipping cost falls to **Rp5,126 per order**, less than half the current cost. This is what makes the promo worth retesting rather than abandoning.

---

## Recommendations

**1. Do not roll out the current version.**
At today's cost structure, every 1,000 exposed users returns Rp442,543 less contribution than running no promo.

**2. Re-test with a Rp75,000 threshold and a Rp10,000 subsidy cap.**
Shipping fees run Rp9,000-16,000 per order, higher on average outside Greater Jakarta. A Rp10,000 cap trims every fee above that level (about 70% of orders), but on its own it only lowers the average subsidy from about Rp11,800 to about Rp9,700, still close to double the Rp5,126 break-even. The higher threshold has to do the rest by lifting margin per order, and carrier rates are the third lever. The re-test measures whether the combination gets there.

**3. Read the lift by customer segment in the re-test.**
About 87 of every 100 free-shipping orders would likely have happened without the offer. Narrowing the offer only helps if some group responds more strongly, and in this test new visitors and existing customers responded alike (+0.92pp and +0.89pp). Targeting stays a hypothesis until the re-test shows a difference.

**4. Fix these two before any re-test:**

- **Android build 6.4.0 bucketing bug.** This build assigns 62.9% of users to variant B (z = 30.5), while build 6.3.2 sits at a clean 49.9%. While the bug exists, any experiment result will be questionable.
- **Hero SKU safety stock at WH-CKR.** KRK-BLD-080 and SGR-LMN-350 were out of stock for 8-9 days during the promo window. Days of cover for KRK-BLD-080 had already fallen below 7 on 17 May, six days before stock hit zero. A daily alert on that metric would have left time to reorder.

**Time required:** 2 weeks of re-testing once both fixes are in place.

---

## Method notes

- The Rp12,000 subsidy is a logistics-cost proxy based on what variant A customers paid (Rp11,829 on average), not an actual carrier rate.
- Rp255M annualises six weeks of experiment traffic over 52 weeks; seasonality is not modelled.
- A bucketing bug on Android build 6.4.0 skewed the split. The lift is clear on Android, iOS and mobile web (+0.91 to +1.25pp) and not detectable on desktop (+0.08pp, within noise), so its direction is reliable; its exact size is less certain.
- The rupiah effects in "Where the money goes" are measured one at a time; the overlap row reconciles them to the total.
- The Power BI dashboard shows contribution per 1,000 users about 0.3% lower (Rp1,307,129 and Rp865,692), because it sums the actual margins of completed orders, while the analysis script multiplies the average margin by the number of completed orders. The conclusion is the same.
