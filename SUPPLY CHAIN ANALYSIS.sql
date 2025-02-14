USE [Supply Chain]
SELECT * FROM dim_customers
SELECT * FROM dim_products
SELECT * FROM dim_date
SELECT * FROM dim_targets_orders
SELECT * FROM fact_order_lines
SELECT * FROM fact_orders_aggregate

--DATA CLEANING
--Change column name IN table dim_targets_orders

SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'dim_targets_orders';

ALTER TABLE dim_targets_orders
ADD CUSTOMER_ID INT
SELECT * FROM dim_targets_orders

UPDATE DBO.dim_targets_orders
SET CUSTOMER_ID=[column1]

ALTER TABLE DBO.dim_targets_orders
DROP COLUMN [COLUMN1]

ALTER TABLE dbo.dim_targets_orders  
DROP COLUMN [COLUMN1];

SELECT name, type_desc 
FROM sys.objects 
WHERE object_id IN (
    SELECT object_id 
    FROM sys.columns 
    WHERE name = 'CUSTOMER_ID' AND object_id = OBJECT_ID('dbo.dim_targets_orders') );

ALTER TABLE dbo.dim_targets_orders DROP CONSTRAINT PK_dim_targets_orders;

ALTER TABLE dim_targets_orders
ADD ontime_target_PERCENTAGE INT
SELECT * FROM dim_targets_orders

UPDATE DBO.dim_targets_orders
SET ontime_target_PERCENTAGE=[column2]


ALTER TABLE dim_targets_orders
ADD infull_target_PERCENTAGE INT

ALTER TABLE dim_targets_orders
ADD OTIF_target_PERCENTAGE INT

ALTER TABLE DBO.dim_targets_orders
DROP COLUMN [COLUMN2]

UPDATE DBO.dim_targets_orders
SET infull_target_PERCENTAGE=[column3]

UPDATE DBO.dim_targets_orders
SET OTIF_target_PERCENTAGE=[COLUMN4]

ALTER TABLE DBO.dim_targets_orders
DROP COLUMN [COLUMN3]
ALTER TABLE DBO.dim_targets_orders
DROP COLUMN [COLUMN4]


SELECT * FROM dim_targets_orders

---CREATING CUSTOMER_ID and PRODUCT_ID AS A FOREIGN CONSTRAINT for refrential integrity
ALTER TABLE dbo.fact_order_lines
ADD CONSTRAINT FK_fact_order_lines_customers  
FOREIGN KEY(customer_id) REFERENCES dbo.dim_customers(customer_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;

ALTER TABLE dbo.dim_targets_orders
ADD CONSTRAINT FK_dim_targets_orders
FOREIGN KEY(customer_id) REFERENCES dbo.dim_customers(customer_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;

ALTER TABLE dbo.fact_orders_aggregate
ADD CONSTRAINT FK_fact_orders_aggregate
FOREIGN KEY(customer_id) REFERENCES dbo.dim_customers(customer_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;

ALTER TABLE dbo.fact_order_lines
ADD CONSTRAINT FK_fact_order_lines
FOREIGN KEY(product_id) REFERENCES dbo.dim_products(product_id)
ON DELETE CASCADE 
ON UPDATE CASCADE;


--Business Question 1: How many total orders were placed last month?
WITH LAST_MONTH_ORDERS AS (
SELECT DATEPART(YEAR,ORDER_PLACEMENT_DATE) AS YEAR,DATEPART(MONTH,ORDER_PLACEMENT_DATE) AS MONTH,
COUNT(ORDER_ID) AS total_orders 
FROM fact_order_lines
GROUP BY DATEPART(YEAR,ORDER_PLACEMENT_DATE),DATEPART(MONTH,ORDER_PLACEMENT_DATE) )
SELECT YEAR,MONTH,TOTAL_ORDERS
FROM LAST_MONTH_ORDERS
WHERE MONTH=7
ORDER BY MONTH

--Business Question 2: What is the average On-Time Delivery % for all customers?

WITH ON_TIME_D AS ( 
SELECT CUSTOMER_ID,
COUNT(CASE WHEN ON_TIME=1 THEN 1 END) AS on_TIME_DELIVERY,
COUNT(*) AS TOTAL_ORDERS
FROM DBO.fact_order_lines
GROUP BY customer_id)
SELECT *,(on_TIME_DELIVERY*1.0/TOTAL_ORDERS)*100 as percentage
FROM ON_TIME_D

SELECT customer_id, 
AVG(CAST(ON_TIME AS FLOAT))*100 AS average_on_time
FROM dbo.fact_order_lines
GROUP BY customer_id;

--Business Question 3: Which customers have the lowest In-Full Delivery %?

SELECT a.customer_id, a.customer_name,
ROUND(AVG(CAST(IN_FULL AS FLOAT)) * 100, 2) AS PERCENTAGE_
FROM dbo.fact_order_lines
join dim_customers A
on A.customer_id=fact_order_lines.customer_id
GROUP BY A.customer_id,A.customer_name
ORDER BY PERCENTAGE_
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;  

--Business Question 4: How many total order lines were created in the last 2 months?

select A.year,A.MONTH,count(DISTINCT B.product_id) AS PRODUCT_LINE
from (
SELECT DATEPART(YEAR,ORDER_PLACEMENT_DATE) AS YEAR,
DATEPART(MONTH,ORDER_PLACEMENT_DATE) AS MONTH,
product_id
FROM DBO.fact_order_lines  
) A
JOIN dim_products B
ON A.product_id=B.product_id
GROUP BY A.YEAR,A.MONTH
order by MONTH
OFFSET 4 ROWS FETCH NEXT 5 ROWS ONLY

--Business Question 5: Which cities have the highest volume fill rate?

select A.CITY,SUM(B.ORDER_QTY) AS ORDERS_DEMANDED,SUM(B.DELIVERY_QTY) AS ORDERS_SHIPPED,
ROUND((SUM(B.DELIVERY_QTY)*1.0/SUM(B.order_qty))*100,4) AS VOLUME_FILL_RATE_PERCENTAGE
FROM DBO.dim_customers A ,DBO.fact_order_lines B
WHERE A.customer_id=B.customer_id
GROUP BY city

--Business Question 6: What is the trend of On-Time In-Full % over the past 6 months?

SELECT 
FORMAT(order_placement_date, 'yyyy-MMM') AS YEAR_MONTH,
COUNT(ORDER_ID) AS TOTAL_ORDERS,
COUNT(CASE WHEN otif=1 THEN 1 END) AS OTIF,
ROUND((COUNT(CASE WHEN otif=1 THEN 1 END)*1.0/COUNT(ORDER_ID)*100),3) AS OTIF_PERCENTAGE
FROM DBO.fact_orders_aggregate 
WHERE order_placement_date>=DATEADD(MONTH,-6,cast('2022-03-01'  AS date))
GROUP BY FORMAT(order_placement_date, 'yyyy-MMM') 

--Business Question 7: Which CITY has the highest late deliveries in the last quarter?

SELECT 
FORMAT(A.ORDER_PLACEMENT_DATE,'yyyy-Q') AS LAST_QUARTER,
B.CITY,
COUNT(CASE WHEN ON_TIME=0 THEN A.order_id END) AS LATE_DELIVERY,
COUNT(ORDER_ID) AS TOTAL_ORDERS,
ROUND((COUNT(CASE WHEN ON_TIME=0 THEN order_id END)*1.0)/COUNT(ORDER_ID)*100,2) AS LATE_DELIVERY_PERCENTAGE
FROM DBO.fact_order_lines A
JOIN dim_customers B
ON A.customer_id=B.customer_id
where DATEPART(QUARTER,order_placement_date) = 2
GROUP BY FORMAT(A.ORDER_PLACEMENT_DATE,'yyyy-Q'),B.city

----Business Question 8: Compare the current MONTH'S and Previous month's In-Full Delivery % with the previous quarter.

SELECT DATENAME(MONTH,order_placement_date) AS MONTH,
--count(order_placement_date) AS DateCount,
COUNT(CASE WHEN IN_FULL=1 THEN ORDER_ID END) AS IN_FULL,
COUNT(ORDER_ID) AS TOTAL_ORDERS,
ROUND((COUNT(CASE WHEN IN_FULL=1 THEN ORDER_ID END)*1.0/COUNT(ORDER_ID))*100,3) AS INFULL_PERCENT
FROM DBO.fact_order_lines
GROUP BY DATENAME(MONTH,order_placement_date) 
ORDER BY min(order_placement_date) 
OFFSET 4 ROWS FETCH NEXT 2 ROWS ONLY

----Business Question 9: Which Customers are consistently below the on-time target?

WITH CTE AS (
SELECT DATENAME(MONTH,A.order_placement_date) AS MONTH,
A.customer_id,
B.ONTIME_TARGET_PERCENTAGE AS ON_TIME_TARGET_PERCENT,
(COUNT(CASE WHEN A.On_Time=1 THEN ORDER_ID END)*1.0 /COUNT(A.order_id))*100 AS PERCENTAGE_
FROM DBO.fact_order_lines A
JOIN DBO.dim_targets_orders B
ON A.customer_id=B.CUSTOMER_ID
GROUP BY DATENAME(MONTH,A.order_placement_date),A.customer_id,B.ONTIME_TARGET_PERCENTAGE )
SELECT DISTINCT CUSTOMER_ID 
FROM CTE
group by customer_id
HAVING MIN(ON_TIME_TARGET_PERCENT-PERCENTAGE_)>0


select distinct b.customer_id,b.customer_name,a.ontime_target_PERCENTAGE,c.order_placement_date
from dbo.dim_targets_orders a
join dbo.dim_customers b
on a.CUSTOMER_ID=b.customer_id
join dbo.fact_order_lines c
on a.CUSTOMER_ID=c.customer_id and b.customer_id=c.customer_id

----Business Question 10: Which products frequently have incomplete deliveries?

SELECT Distinct PRODUCT_ID
FROM (
    SELECT 
        PRODUCT_ID,
        DATENAME(MONTH, ORDER_PLACEMENT_DATE) AS MONTH,
        SUM(ORDER_QTY) AS TOTAL_ORDERED_QTY,
        SUM(DELIVERY_QTY) AS TOTAL_DELIVERED_QTY,
        COUNT(CASE WHEN In_Full = 0 THEN 1 END) AS NOT_DELIVERED_IN_FULL
    FROM DBO.fact_order_lines
    GROUP BY PRODUCT_ID, DATENAME(MONTH, ORDER_PLACEMENT_DATE)
) X
WHERE TOTAL_ORDERED_QTY - TOTAL_DELIVERED_QTY > 0;


SELECT 
PRODUCT_ID,row_number() over(partition by DATENAME(MONTH, ORDER_PLACEMENT_DATE) order by DATENAME(MONTH, ORDER_PLACEMENT_DATE) ) as row_,
DATENAME(MONTH, ORDER_PLACEMENT_DATE) AS MONTH,
COUNT(CASE WHEN In_Full = 0 THEN ORDER_ID END) AS Incomplete_Delivery_Count,
COUNT(ORDER_ID) AS Total_Orders,
(COUNT(CASE WHEN In_Full = 0 THEN ORDER_ID END) * 100.0 / COUNT(ORDER_ID)) AS Incomplete_Delivery_Percent
FROM DBO.fact_order_lines
GROUP BY PRODUCT_ID,DATENAME(MONTH, ORDER_PLACEMENT_DATE) 

----Business Question 11: What is the avg time difference btw the actual dleivery date and agreed date for each product?

WITH CTE AS (
SELECT P.PRODUCT_ID, P.PRODUCT_NAME,O.AGREED_DELIVERY_DATE,O.ACTUAL_DELIVERY_DATE,
DATEDIFF(HOUR,O.AGREED_DELIVERY_DATE,O.ACTUAL_DELIVERY_DATE) AS DIFFERENCE_
FROM  fact_order_lines O
JOIN dim_products P
ON P.product_id=O.product_id
WHERE DATEDIFF(HOUR,O.AGREED_DELIVERY_DATE,O.ACTUAL_DELIVERY_DATE) IS NOT NULL
AND O.agreed_delivery_date<O.actual_delivery_date)

SELECT AVG(DIFFERENCE_) AS AVGERAGE_LATE
FROM CTE

--Business Question 12:CUSTOMERS THAT WILL PROBABLY NOT RENEW THE CONTRACTS
SELECT TOP 6 * FROM (
SELECT DISTINCT CUSTOMER_NAME,
COUNT(CASE WHEN IN_FULL=1 THEN 1 END )AS ON_TIME_COUNT,
COUNT(ORDER_ID) AS TOTAL_ORDERS,
ontime_target_PERCENTAGE AS TARGET_PERCENTAGE,
(COUNT(CASE WHEN IN_FULL=1 THEN 1 END)*1.0/COUNT(ORDER_ID))*100 AS ACTUAL_PERCENTAGE
FROM dim_targets_orders 
JOIN dim_customers
ON DIM_CUSTOMERS.customer_id=dim_targets_orders.CUSTOMER_ID
JOIN fact_order_lines
ON fact_order_lines.customer_id=dim_targets_orders.CUSTOMER_ID AND fact_order_lines.customer_id=dim_customers.customer_id
GROUP BY CUSTOMER_NAME,ontime_target_PERCENTAGE
HAVING ontime_target_PERCENTAGE>(COUNT(CASE WHEN IN_FULL=1 THEN 1 END)*1.0/COUNT(ORDER_ID))*100)X
ORDER BY X.ACTUAL_PERCENTAGE ASC

SELECT * FROM dim_customers
SELECT * FROM dim_products
SELECT * FROM dim_date
SELECT * FROM dim_targets_orders
SELECT * FROM fact_order_lines
SELECT * FROM fact_orders_aggregate

--Business Question 13:Are there any seasonal patterns or spikes in order volumes across different quarters?
SELECT 
 DATENAME(YEAR, order_placement_date) AS year, 
  DATENAME(QUARTER, order_placement_date) AS quarter, 
 COUNT(order_id) AS total_orders
FROM dbo.fact_order_lines
GROUP BY DATENAME(QUARTER, order_placement_date), DATENAME(YEAR, order_placement_date)
ORDER BY year, quarter;

--Business Question 14:AVG in fill rates across different product categories?

SELECT ROUND(AVG( IN_FULL_RATE_PERCENT),2) AS AVG_PERCENT FROM (
select p.product_name,
count(case when o.In_Full =1 then 1 end) as delivered_infull,
count(o.order_id) as total_orders,
(count(case when o.In_Full =1 then 1 end)*1.0/count(o.order_id))*100 AS IN_FULL_RATE_PERCENT
from dbo.fact_order_lines o
join dim_products p
ON P.product_id=O.product_id
group by p.product_name
) X
