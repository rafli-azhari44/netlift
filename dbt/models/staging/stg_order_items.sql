with cleaned as (
    select
        item_id,
        order_id,
        upper(trim(sku_code))                   as sku_code_raw,
        qty::int                                as qty,
        nullif(regexp_replace(unit_price, '[^0-9-]', '', 'g'), '')::int
                                                as unit_price
    from {{ source('raw','order_items_d2c') }}
)
select
    item_id,
    order_id,
    case when sku_code_raw = 'KRK-BLD-80' then 'KRK-BLD-080'
         else sku_code_raw end                  as sku_code,
    qty,
    unit_price,
    (qty < 0)                                   as is_return
from cleaned
where sku_code_raw <> 'SKU-TEST'
