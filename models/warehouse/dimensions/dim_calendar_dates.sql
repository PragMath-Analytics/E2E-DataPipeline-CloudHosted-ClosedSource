with

calendar_dates as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2018-01-01' as date)",
        end_date="cast('2050-12-31' as date)"
    )
    }}

),

final as (

    select
        -- Surrogate Key
        {{ dbt_utils.generate_surrogate_key(
            ['date(date_day)']
        )}} as calendar_date_sk,
 
        -- Descriptive Values
        date_day::date as date_day,
        dayofweek(date_day) + 1 as day_of_week_number,
        dayofmonth(date_day) as day_of_month_number,
        dayofyear(date_day) as day_of_year_number,

        week(date_day) as week_of_year_number,
        month(date_day) as month_of_year_number,
        quarter(date_day) as quarter_of_year_number,
        year(date_day) as year_number,

        dayname(date_day) as short_weekday_name,
        
        case dayofweek(date_day)
            when 0 then 'Sunday'
            when 1 then 'Monday'
            when 2 then 'Tuesday'
            when 3 then 'Wednesday'
            when 4 then 'Thursday'
            when 5 then 'Friday'
            when 6 then 'Saturday'
        end as full_weekday_name,
        
        monthname(date_day) as short_month_name,
        to_char(date_day,'MMMM') as full_month_name,

        concat(monthname(date_day), ' ', year(date_day)) as short_month_year,

        concat(to_char(date_day,'MMMM'), ' ', year(date_day)) as full_month_year

    from calendar_dates

)

select * from final
