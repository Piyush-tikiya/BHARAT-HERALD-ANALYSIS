WITH CTE1 AS (
    SELECT 
        LEFT(month,4) AS year,
        edition_id,
        city_id,
        SUM(net_circulation) AS total_yearly_net_circulation
    FROM fact_print_sales
    GROUP BY LEFT(month,4), edition_id, city_id
),
CTE2 AS (
    SELECT 
        RIGHT(quarter,4) AS year,
        edition_id,
        SUM(ad_revenue) AS total_yearly_ad_revenue
    FROM fact_ad_revenue
    GROUP BY RIGHT(quarter,4), edition_id
),
	CTE3 AS (
		SELECT city_id, city AS city_name
		FROM dim_city
	),
	 CTE4 AS (
		SELECT 
			C1.year,
			C1.city_id,
			C3.city_name,
			C1.total_yearly_net_circulation,
			C2.total_yearly_ad_revenue,
			LAG(C1.total_yearly_net_circulation) OVER (PARTITION BY C1.city_id ORDER BY C1.year) AS prev_circulation,
			LAG(C2.total_yearly_ad_revenue) OVER (PARTITION BY C1.city_id ORDER BY C1.year) AS prev_revenue
		FROM CTE1 C1
		JOIN CTE2 C2 
			ON C1.edition_id = C2.edition_id 
		   AND C1.year = C2.year
		JOIN CTE3 C3 ON C1.city_id = C3.city_id
),
CTE5 AS (

	SELECT 
		city_name,
		year,
       coalesce (lead(year,1) over (partition by city_name order by year),'dec-2024')as Next,
        total_yearly_net_circulation,
        total_yearly_ad_revenue,
		CASE WHEN (total_yearly_net_circulation - prev_circulation) < 0 
			 THEN 'Yes' ELSE 'No' END AS is_declining_print,
		CASE WHEN (total_yearly_ad_revenue - prev_revenue) < 0 
			 THEN 'Yes' ELSE 'No' END AS is_declining_ad_revenue,
		CASE WHEN (total_yearly_net_circulation - prev_circulation) < 0
			  AND (total_yearly_ad_revenue - prev_revenue) < 0
			 THEN 'Yes' ELSE 'No' END AS is_declining_both
	FROM CTE4
	GROUP BY city_name,year,total_yearly_net_circulation,total_yearly_ad_revenue
    )
   select * ,
   case when total_yearly_net_circulation > lead(total_yearly_net_circulation,1) over (partition by city_name order by year,Next) then "Strictly Decreasing"
   else "Not Decreasing" end as FLAG_AS_PER_net_circulation,
      case when total_yearly_ad_revenue > lead(total_yearly_ad_revenue,1) over (partition by city_name order by year,Next) then "Strictly Decreasing"
   else "Not Decreasing" end as FLAG_AS_PER_ad_revenue
   from CTE5
   ORDER BY city_name;
   
   
   
   
   
   
