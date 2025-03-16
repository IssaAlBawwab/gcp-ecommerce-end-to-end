{{ config(materialized='table') }}

select
    date(se.event_time) as event_date,
    se.user_id,
    se.user_session,
    se.event_time,
    se.event_type,
    se.product_id,
    se.category_code,
    se.brand,
    row_number() over (partition by se.user_session order by se.event_time) as session_event_number,
    timestamp_diff(se.event_time, lag(se.event_time) over (partition by se.user_session order by se.event_time), SECOND) as time_difference_from_previous,
    lag(se.event_type) over (partition by se.user_session order by se.event_time) as previous_event_type,
    min(se.event_time) over (partition by se.user_session) as session_start_time,
    max(se.event_time) over (partition by se.user_session) as session_end_time,
    timestamp_diff(max(se.event_time) over (partition by se.user_session), min(se.event_time) over (partition by se.user_session), HOUR) as session_duration_hours
from {{ ref('stg_ecommerce_events') }} se
where se.user_session is not null
order by se.user_session, se.event_time