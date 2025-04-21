with

source_table as (
    select * from {{ source('franchises', 'actives') }}
),

final as (

    select 
        "TEAM_ID"::int as team_id,
        "FRANCHISE_ID"::int as franchise_id,
        "FRANCHISE_NAME" as franchise_name,
        "URL" as url,
        "START"::int as year_started,
        "END"::int as year_ended,
        "YEARS"::int as years_active,
        "GP"::int as games_played,
        "WINS"::int as wins,
        "LOSSES"::int as losses,
        "WIN_"::numeric / 100 as winning_percentage,
        "PO"::int as playoffs_made,
        "DIV_TITLES"::int as division_titles,
        "CONF_TITLES"::int as conference_titles,
        "LEAGUE_TITLES"::int as league_titles,
        "END" is null as is_current

    from source_table

)

select * from final
