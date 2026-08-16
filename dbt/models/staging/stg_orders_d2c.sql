with dedup as (
    select *,
        row_number() over (
            partition by order_id
            order by ingested_at desc
        ) as rn
    from {{ source('raw','orders_d2c') }}
)
select
    order_id,
    customer_id,
    case
        when order_ts like '%Z'
            then (order_ts::timestamptz at time zone 'Asia/Jakarta')
        else order_ts::timestamp
    end                                         as order_ts_wib,
    channel,
    payment_method,
    shipping_fee::int                           as shipping_fee,
    dest_city,
    order_status,
    ingested_at::timestamp                      as ingested_at
from dedup
where rn = 1
