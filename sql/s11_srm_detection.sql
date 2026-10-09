-- =====================================================
-- S11: SRM detection in pure SQL
-- =====================================================
-- SRM = Sample Ratio Mismatch: the A/B split deviates from the intended
--   50/50. A skewed split means something influenced who landed in which
--   variant, and that something may also influence the outcome, which
--   makes the experiment result unreadable.
--
-- Population: the raw log has 68,590 exposure rows. Staging keeps the
--   68,270 inside the test window (4 May - 14 Jun). Removing bots, users
--   exposed to both variants and repeat exposures leaves 66,570 people.
--
-- z = (p - 0.5) / sqrt(0.25 / n), flagged at |z| > 3. The numerator is
--   cast to numeric because integer division would return 0 for every
--   share.
--
-- The question asks for the total and the per-device split, so query 1
--   uses ROLLUP to add an "all devices" row. The investigation then
--   narrows from device to app version:
--   - Overall the split is off: B share 52.7%, z = 13.7.
--   - By device, only Android is skewed (z = 23.5).
--   - Within Android, build 6.4.0 is skewed (B share 62.9%, z = 30.5)
--     while 6.3.2 is clean (z = -0.1). That is specific enough for
--     engineering to trace to a commit.
--
-- Result: query 1 returns 5 rows (4 devices plus all devices), query 2
--   returns 2 rows (one per Android build).
-- =====================================================


-- Query 1 of 2: overall and by device
WITH base AS (
    SELECT user_id, variant, device, app_version
    FROM analytics_staging.stg_ab_exposures
    WHERE is_bot            = FALSE
      AND is_multi_variant  = FALSE
      AND is_first_exposure = TRUE
),
by_device AS (
    SELECT
        COALESCE(device, 'all devices')                       AS device_group,
        COUNT(*)                                              AS n,
        COUNT(*) FILTER (WHERE variant = 'B')::numeric
            / COUNT(*)                                        AS p_b
    FROM base
    GROUP BY ROLLUP (device)
)
SELECT
    device_group,
    n,
    ROUND(p_b * 100, 1)                                       AS b_share_pct,
    ROUND((p_b - 0.5) / SQRT(0.25 / n), 1)                    AS z_score,
    CASE WHEN ABS((p_b - 0.5) / SQRT(0.25 / n)) > 3
         THEN 'SRM!' ELSE 'ok' END                            AS flag
FROM by_device
ORDER BY ABS((p_b - 0.5) / SQRT(0.25 / n)) DESC;


-- Query 2 of 2: android only, broken down by app version
WITH base AS (
    SELECT user_id, variant, device, app_version
    FROM analytics_staging.stg_ab_exposures
    WHERE is_bot            = FALSE
      AND is_multi_variant  = FALSE
      AND is_first_exposure = TRUE
),
by_version AS (
    SELECT
        app_version,
        COUNT(*)                                              AS n,
        COUNT(*) FILTER (WHERE variant = 'B')::numeric
            / COUNT(*)                                        AS p_b
    FROM base
    WHERE device = 'android'
    GROUP BY app_version
)
SELECT
    app_version,
    n,
    ROUND(p_b * 100, 1)                                       AS b_share_pct,
    ROUND((p_b - 0.5) / SQRT(0.25 / n), 1)                    AS z_score,
    CASE WHEN ABS((p_b - 0.5) / SQRT(0.25 / n)) > 3
         THEN 'SRM!' ELSE 'ok' END                            AS flag
FROM by_version
ORDER BY ABS((p_b - 0.5) / SQRT(0.25 / n)) DESC;
