# SUPPLY-CHAIN-ANALYSIS
Solving a Supply Chain issue in the FMCG Domain
# Problem Statement
AtliQ Mart is a growing FMCG manufacturer headquartered in Gujarat, India. It is currently operational in three cities Surat, Ahmedabad and Vadodara. They want to expand to other metros/Tier 1 cities in the next 2 years.

AtliQ Mart is currently facing a problem where a few key customers did not extend their annual contracts due to service issues. It is speculated that some of the essential products were either not delivered on time or not delivered in full over a continued period, which could have resulted in bad customer service. Management wants to fix this issue before expanding to other cities and requested their supply chain analytics team to track the ’On time’ and ‘In Full’ delivery service level for all the customers daily basis so that they can respond swiftly to these issues.

The Supply Chain team decided to use a standard approach to measure the service level in which they will measure ‘On-time delivery (OT) %’, ‘In-full delivery (IF) %’, and OnTime in full (OTIF) %’ of the customer orders daily basis against the target service level set for each customer.

# About Dataset
**To conduct the analysis, I worked with six tables:**
dim_customers: Information on customer details and locations.
dim_products: Product details including categories.
dim_date: Dates broken down by daily, monthly, and weekly levels.
dim_targets_orders: Service level targets for each customer.
fact_order_lines: Detailed order line information, including ordered quantity, agreed delivery date, and actual delivery date.
fact_orders_aggregate: Pre-aggregated data showing if orders were delivered on time, in full, or met both criteria (OTIF).

# Analysis and Insights
Lotus Mart, Coolblue, Acclaimed stores have the highest orders as well as delayed the most to deliver the products on time .
There is no noticeable improvements in any of the key metrics in the last few months.
On an average, orders are delayed 3 days from the agreed date of delivery
Ghee, curd and butter products are most delayed to deliver.
There is no noticeable improvements in any of the key metrics in the last few months
City Vadodara has the highest late delivery in the last quarter.
The avg time difference btw the actual delivery date and agreed date for each product is by 1 day.
We had maximum number of orders in the second quarter of the year.
There is a huge gap in IF% for most of the customers average is 66%.

