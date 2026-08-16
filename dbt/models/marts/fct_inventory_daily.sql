select
    v.*,
    (v.qty_on_hand = 0) as is_stockout
from {{ ref('stg_inventory_daily') }} v
