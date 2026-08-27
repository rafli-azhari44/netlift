-- S11: SRM detection in pure SQL
--
-- SRM = Sample Ratio Mismatch: the A/B split deviates from the intended
-- 50/50. A skewed split means something influenced who landed in which
-- variant, and that something may also influence the outcome — which
-- makes the experiment result unreadable.
--
-- Population cleaned first: bots, users exposed to both variants, and
-- repeat exposures. 68,590 rows -> 66,570 people.
--
-- z = (p - 0.5) / sqrt(0.25/n), flagged at |z| > 3. Numerator cast to
-- numeric — integer division would return 0 for every share.
--
-- Two queries below: the investigation narrows from device to app
-- version. "Android is skewed" (z=23.5) becomes "build 6.4.0 is skewed"
-- (z=30.5) while 6.3.2 is clean (z=-0.1) — specific enough for
-- engineering to trace to a commit.


-- Query 1 of 2: by device
WITH base AS (
    SELECT user_id, variant, device, app_version
    FROM analytics_staging.stg_ab_exposures
    WHERE is_bot            = FALSE
      AND is_multi_variant  = FALSE
      AND is_first_exposure = TRUE
),
by_device AS (
    SELECT
        device,
        COUNT(*)                                              AS n,
        COUNT(*) FILTER (WHERE variant = 'B')::numeric
            / COUNT(*)                                        AS p_b
    FROM base
    GROUP BY device
)
SELECT
    device,
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