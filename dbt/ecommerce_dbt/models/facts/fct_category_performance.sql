{{ config(materialized='table') }}

select
    date(se.event_time) as event_date,
    se.category_code,
    count(case when se.event_type = 'view' then 1 end) as number_of_views,
    count(case when se.event_type = 'add_to_cart' then 1 end) as number_of_add_to_cart,
    count(case when se.event_type = 'purchase' then 1 end) as number_of_purchases,
    sum(case when se.event_type = 'purchase' then se.price else 0 end) as total_revenue,
    count(distinct case when se.event_type = 'view' then se.user_id end) as number_of_unique_viewers,
    count(distinct case when se.event_type = 'purchase' then se.user_id end) as number_of_unique_buyers
from {{ ref('stg_ecommerce_events') }} se
group by 1, 2