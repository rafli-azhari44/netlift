select
    snapshot_date::date                         as snapshot_date,
    warehouse_id,
    upper(trim(sku_code))                       as sku_code,
        case
        when qty_on_hand::int < 0
            then null                           -- negative stock is invalid; checked first so carton rows are nulled too
        when warehouse_id = 'WH-BDG' and sku_code like '%-1L0'
            then qty_on_hand::int * 12          -- WH-BDG reports 1L SKUs in cartons of 12
        else qty_on_hand::int
    end                                         as qty_on_hand,
    (qty_on_hand::int < 0)                      as is_invalid_negative
from {{ source('raw','inventory_daily') }}
