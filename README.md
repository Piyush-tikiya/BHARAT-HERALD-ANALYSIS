# BHARAT-HERALD-ANALYSIS
Provide Insights to Guide a Legacy Newspaper’s Survival in a Post- COVID Digital Era


📌 Project Overview

The Bharat Herald, a 100+ year-old Indian newspaper, has been hit hard post-COVID with falling print circulation and ad revenue. To survive in a digital-first world, it must understand circulation trends, ad revenue shifts, digital readiness, and audience engagement.

This project answers real-world ad-hoc business requests using SQL queries on newspaper datasets (2019–2024).

🗂 Dataset & Tables

Imported datasets into MySQL:

fact_print_sales – circulation data by city & month

fact_ad_revenue – ad revenue across categories

fact_city_readiness – internet, smartphone, literacy penetration

fact_digital_pilot – digital engagement metrics

dim_city – city dimension

dim_ad_category – ad category dimension


🎯 Business Requests Solved<BR>

1️⃣ Monthly Circulation Drop Check

Found top 3 months (2019–2024) where any city recorded the sharpest decline in net_circulation.

2️⃣ Yearly Revenue Concentration by Category

Identified ad categories contributing >50% of yearly revenue.

3️⃣ 2024 Print Efficiency Leaderboard

Ranked cities on print efficiency = net_circulation / copies_printed.

Returned Top 5 performers in 2024.

4️⃣ Internet Readiness Growth (2021)

Measured Q1→Q4 internet penetration growth in 2021.

Highlighted the city with the highest digital improvement.

5️⃣ Consistent Multi-Year Decline (2019–2024)

Found cities with strictly declining net_circulation & ad_revenue every year.

6️⃣ 2021 Readiness vs Pilot Engagement Outlier

Identified the outlier city: high readiness but low engagement.


<img width="1130" height="622" alt="image" src="https://github.com/user-attachments/assets/43e5e0ab-9d6f-4f8a-84b3-1f6cce52ed3f" />


🛠 Tools & Skills Used

SQL (MySQL) – core analysis.

Joins, CTEs, Window Functions, Aggregations – query techniques.

Ad-hoc Reporting – solving business requests directly with SQL.




📈 Key Insights

📉 Some Tier-1 cities faced the sharpest circulation drops during 2020–21.

💰 A few ad categories dominate (>50%) yearly revenue – risky dependency.

📰 Print efficiency varied widely; top cities operate 2x better than bottom cities.

🌐 Digital readiness jumped sharply in select cities in 2021.

⚠️ Certain cities show continuous decline in both circulation & ad revenue → major red flag.

📱 Some cities are digitally ready but lack engagement → poor execution of digital strategy.




 Recommendations

Diversify revenue streams – reduce dependence on 1–2 ad categories.

Push digital adoption – target cities with readiness but low engagement.

Print optimization – focus on efficient cities, cut losses in declining ones.

Data-driven strategy – continuous monitoring of circulation & digital KPIs.
