select
    s.*,
    date_trunc('week',  s.ship_date)::date  as ship_week,
    date_trunc('month', s.ship_date)::date  as ship_month
from {{ ref('stg_shipments') }} s
