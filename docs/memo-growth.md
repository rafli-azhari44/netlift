# Free shipping test: what worked, and the version that can win

**To:** Pak Danu, Head of Growth
**From:** Data Team
**Re:** "Free shipping over Rp50K" test, 4 May - 14 June 2026

Pak Danu,

The free-shipping test did what it was designed to do. Conversion rose from 5.89% to 6.81%, a statistically solid 15.5% lift. Average order value grew from Rp55,440 to Rp62,301, with over half of variant B's orders landing just above the threshold, between Rp50,000 and Rp60,000. The offer changes behaviour, and that part is worth keeping.

One cost does not appear on the growth dashboard. In variant B, the company pays the courier on every order, about Rp12,000 each. Per 1,000 users, the offer added about 9 orders; the other 59 would most likely have come anyway, yet each of them now ships at our cost. B's extra margin, Rp2,577 per order, covers about a fifth of that subsidy.

Per 1,000 users, variant A returns Rp1,311,091 in contribution and variant B Rp868,548. At full rollout, that gap comes to roughly **Rp255 million less contribution per year** than running no promo.

Two problems need fixing before the next test:

1. **A bucketing bug on Android build 6.4.0** sent 62.9% of its users to variant B instead of half. The lift is clear on iOS and mobile web, where the split was clean, but the next test needs a clean split everywhere.
2. **A stockout at WH-CKR.** Both hero SKUs ran out for 8-9 days in late May. Variant B's baskets contained them far more often (78% of orders versus 20%), which pushed its cancellation rate to 5.45% against 2.91% for A.

The promo breaks even if shipping cost falls to Rp5,126 per order, so the idea needs a sharper design, not a shelf. The version I would propose:

- Threshold raised to Rp75,000, so each subsidised order carries more margin
- Subsidy capped at Rp10,000 per order
- Lift read separately for new and returning customers; in this test both responded alike (+0.92 vs +0.89 points), so targeting stays a hypothesis
- A two-week re-test once the Android fix ships and hero-SKU safety stock is set at WH-CKR

If this direction works for you, I can bring a one-page test design to a 30-minute review this week, at a time that suits you, ready to launch once engineering confirms the Android fix.
