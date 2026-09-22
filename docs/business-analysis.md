# Variant B (control group) TEST analysis

---

> **Number format:** This document uses the international (English)
>
> International format: **IDR 1,000,000.00** <br>
> Local format: **Rp1.000.000,00**

---

## Summary
Variant B (featuring a free shipping promotion) outperformed Variant A in two metrics: its conversion rate (based on orders placed) was 6.809% (equating to 68.1 per user), whereas Variant A (standard ordering without the shipping promo) stood at 5.893% (also equating to 68.1 per user). The outcome would be a loss of IDR 255 million per year if the promotion were extended to all customers; the total contribution revenue from Variant B was lower than that of Variant A, which did not include the promotion. 


**My recommendation: postpone the rollout**, revise it, and re-test using the updated version.

---

## What the Dashboard shows

| Metric | A | B | Change |
|---|---|---|---|
| Conversion | 5.893% | 6.809% | **+15.5%** relative |
| AOV | Rp55,440 | Rp62,301 | **+12.4%** |

## What the Dashboard does not show

Ada tiga hal yang tidak muncul di dashboard growth:

**1. Shipping subsidy cost: Rp.12,000 (IDR 12.000) per order.** Customers in Variant A covered their own shipping costs (averaging IDR 11,829), whereas for Variant B, the company fully covered shipping costs, meaning customers incurred no charge.

**2. Cancellations nearly double. A = 2.91%, B = 5.45%.** The cause is not the promo itself but a stockout of two hero SKUs at WH-CKR from 22-30 May. The promo generated demand the warehouse could not serve.

**3. Novelty effect. Variant B conversion falls from 7.53% (weeks 1-2) to 6.11% (weeks 5-6).** Part of the lift is curiosity, not a permanent behaviour change. A test stopped at week 2 which many teams do once results read "significant" would have projected far too optimistically.

---

## Where the money goes

Four metrics decide the outcome. Two favour B, two work against it.

| Metric | Favours | Gap | Rupiah effect per 1,000 users |
|---|---|---|---|
| Conversion rate | B | +0.92pp | +164,162 |
| Margin per order | B | +Rp2,576 | +147,386 |
| Cancellation rate | A | +2.54pp | included above |
| **Shipping subsidy** | **A** | **Rp12,000** | **-686,582** |

The subsidy alone erases more than twice the combined value of B's two
advantages. That single line decides the result.

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

B wins 7.2 more completed orders but each one returns 41% less. The
deficit per order outweighs the surplus in volume.

**Difference: -Rp442,543 per 1,000 users -> -Rp255.3M annualised.**

### Why this was easy to miss

The first three metrics live on the growth dashboard. The fourth does
not, shipping cost sits in the ops and finance reports. A team reading
only their own dashboard would have seen this promo as a clear win. The
failure was not misreading the numbers; it was that the deciding number
was on a different screen.

### One is fixable, one is structural

Cancellations are driven by the WH-CKR stockout, not by the promo
itself. Fix the stock and B's cancellation rate should fall toward A's.

The subsidy is structural. Free shipping means someone pays the courier,
and that someone is the company. It can only be reduced by raising the
threshold, capping the subsidy, or negotiating carrier rates never
removed while the offer exists.

This is why fixing the warehouse alone does not rescue the promo:
modelled with A's cancellation rate, B still returns only Rp891,871
against A's Rp1,311,085.


## Break-even

The promo breaks even if shipping cost falls to **Rp5,126 per order** 
less than half the current cost. This is what makes the promo worth
retesting rather than abandoning.

---

## Recommendations

**1. Do not roll out the current version.**
At today's cost structure, every 1,000 exposed users costs the company Rp442,543.

**2. Re-test with a Rp75,000 threshold and a Rp10,000 subsidy cap.** A higher threshold raises margin per order; a cap limits the loss on low-value baskets. Together they move the effective cost toward the Rp5,126 break-even point.

**3. Target new and lapsed customers only.** Part of the subsidy currently goes to shoppers who would have bought anyway. Restricting it to inactive segments makes each subsidised rupiah work on genuinely incremental demand.

**4. Fix these two before any re-test:**

- **Android build 6.4.0 bucketing bug.** This build assigns 62.9% of users to variant B (z = 30.5), while build 6.3.2 sits at a clean 49.9%. While the bug exists, any experiment result will be questionable.
- **Hero SKU safety stock at WH-CKR.** KRK-BLD-080 and SGR-LMN-350 were out of stock for 8-9 days during the promo window. Days of cover had already fallen below 7 on 16 May, a full week before stock hit zero. A daily alert on that metric would have left time to reorder.
Time required: 2 weeks of re-testing once both fixes are in place.