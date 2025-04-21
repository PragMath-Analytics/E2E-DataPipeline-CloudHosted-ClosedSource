with

source_table as (
    select * from {{ source('franchises', 'head_coaches') }}
),

final as (

    select 
        "ID" as head_coach_id,
        "HEAD_COACH" as head_coach,
        "TEAM" as team_name,
        "DIVISION" as division,
        "CONFERENCE" as conference,
        date("START_DATE", 'MMMMDD, YYYY') as start_date,
        date("AS_OF_DATE", 'MMMMDD, YYYY') as as_of_date,
        date_part('year', date("AS_OF_DATE", 'MMMMDD, YYYY')) 
            - date_part('year', date("START_DATE", 'MMMMDD, YYYY')) as years_active

    from source_table

)

select * from final