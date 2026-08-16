with users as (
    select user_id, variant, first_exposure_ts, device, app_version
    from {{ ref('stg_ab_exposures') }}
    where is_first_exposure
      and not is_bot
      and not is_multi_variant
),

first_order as (
    select
        u.user_id,
        o.order_id,
        o.order_ts_wib,
        o.gross_amount,
        o.margin_amount,
        o.shipping_fee,
        o.order_status,
        row_number() over (
            partition by u.user_id
            order by o.order_ts_wib
        ) as rn
    from users u
    join {{ ref('fct_orders') }} o
      on  o.customer_id  = u.user_id
      and o.order_ts_wib >= u.first_exposure_ts
      and o.order_ts_wib <  u.first_exposure_ts + interval '7 days'
)

select
    u.user_id,
    u.variant,
    u.first_exposure_ts,
    u.device,
    u.app_version,
    (f.order_id is not null)        as converted,
    f.order_id,
    f.order_ts_wib                  as conv_order_ts,
    f.gross_amount,
    f.margin_amount,
    f.shipping_fee,
    f.order_status
from users u
left join (select * from first_order where rn = 1) f using (user_id)
