with base as (
    select
        trim(sku_code)                          as sku_code,
        sku_name                                as sku_name,
        initcap(brand)                          as brand,
        category,
        pack_size,
        unit_cogs::int                          as unit_cogs,
        list_price::int                         as list_price,
        launch_date::date                       as launch_date,
        status,
        row_number() over (
            partition by trim(sku_code)
            order by (sku_code = trim(sku_code)) desc
        )                                       as rn
    from {{ source('raw','sku_master') }}
)
select sku_code, sku_name, brand, category, pack_size,
       unit_cogs, list_price, launch_date, status
from base
where rn = 1
