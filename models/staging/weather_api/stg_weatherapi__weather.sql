with

source_table as (
    select *
    from {{ source('weather', 'weather_data') }}
),

final as (

    select 
        request_query             as city_country,
        location_name             as city,
        location_country          as country,
        location_region           as region,
        CAST(location_lat AS DECIMAL(10, 6))  as latitude,
        CAST(location_lon AS DECIMAL(10, 6))  as longitude,
        location_timezone_id      as timezone,
        CAST(location_localtime AS TIMESTAMP) as local_time,
        current_temperature       as temperature_c,
        current_weather_code      as weather_code,
        current_weather_descriptions as weather_desc,
        current_wind_speed        as wind_speed_kph,
        current_wind_degree       as wind_degree,
        current_wind_dir          as wind_direction,
        current_pressure          as pressure_mb,
        current_precip            as precip_mm,
        current_humidity          as humidity_pct,
        current_cloudcover        as cloud_cover_pct,
        current_feelslike         as feels_like_c,
        current_uv_index          as uv_index,
        current_visibility        as visibility_km,
        current_is_day            as is_day

    from source_table
)

select * from final