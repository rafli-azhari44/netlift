with base as (
    select
        exposure_id,
        user_id,
        variant,
        first_exposure_ts::timestamp            as first_exposure_ts,
        device,
        nullif(app_version, '')                 as app_version
    from {{ source('raw','ab_exposures') }}
    where first_exposure_ts::timestamp >= '2026-05-04'
      and first_exposure_ts::timestamp <  '2026-06-15'
),
flagged as (
    select *,
        count(*) over (partition by user_id)    as n_exposures,
        (min(variant) over (partition by user_id)
         <> max(variant) over (partition by user_id))
                                                as is_multi_variant,
        row_number() over (
            partition by user_id
            order by first_exposure_ts
        )                                       as rn
    from base
)
select
    exposure_id, user_id, variant, first_exposure_ts, device, app_version,
    n_exposures,
    is_multi_variant,
    (n_exposures > 20)                          as is_bot,
    (rn = 1)                                    as is_first_exposure
from flagged
