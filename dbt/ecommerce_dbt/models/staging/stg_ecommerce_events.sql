{{ config(materialized='view') }}

select

    extract(DATETIME from event_time) as event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session
from {{ source('staging', 'kafka_ecom_events') }}