select
    sku_code, sku_name, brand, category, pack_size,
    unit_cogs, list_price,
    list_price - unit_cogs as margin_per_unit,
    launch_date, status
from {{ ref('stg_sku_master') }}
