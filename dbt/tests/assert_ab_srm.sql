--- Alarm Sample Ratio Mismatch.
--- It is considered a failure if the proportion of variant B deviates by more than 1 percentage point from 50%
--- In this dataset it can be fail (B = 52,66%) -> proof that the alarm works.
with s as (
    select
        avg(case when variant = 'B' then 1.0 else 0 end) as b_share,
        count(*)                                          as n
    from {{ ref('fct_ab_users') }}
)
select *
from s
where abs(b_share - 0.5) > 0.01
