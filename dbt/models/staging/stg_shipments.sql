select
    shipment_id,
    order_id,
    warehouse_id,
    courier,
    ship_date::date                             as ship_date,
    promised_date::date                         as promised_date,
    nullif(delivered_date, '')::date            as delivered_date,
    fulfil_type,
    dest_city,
    (nullif(delivered_date,'') is null)         as is_scan_missing,
    case
        when nullif(delivered_date,'') is null then null
        else (delivered_date::date <= promised_date::date
              and fulfil_type = 'full')
    end                                         as is_otif
from {{ source('raw','shipments_d2c') }}
