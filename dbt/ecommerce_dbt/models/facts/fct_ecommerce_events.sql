{{ config(materialized='table') }}

select
    date(se.event_time) as event_date,
    se.event_type,
    se.product_id,
    se.category_code,
    se.brand,
    count(*) as total_events,
    count(distinct se.user_id) as unique_users,
    sum(case when se.event_type = 'purchase' then se.price else 0 end) as total_revenue
from {{ ref('stg_ecommerce_events') }} se
group by 1, 2, 3, 4, 5