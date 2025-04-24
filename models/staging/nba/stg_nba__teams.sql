with

source_table as (
    select * from {{ source('nba', 'teams') }}
),

final as (

    select
        id::integer as team_id,
        name as team_name,
        logo as team_logo_url,

        case
            when name = 'Toronto Raptors'
                then 'Canada'
            else 'USA'
        end as country_name,
  
        row_number() over (partition by id order by _airbyte_emitted_at desc) = 1 is_latest

    from source_table

)

select * from final where is_latest