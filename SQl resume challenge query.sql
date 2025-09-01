CREATE DATABASE if not exists bharat_herald;
USE bharat_herald;

CREATE TABLE dim_ad_category (
    ad_category_id VARCHAR(20) PRIMARY KEY,
    standard_ad_category VARCHAR(100),
    category_group VARCHAR(100),
    example_brands TEXT
);

# Data imported now to check table
select  * from dim_ad_category;


CREATE TABLE dim_city (
    city_id VARCHAR(20) PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(100),
    tier VARCHAR(50)
);

# Data imported now to check table
select  * from dim_city;

CREATE TABLE fact_ad_revenue (
    edition_id VARCHAR(10),
    ad_category VARCHAR(10),
    quarter VARCHAR(10),
    ad_revenue DECIMAL(15,2),
    currency VARCHAR(5)
);

select * from fact_ad_revenue;

CREATE TABLE fact_print_sales (
    edition_id VARCHAR(10),
    city_id VARCHAR(10),
    language VARCHAR(10),
    state VARCHAR(20),
    month  char(10),
    copies_sold INT,
    copies_returned INT,
    net_circulation INT
);
select * from fact_print_sales;

CREATE TABLE fact_digital_pilot (
    dp_id INT PRIMARY KEY,   -- surrogate ID from your file
    city_id VARCHAR(20),
    platform VARCHAR(100),
    launch_mon CHAR(10),  -- YYYY-MM format
    ad_category VARCHAR(20),
    dev_cost int,
    marketing_cost int,
    users_reach INT,
    downloads_or_access INT,
    avg_bounce_rate DECIMAL(5,2),
    cumulative_feedback_from_customers TEXT
);
select * from fact_digital_pilot;

CREATE TABLE fact_city_readiness (
    CR_id TINYINT,
    city_id VARCHAR(20),
    quarter VARCHAR(10),
    literacy_rate DECIMAL(5,2),
    smartphone_penetration DECIMAL(5,2),
    internet_penetration DECIMAL(5,2)
);
SELECT * FROM fact_city_readiness;

/*
Generate a report showing the top 3 months (2019–2024) where any city recorded the sharpest month-over-month decline in net_circulation.
column to show
			1-  city_name
            2-  month (YYYY-MM)
            3-  net_circulation
*/
With CTE1 as (	
select 
	dc.city_id,dc.city as city_name, fs.month,fs.net_circulation,
	lag(net_circulation) over (partition by dc.city_id order by fs.MONTH) as prev_month_circulation
from fact_print_sales fs inner join  dim_city dc
on fs.city_id = dc.city_id
)
select City_name, month,net_circulation,prev_month_circulation,(net_circulation - prev_month_circulation) as MOM_change
from CTE1
WHERE prev_month_circulation IS NOT NULL
ORDER BY MOM_change, MONTH 
LIMIT 3;


/*
Yearly Revenue Concentration by Category
Identify ad categories that contributed > 50% of total yearly ad revenue.
Fields:
year
category_name
category_revenue
total_revenue_year
pct_of_year_total
*/
select * from dim_ad_category;
select * from fact_ad_revenue;
explain analyze
with cte1 as (
select 
		dac.standard_ad_category as category_name, 
        substring_index(far.quarter,'-',-1) as Year,
        SUM(far.ad_revenue) AS category_revenue
	from dim_ad_category dac join fact_ad_revenue far
    on dac.ad_category_id = far.ad_category
    group by dac.standard_ad_category, substring_index(far.quarter,'-',-1)
),
cte2 as (
select 
	Year,
	sum(category_revenue) as total_revenue_across_category_yearly
from cte1
group by year
)
select 
		c1.year,
		c1.category_name,
        c1.category_revenue,c2.total_revenue_across_category_yearly,
       concat(round((category_revenue/total_revenue_across_category_yearly *100),2), '%') as pct_of_year_total
from cte1 c1 join cte2 c2
on c1.year = c2.year
where concat(round((category_revenue/total_revenue_across_category_yearly *100),2), '%') > 0.5
order by c1.year, pct_of_year_total desc;


/*
For 2024, rank cities by print efficiency = net_circulation / copies_printed. Return top 5
city_name|copies_printed_2024|net_circulation_2024| efficiency_ratio = net_circulation_2024 / copies_printed_2024 | efficiency_rank_2024
*/
select * from dim_city;
select * from  fact_print_sales;

with cte1 as (
select 
	dc.city as city_name,
    sum(fps.copies_sold+fps.copies_returned) as copies_printed_2024,
	sum(fps.net_circulation) as net_circulation_2024
from fact_print_sales fps join dim_city dc
on fps.city_id = dc.city_id
where substring_index(month,'-',1) = 2024
group by dc.city	
),
cte2 as (
select city_name, round((net_circulation_2024/copies_printed_2024),2)*100 as  efficiency_ratio
from cte1
)
select c1.city_name,c1.copies_printed_2024,c1.net_circulation_2024,c2.efficiency_ratio,
row_number() over(order by c2.efficiency_ratio desc) Ranking
from cte1 c1 join cte2 c2 on c1.city_name = c2.city_name
order by c2.efficiency_ratio desc
limit 5;



/*
Business Request – 4 : Internet Readiness Growth (2021)
For each city, compute the change in internet penetration from Q1-2021 to Q4-2021 and identify the city with the highest improvement.
Fields:
city_name
internet_rate_q1_2021
internet_rate_q4_2021
delta_internet_rate = internet_rate_q4_2021 − internet_rate_q1_2021
*/
with CTE1 as (
SELECT CITY_id, city as  city_name from dim_city
),
CTE2 as (
select city_id, internet_penetration AS internet_rate_q1_2021 from fact_city_readiness
where quarter = 'Q1-2021'
),
CTE3 AS (
select city_id, internet_penetration AS internet_rate_q4_2021 from fact_city_readiness
where quarter = 'Q4-2021'
)
SELECT 
	C1.city_name,C2.city_id,C2.internet_rate_q1_2021,C3.internet_rate_q4_2021,
    (C3.internet_rate_q4_2021 - C2.internet_rate_q1_2021)  as Change_delta_internet_rate
    FROM CTE1 C1 JOIN CTE2 C2 ON C1.CITY_ID = C2.CITY_ID
    JOIN CTE3 C3 ON C3.CITY_ID = C2.CITY_ID
order by change_delta_internet_rate desc;






/*
Business Request – 5: Consistent Multi-Year Decline (2019→2024)
Find cities where both net_circulation and ad_revenue decreased every year from 2019 through 2024 (strictly decreasing sequences).
Fields:
city_name
year
yearly_net_circulation
yearly_ad_revenue
is_declining_print (Yes/No per city over 2019–2024)
is_declining_ad_revenue (Yes/No)
is_declining_both (Yes/No)
*/
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

	)
	SELECT 
		city_name,
		MIN(year) AS start_year,
		 MAX(year) AS end_year,
        total_yearly_net_circulation,
        total_yearly_ad_revenue,
		CASE WHEN MAX(total_yearly_net_circulation - prev_circulation) < 0 
			 THEN 'Yes' ELSE 'No' END AS is_declining_print,
		CASE WHEN MAX(total_yearly_ad_revenue - prev_revenue) < 0 
			 THEN 'Yes' ELSE 'No' END AS is_declining_ad_revenue,
		CASE WHEN MAX(total_yearly_net_circulation - prev_circulation) < 0
			  AND MAX(total_yearly_ad_revenue - prev_revenue) < 0
			 THEN 'Yes' ELSE 'No' END AS is_declining_both
	FROM CTE4
	GROUP BY city_name,total_yearly_net_circulation,total_yearly_ad_revenue
	ORDER BY city_name;