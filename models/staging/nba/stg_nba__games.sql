with

source_table as (
    select * from {{ source('nba', 'games') }}
),

final as (

    select
        id::int as game_id,
        date::timestamp as game_at,
        date::date as game_date,
        time::time as game_time,
        
        -- teams
        teams:away.id::int as away_team_id,
        teams:away.name::string as away_team_name,
        teams:home.id::int as home_team_id,
        teams:home.name::string as home_team_name,

        -- league & season
        league:id::int as league_id,
        replace((league:name)::string, '"','') as league_name,
        replace((league:season)::string, '"','') as season,
        
        -- away team scoring
        scores:away.total::int as away_team_score_total,
        scores:away.quarter_1::int as away_team_score_quarter_1,
        scores:away.quarter_2::int as away_team_score_quarter_2,
        scores:away.quarter_3::int as away_team_score_quarter_3,
        scores:away.quarter_4::int as away_team_score_quarter_4,
        (coalesce(scores:away.over_time, '0'))::int as away_team_score_overtime,
 
        -- home team scoring
        scores:home.total::int as home_team_score_total,
        scores:home.quarter_1::int as home_team_score_quarter_1,
        scores:home.quarter_2::int as home_team_score_quarter_2,
        scores:home.quarter_3::int as home_team_score_quarter_3,
        scores:home.quarter_4::int as home_team_score_quarter_4,
        (coalesce(scores:home.over_time, '0'))::int as home_team_score_overtime,

        -- Custom Metrics
        case
            when scores:home.total::int > scores:away.total::int
                then true
            else false
        end as is_home_team_win,
   
        case
            when scores:home.total::int < scores:away.total::int
                then true
            else false
        end as is_away_team_win,

        abs(scores:home.total::int 
            - scores:away.total::int) as point_differential,


        -- status
        replace(status:long::string, '"','') as status_long,
        replace(status:short::string, '"','') as status_short,
        
        -- country
        country:id::int as country_id,
        replace(country:code::string, '"','') as country_code,
        replace(country:name::string, '"','') as country_name,

        timezone,
        cast(timestamp::int as timestamp) as created_at,

        row_number() over (partition by id order by _airbyte_emitted_at desc) = 1 is_latest

    from source_table

)

select * from final where is_latest