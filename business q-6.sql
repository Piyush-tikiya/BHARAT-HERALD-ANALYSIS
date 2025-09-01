SELECT * FROM bharat_herald.fact_city_readiness;

WITH CTE1 AS (
    SELECT 
        city_id,
        ROUND(AVG( (literacy_rate + smartphone_penetration + internet_penetration) / 3 ), 2) AS readiness_score_2021
    FROM fact_city_readiness 
    WHERE RIGHT(quarter,4) = '2021'
    GROUP BY city_id
),
cte2 as (
SELECT 
	dc.city_id,
    dc.city AS city_name,
    C1.readiness_score_2021
FROM CTE1 c1
JOIN dim_city dc ON C1.city_id = dc.city_id
),
cte3 as (
select 
	city_id,
    round( sum(downloads_or_access * (1-COALESCE(avg_bounce_rate,0)/100)) / COALESCE(sum(users_reach),0) *100,2)aS engagement_metric_2021
from fact_digital_pilot
where left(launch_mon,4) =  2021
group by city_id
),
cte4 as (
select 
	c1.city_id,
    c2.city_name,
    c1.readiness_score_2021,
    c3.engagement_metric_2021,
dense_rank () over(order by c3.engagement_metric_2021 asc) as Engagement_Rank,
dense_rank () over(order by c1.readiness_score_2021 desc) as Readiness_Rank
from cte1 c1 join cte3 c3 using(city_id)
join cte2 c2 using(city_id)
)
select *,
case when Readiness_Rank = 1 and Engagement_Rank <=3 then 'yes' else 'No'  end as is_outlier
from cte4
order by city_id, city_name