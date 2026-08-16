select
    snapshot_date::date                         as snapshot_date,
    warehouse_id,
    upper(trim(sku_code))                       as sku_code,
    case
        when warehouse_id = 'WH-BDG' and sku_code like '%-1L0'
            then qty_on_hand::int * 12          -- cardboard report -> pcs
        when qty_on_hand::int < 0
            then null                           -- negative stock = invalid
        else qty_on_hand::int
    end                                         as qty_on_hand,
    (qty_on_hand::int < 0)                      as is_invalid_negative
from {{ source('raw','inventory_daily') }}
