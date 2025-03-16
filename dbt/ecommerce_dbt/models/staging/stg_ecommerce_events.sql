{{ config(materialized='view') }}

select

    format_timestamp('%Y-%m-%d %H:%M:%S', event_time) as event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session
from {{ source('staging', 'kafka_ecom_events') }}