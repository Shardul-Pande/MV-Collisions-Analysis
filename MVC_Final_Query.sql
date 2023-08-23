------------- number of collisions

select count(collision_id) as 'Number of Collisions'
from [NYC_Final].[dbo].[fct_collision_crashes]



------------- number of people by role, such as pedestrian, injured or died

select a.PED_ROLE as 'Role Type', b.[PERSON_INJURY] as 'Injury Type', 
count([UNIQUE_ID]) as 'Total Number of People Injured/Killed'

from [NYC_Final].[dbo].[fct_collision_persons] fp
join [NYC_Final].[dbo].[Dim_PERSON_INJURY] b on fp.[PERSON_INJURY_SK] = b.PERSON_INJURY_SK
join [NYC_Final].[dbo].[Dim_PED_ROLE] a on fp.[PED_ROLE_SK] =a.[PED_ROLE_SK]

where b.PERSON_INJURY in ('Injured', 'Killed') and a.PED_ROLE <> 'No Value'
group by b.[PERSON_INJURY], a.PED_ROLE;


--number of people by role, such as pedestrian, injured or died

SELECT PERSON_TYPE as Person_type,
sum(case when PERSON_INJURY = 'Injured' then 1 else 0 end) AS Injured,
sum(case when PERSON_INJURY = 'Killed' then 1 else 0 end) AS Killed,
sum(case when PERSON_INJURY = 'Unspecified' then 1 else 0 end) AS Unspecified 
 FROM [NYC_Final].[dbo].[stg_nyc_mv_collision_persons] 
WHERE PERSON_TYPE is not null
GROUP BY PERSON_TYPE



----- How Many Car Accidents Are There in NYC Every Year?

Select YEAR([collision_dt]) as Collision_Year, count(*) as Collision_Count
from [NYC_Final].[dbo].[fct_collision_crashes]

group by YEAR([collision_dt])
order by YEAR([collision_dt])



-------- Which Boroughs in New York City Have the Most Accidents?

Select b.Borough,count(*) as Collision_Count
from [NYC_Final].[dbo].[fct_collision_crashes] a 
join [NYC_Final].[dbo].[dim_arrest_borough] b on a.borough_sk =b.borough_sk

group by b.borough
order by count(*) desc



------------ How Many NYC Car Accidents Result in an Injury?

Select count(*) as Collisions_Resulting_Injury from [NYC_Final].[dbo].[fct_collision_crashes] 
where number_of_persons_injured!=0



----------- Which NYC Borough Has the Most Fatal Car Accidents?

Select b.Borough,count(*) as Collision_Count
from [NYC_Final].[dbo].[fct_collision_crashes] a 

join [NYC_Final].[dbo].[dim_arrest_borough] b 
on a.borough_sk =b.borough_sk where [number_of_persons_killed]!=0

group by b.borough
order by count(*) desc


---------- When Do Most New York City Car Accidents Happen?

with x as (Select Case When [collision_hour] >=0 and [collision_hour] <6 Then 'Late Night (12AM-6AM)'
            When [collision_hour] >=6 and [collision_hour]<9 Then 'Morning Busy Route (6AM-9AM)'    
            When [collision_hour] >=9 and [collision_hour]<12 Then 'Late in the Morning Commute (9AM-12PM)'    
            When [collision_hour] >=12 and [collision_hour]<15 Then 'Commuting Afternoon(12PM-3PM)'
            When [collision_hour] >=15 and [collision_hour]<18 Then 'Late Afternoon Commute (3PM-6PM)'
            When [collision_hour] >=18 and [collision_hour]<21 Then 'Evening Commute (6PM-9PM)'
            When [collision_hour] >=21 and [collision_hour]<24 Then 'Night Commute (9PM-12AM)' 
			END Time_When_Most_Accidents_Happened, collision_hour
from [NYC_Final].[dbo].[fct_collision_crashes])  

Select Time_When_Most_Accidents_Happened,count(collision_hour) as collision_count
from x
group by Time_When_Most_Accidents_Happened order by count(collision_hour) desc




--------How Common Are Bicycle Accidents in NYC?

Select year([collision_dt]) as 'Year of collision', 
	   DATENAME(month,[collision_dt]) as 'Month of collision',
       count(c.PERSON_TYPE) as 'Bicyclist_Count'

from [NYC_Final].[dbo].[fct_collision_crashes] a  
join [NYC_Final].[dbo].[fct_collision_persons] b on a.collision_id=b.COLLISION_ID
join [NYC_Final].[dbo].[Dim_PersonType] c on b.PERSON_TYPE_SK=c.PERSON_TYPE_SK 
where c.PERSON_TYPE='BICYCLIST'  

group by year([collision_dt]),DATENAME(month,[collision_dt])
order by year([collision_dt]) asc ,count(c.PERSON_TYPE) desc



-------- How Often Are Pedestrians Involving New York Traffic Accidents?



Select year([collision_dt]) as 'year of collision' ,
       DATENAME(month,[collision_dt]) as 'month of collision',
       count(c.PERSON_TYPE) as 'Pedestrian_count'

from [NYC_Final].[dbo].[fct_collision_crashes] a  
join [NYC_Final].[dbo].[fct_collision_persons] b on a.collision_id=b.COLLISION_ID
join [NYC_Final].[dbo].[Dim_PersonType] c on b.PERSON_TYPE_SK=c.PERSON_TYPE_SK 
where c.PERSON_TYPE='PEDESTRIAN'  

group by year([collision_dt]),DATENAME(month,[collision_dt])
order by year([collision_dt]) asc ,count(c.PERSON_TYPE) desc




----------How Many Motorcyclists are Injured or Killed in NYC Accidents?

Select sum([number_of_motorist_injured]+[number_of_motorist_killed]) as 'motorcyclist_Killed_OR_Injured_NYC' 
from [NYC_Final].[dbo].[fct_collision_crashes]


--------- OR by borough
Select b.Borough, sum([number_of_motorist_injured]+[number_of_motorist_killed]) as 'Motorcyclist_Killed_or_Injured_NYC'
from [NYC_Final].[dbo].[fct_collision_crashes] a

join [NYC_Final].dbo.dim_arrest_borough b on a.borough_sk=b.Borough_sk  

group by b.Borough 
order by sum([number_of_motorist_injured]+[number_of_motorist_killed]) desc



---------- Are Trucks Involved in Many New York Accidents?

Select  year(c.collision_dt) as 'Year of collision' ,
	    DATENAME(month,c.collision_dt) as 'Month of collision',
		count(a.VEHICLE_MAKE_SK) as No_of_Trucks_Involved_in_Collision
from [NYC_Final].[dbo].[fct_Collisions_Vehicles] a

join [NYC_Final].[dbo].[Dim_VEHICLE_MAKE] b  on a.VEHICLE_MAKE_SK=b.VEHICLE_MAKE_SK
join [NYC_Final].[dbo].[fct_collision_crashes] c on a.COLLISION_ID=c.collision_id

where VEHICLE_MAKE like '%TRU%'

group by year(c.collision_dt),DATENAME(month,c.collision_dt)
order by year(c.collision_dt) asc ,count(a.VEHICLE_MAKE_SK) desc



------------------- Collisions by Causes
select
		b.[CONTRIBUTING_FACTOR] as 'Collision Cause'
		,count([TABLE_SK]) as 'Collision factor'
from [NYC_Final].[dbo].[fct_collision_persons_contributing_factors] a
join [NYC_Final].[dbo].[Dim_CONTRIBUTING_FACTOR] b on a.[CONTRIBUTING_FACTOR_SK] = b.CONTRIBUTING_FACTOR_SK
where b.[CONTRIBUTING_FACTOR] NOT IN ('Unspecified')
group by b.[CONTRIBUTING_FACTOR]
order by 2 desc;










------- Trend (granularity month, year), also seasonality, i.e., Spring, Summer, Fall and Winter---

with x as (select Case When MONTH([collision_day]) in (3,4,5) then 'Spring'
            When MONTH([collision_day]) in (6,7,8) then 'Summer'
            When MONTH([collision_day]) in (9,10,11) then 'Fall'
            When MONTH([collision_day]) in (12,1,2) then 'Winter'
            END as 'Seasonality',MONTH([collision_day]) as month_number
			from [NYC_Final].[dbo].[fct_collision_crashes])

			select Seasonality,count(month_number) as number_of_accidents_by_seasonality from x group by Seasonality order by count(month_number) desc



-------------- Seasonality

with x as (select Case When MONTH([collision_day]) in (3,4,5) then 'Spring'
            When MONTH([collision_day]) in (6,7,8) then 'Summer'
            When MONTH([collision_day]) in (9,10,11) then 'Fall'
            When MONTH([collision_day]) in (12,1,2) then 'Winter'
            END as 'Seasonality',Case When [collision_hour] >=0 and [collision_hour] <6 Then 'Late Night (12AM-6AM)'
            When [collision_hour] >=6 and [collision_hour]<9 Then 'Morning Busy Route (6AM-9AM)'    
            When [collision_hour] >=9 and [collision_hour]<12 Then 'Late in the Morning Commute (9AM-12PM)'    
            When [collision_hour] >=12 and [collision_hour]<15 Then 'Commuting Afternoon(12PM-3PM)'
            When [collision_hour] >=15 and [collision_hour]<18 Then 'Late Afternoon Commute (3PM-6PM)'
            When [collision_hour] >=18 and [collision_hour]<21 Then 'Evening Commute (6PM-9PM)'
            When [collision_hour] >=21 and [collision_hour]<24 Then 'Night Commute (9PM-12AM)' END Time_When_Most_Accidents_Happened,
			MONTH([collision_day]) as month_number
			from [NYC_Final].[dbo].[fct_collision_crashes])

			select Seasonality,Time_When_Most_Accidents_Happened,count(month_number) as number_of_accidents_by_seasonality from x group by Seasonality,Time_When_Most_Accidents_Happened order by count(month_number) desc
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

with x as (select Case When MONTH([collision_day]) in (3,4,5) then 'Spring'
            When MONTH([collision_day]) in (6,7,8) then 'Summer'
            When MONTH([collision_day]) in (9,10,11) then 'Fall'
            When MONTH([collision_day]) in (12,1,2) then 'Winter'
            END as 'Seasonality',DATENAME(month,[collision_dt]) as month_number,YEAR([collision_dt]) as collision_year
			from [NYC_Final].[dbo].[fct_collision_crashes])

			select collision_year,Seasonality,month_number,count(month_number) as number_of_accidents_by_seasonality from x 
			group by collision_year,Seasonality,month_number 
			order by collision_year asc,count(month_number) desc


-- Collisions Trend by Vehicle Types

select UPPER(d.[VEHICLE_TYPE]) as 'Vehicle Type',
	   count([UNIQUE_ID]) as 'Total Number of Collisions'

from [NYC_Final].[dbo].[fct_Collisions_Vehicles] fv
join [NYC_Final].[dbo].[Dim_VEHICLE_TYPE] d on d.VEHICLE_TYPE_SK = fv.[VEHICLE_TYPE_SK]
where d.[VEHICLE_TYPE] NOT IN ('No Value', 'UNKNOWN')

group by d.[VEHICLE_TYPE]
order by 2 desc;


-- Collisions by Causes

select b.[CONTRIBUTING_FACTOR] as 'Collision Cause', count([TABLE_SK]) as 'Collision factor'
		
from [NYC_Final].[dbo].[fct_collision_persons_contributing_factors] a
join [NYC_Final].[dbo].[Dim_CONTRIBUTING_FACTOR] b on a.[CONTRIBUTING_FACTOR_SK] = b.CONTRIBUTING_FACTOR_SK
where b.[CONTRIBUTING_FACTOR] NOT IN ('Unspecified')

group by b.[CONTRIBUTING_FACTOR]
order by 2 desc;


---Collision causes percentage of total factor count

with z as (select dc.[CONTRIBUTING_FACTOR] as Collision_Cause,
count([TABLE_SK]) as Total_Number_of_Collisions_Cause_Wise
from [NYC_Final].[dbo].[fct_collision_persons_contributing_factors] fcp

join [NYC_Final].[dbo].[Dim_CONTRIBUTING_FACTOR] dc on 
fcp.[CONTRIBUTING_FACTOR_SK] = dc.CONTRIBUTING_FACTOR_SK
where dc.[CONTRIBUTING_FACTOR] NOT IN ('Unspecified')

group by dc.[CONTRIBUTING_FACTOR]),

y as (select count(TABLE_SK) as Total 
from [NYC_Final].[dbo].[fct_collision_persons_contributing_factors]),
x as (select z.Collision_Cause,z.Total_Number_of_Collisions_Cause_Wise,y.total from z,y)
select x.Collision_Cause,x.Total_Number_of_Collisions_Cause_Wise,x.total,
ROUND((CAST(x.Total_Number_of_Collisions_Cause_Wise as float)/
CAST(x.Total as float))* 100,4) as Contributing_Factor_Percentage  from x



-----Annual statistics

--How Many Car Accidents Are There in NYC Every Year?

Select YEAR([collision_dt]) as Collision_Year,count(*) as Collision_Count
from [NYC_Final].[dbo].[fct_collision_crashes] 
group by YEAR([collision_dt]) 
order by YEAR([collision_dt]) 

------- Which Boroughs in New York City Have the Most Accidents?

Select b.borough,count(*) as Collision_Count
from [NYC_Final].[dbo].[fct_collision_crashes] a 
join [NYC_Final].[dbo].[dim_arrest_borough] b on a.borough_sk =b.borough_sk
group by b.borough
order by count(*) desc


--How Many NYC Car Accidents Result in an Injury?

Select count(*) as Collisions_resulting_Injury from [NYC_Final].[dbo].[fct_collision_crashes] 
where number_of_persons_injured!=0



--When Do Most New York City Car Accidents Happen?

with x as (Select Case
	        When [collision_hour] >=0 and [collision_hour] <6 Then 'Late Night (12AM-6AM)'
            When [collision_hour] >=6 and [collision_hour]<9 Then 'Morning Busy Route (6AM-9AM)'    
            When [collision_hour] >=9 and [collision_hour]<12 Then 'Late in the Morning Commute (9AM-12PM)'    
            When [collision_hour] >=12 and [collision_hour]<15 Then 'Commuting Afternoon(12PM-3PM)'
            When [collision_hour] >=15 and [collision_hour]<18 Then 'Late Afternoon Commute (3PM-6PM)'
            When [collision_hour] >=18 and [collision_hour]<21 Then 'Evening Commute (6PM-9PM)'
            When [collision_hour] >=21 and [collision_hour]<24 Then 'Night Commute (9PM-12AM)' 
			END Time_When_Most_Accidents_Happened,collision_hour

from [NYC_Final].[dbo].[fct_collision_crashes])  

			
Select Time_When_Most_Accidents_Happened,count(collision_hour) as collision_count from x 
group by Time_When_Most_Accidents_Happened 
order by count(collision_hour) desc

