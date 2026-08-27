-- S13: BOM explosion for a 50,000 pcs production run of KRK-BLD-080
--
-- The BOM is nested: KRK-BLD-080 needs Balado Seasoning Mix, and that
-- mix has its own recipe. Depth is not stored anywhere — it is implied
-- by the parent/component chain, so the query cannot assume how many
-- levels exist.
--
-- WITH RECURSIVE handles this. The anchor takes the direct components of
-- the finished good; the recursive part joins the table back to itself
-- (b.parent_code = e.component_code) to find each component's own
-- children. It stops on its own when a pass returns no new rows — raw
-- materials have no children.
--
-- Quantities multiply down the chain: e.total_qty carries the parent's
-- computed quantity into the child. 50,000 x 0.012 = 600 kg of mix,
-- then 600 x 0.400 = 240 kg of chili powder.
--
-- Reading the result: levels must NOT be summed together. The 600 kg of
-- Balado Mix already contains the 240 kg of chili powder. Purchasing
-- only buys the leaves — the level-2 raw materials plus the level-1
-- items that have no recipe of their own (potato, oil, film). The mix
-- itself is made in-house.
--
-- Result: 8 rows across 2 levels.

WITH RECURSIVE explosion AS (
    -- ANCHOR: direct components of finished products
    SELECT
        b.component_code,
        b.component_name,
        b.uom,
        b.qty_per_unit::numeric * 50000  AS total_qty,
        1                                AS level
    FROM raw.bom  b
    WHERE b.parent_code = 'KRK-BLD-080'

    UNION ALL

    -- RECURSIVE: Go down one level and multiply sequentially.
    SELECT
        b.component_code,
        b.component_name,
        b.uom,
        b.qty_per_unit::numeric * e.total_qty  AS total_qty,
        e.level + 1                            AS level
    FROM raw.bom     b
    JOIN explosion   e  ON b.parent_code = e.component_code
)
SELECT
    level,
    component_code,
    component_name,
    ROUND(total_qty, 1)  AS total_qty,
    uom
FROM explosion
ORDER BY level, component_code;