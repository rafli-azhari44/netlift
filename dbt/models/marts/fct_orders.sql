with items as (
    select
        i.order_id,
        sum(case when not i.is_return
                 then i.qty * i.unit_price else 0 end)       as gross_amount,
        sum(case when not i.is_return
                 then i.qty * (i.unit_price - s.unit_cogs)
                 else 0 end)                                 as margin_amount,
        sum(case when not i.is_return then i.qty else 0 end) as total_qty,
        bool_or(i.sku_code in ('KRK-BLD-080','SGR-LMN-350')) as has_hero,
        count(*) filter (where not i.is_return)              as n_lines
    from {{ ref('stg_order_items') }} i
    left join {{ ref('dim_sku') }} s using (sku_code)
    group by 1
)
select
    o.order_id,
    o.customer_id,
    o.order_ts_wib,
    o.order_ts_wib::date            as order_date,
    o.channel,
    o.payment_method,
    o.shipping_fee,
    o.dest_city,
    o.order_status,
    coalesce(i.gross_amount, 0)     as gross_amount,
    coalesce(i.margin_amount, 0)    as margin_amount,
    coalesce(i.total_qty, 0)        as total_qty,
    coalesce(i.has_hero, false)     as has_hero,
    coalesce(i.n_lines, 0)          as n_lines,
    sh.warehouse_id,
    sh.is_otif
from {{ ref('stg_orders_d2c') }} o
left join items i using (order_id)
left join {{ ref('stg_shipments') }} sh using (order_id)
