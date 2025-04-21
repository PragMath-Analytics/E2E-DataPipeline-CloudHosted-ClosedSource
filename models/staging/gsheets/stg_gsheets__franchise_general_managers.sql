with

source_table as (
    select * from {{ source('franchises', 'general_managers') }}
),

final as (

    select 
        "ID" as general_manager_id, 
        "TEAM" as team_name, 
        "COLLEGE" as college_name, 
        "DIVISION" as division, 
        "CONFERENCE" as conference, 
        
        case 
            when "GENERAL_MANAGER" = 'Vacant' 
            then null
            else "GENERAL_MANAGER"
        end as general_manager, 
        
        "PROFESSIONAL_CAREER" as professional_career,
        "YEAR_HIRED"::int as year_hired, 
        date("AS_OF_DATE", 'MMMMDD, YYYY') as as_of_date,        
        date_part('year', date("AS_OF_DATE", 'MMMMDD, YYYY')) - "YEAR_HIRED"::int as years_active

    from source_table

)

select * from final