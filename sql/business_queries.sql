--- Business Problems 
---Find the number of stores in each country.
SELECT country, count(store_id) as number_of_stores
FROM stores
GROUP BY country


---Calculate the total number of units sold by each store.
SELECT stores.store_id, stores.store_name, COUNT(sales.quantity) as Total_number_of_units
FROM stores 
JOIN sales 
on stores.store_id = sales.store_id
GROUP BY stores.store_id, stores.store_name

---Identify how many sales occurred in December 2023.
SELECT count(*) as Total_sales_Dec2023
FROM sales
WHERE EXTRACT(YEAR from sale_date) = 2023 AND EXTRACT(MONTH from sale_date) = 12

---Determine how many stores have never had a warranty claim filed.
SELECT Count(*)
FROM stores
WHERE store_id NOT IN (
	SELECT DISTINCT store_id
	FROM sales as s 
	RIGHT JOIN warranty as w 
	on s.sale_id = w.sale_id
)


---Calculate the percentage of repair status marked as "Rejected".
SELECT count(claim_id)/(SELECT COUNT(*) FROM warranty)::numeric
*100 as Percentage_rejected
FROM warranty
WHERE repair_status = 'Rejected'


---Identify which store had the highest total units sold in the last year.
SELECT stores.store_id, stores.store_name, COUNT(quantity) as Highest_unit_sold
FROM sales
LEFT JOIN stores 
ON sales.store_id = stores.store_id
WHERE EXTRACT(YEAR from sales.sale_date) = 2023 
GROUP BY stores.store_id, stores.store_name
ORDER BY Highest_unit_sold DESC
LIMIT 1


---Count the number of unique products sold in the last year.

SELECT COUNT(DISTINCT product_id) as Unique_Products
FROM sales
WHERE EXTRACT (YEAR FROM sale_date) = 2023

---Find the average price of products in each category.
SELECT c.category_name, c.category_id, ROUND(AVG(price), 2) as Average_price
FROM products as p
JOIN category as c 
ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name


---How many warranty claims were filed in 2020?
SELECT COUNT(*) 
FROM warranty
WHERE sale_id IN (SELECT sale_id
					FROM sales
					WHERE EXTRACT(YEAR FROM sale_date) = 2020
)

---For each store, identify the best-selling day based on highest quantity sold.

SELECT *
FROM (SELECT store_id, 
		TO_CHAR(sale_date, 'Day') as Day_name, 
		SUM(quantity), DENSE_RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity)) as Rank_dense
FROM sales
GROUP BY 1,2) as t1
LEFT JOIN stores 
ON t1.store_id = stores.store_id
WHERE Rank_dense = 1


-- Identify the least selling product in each country for each year based on total units sold.


WITH t1 as (SELECT  st.store_id, 
		EXTRACT(YEAR FROM s.sale_date) as Year_sold,
		p.product_name as Product, 
		st.country as Country, 
		s.quantity as Quantity
FROM sales as s 
LEFT JOIN stores as st  
ON s.store_id = st.store_id
LEFT JOIN products as p
ON s.product_id = p.product_id
)

SELECT *
FROM ( SELECT Country, 
		Product, 
		Year_sold, 	
		SUM(quantity) as Total_qty, 
		RANK() OVER(PARTITION BY Country, Year_sold ORDER BY SUM(quantity)) as RANKED
FROM t1
GROUP BY Country, Product, Year_sold
) as t2
WHERE RANKED = 1

-- Calculate how many warranty claims were filed within 180 days of a product sale.
SELECT COUNT(*)  
FROM warranty as w
LEFT JOIN sales as s
ON w.sale_id = s.sale_id
WHERE w.claim_date - s. sale_date <= '180 days'

SELECT *, w.claim_date - s.sale_date as Days
FROM warranty as w
LEFT JOIN sales as s
ON w.sale_id = s.sale_id
WHERE claim_date - sale_date <= '180 days'


--Determine how many warranty claims were filed for products launched in the last two years.
SELECT product_name, count(claim_id) as No_claim
FROM warranty as w
JOIN sales as s 
ON s.sale_id = w.sale_id
JOIN products as p 
ON p.product_id = s.product_id  
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY product_name


--List the months in the last three years where sales exceeded 5,000 units in the USA.
SELECT * 
FROM sales
LEFT JOIN stores 
ON sales.store_id = stores.store_id
WHERE country = 'United States' AND sale_date >= CURRENT_DATE - INTERVAL '3 Years'
GR


--Identify the product category with the most warranty claims filed in the last two years

SELECT category_name, COUNT(claim_id) as Total_warranty_claims
FROM sales as s 
LEFT JOIN warranty as w 
ON s.sale_id = w.sale_id 
LEFT JOIN products as p 
ON s.product_id = p.product_id
LEFT JOIN category as c 
ON p.category_id = c.category_id
WHERE sale_date >= CURRENT_DATE - INTERVAL '2 Years'
GROUP BY category_name
ORDER BY COUNT(claim_id) DESC
LIMIT 1


-- Determine the percentage chance of receiving warranty claims after each purchase for each country.
WITH No_claims(
SELECT * 
FROM sales as s
LEFT JOIN warranty as w 
ON w.sale_id = s.sale_id  
LEFT JOIN stores as st 
ON s.store_id = st.store_id
WHERE claim_id is not null
)
WITH
SELECT * 
FROM sales as s
LEFT JOIN warranty as w 
ON w.sale_id = s.sale_id  
LEFT JOIN stores as st 
ON s.store_id = st.store_id
WHERE claim_id is not null


-- Analyze the year-by-year growth ratio for each store.
WITH sales_report as (SELECT EXTRACT(Year from s.sale_date), 
		st.store_id, 
		st.store_name,
		SUM(s.quantity * p.price) as Total_revenue
FROM sales as s
LEFT JOIN products as p 
ON s.product_id = p.product_id
LEFT JOIN stores as st 
ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name, EXTRACT(Year from sale_date)), 

LAGGED as (SELECT *, 
		LAG(Total_revenue, 1) OVER(PARTITION BY store_id, store_name ORDER BY Total_revenue) as 
																				Previous_revenue
		FROM sales_report
)

SELECT *, 
		ROUND((Total_revenue - Previous_revenue)*100/Total_revenue::numeric, 2)  as Growth_ratio
FROM LAGGED 
WHERE Previous_revenue is not null
ORDER BY Growth_ratio DESC


-- Calculate the correlation between product price and warranty claims for products 
   --                                         sold in the last five years, segmented by price range.

WITH segmentation as (SELECT 	CASE 
			WHEN p.price < 500 THEN 'Less Expensive'
			WHEN p.price BETWEEN 500 AND 1000 THEN 'Moderately Expensive'
			ELSE 'Expensive' 
			END AS Price_segmentation, 
		COUNT(claim_id) as Total_claims
FROM sales as s 
LEFT JOIN warranty as w 
ON s.sale_id = w.sale_id
LEFT JOIN products as p 
ON s.product_id = p.product_id
WHERE sale_date > CURRENT_DATE - INTERVAL '5 years'
GROUP BY p.product_id, p.product_name, p.price
)

SELECT price_segmentation, 
		SUM(total_claims) as Total_claims
FROM segmentation
GROUP BY price_segmentation

-- Identify the store with the highest percentage of "Completed" claims relative to total claims filed.
WITH Total_claims as (SELECT st.store_id, 
		st.store_name, 
		COUNT(*) as Total_claims_filed
FROM warranty as w
LEFT JOIN sales as s
ON w.sale_id = s.sale_id
LEFT JOIN stores as st 
ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name
),

Completed as (
SELECT st.store_id, 
		st.store_name, 
		COUNT(*) as Total_claims_completed
FROM warranty as w
LEFT JOIN sales as s
ON w.sale_id = s.sale_id
LEFT JOIN stores as st 
ON s.store_id = st.store_id
WHERE repair_status = 'Completed'
GROUP BY st.store_id, st.store_name
)


SELECT tc.store_id, 
		tc.store_name,
		tc.Total_claims_filed, 
		c.Total_claims_completed,
		ROUND(Total_claims_completed::numeric *100/ total_claims_filed::numeric, 2) as 
			Completed_percentage
FROM Total_claims as tc
LEFT JOIN Completed as c
ON tc.store_id = c.store_id
ORDER BY completed_percentage DESC
LIMIT 1 



-- Write a query to calculate the monthly running total of sales for each store over the past 
-- 															four years and compare trends during this period.


SELECT  
		st.store_name,
		TO_CHAR(sale_date, 'YYYY-MM') as Sales_Month,
	    SUM(s.quantity * p.price) as Total_sales, 
		SUM(SUM(s.quantity * p.price)) OVER(PARTITION BY store_name ORDER BY st.store_name, TO_CHAR(sale_date, 'YYYY-MM')) as Running_total
FROM sales as s 
LEFT JOIN stores as st 
ON s.store_id = st.store_id
LEFT JOIN products as p 
ON s.product_id = p.product_id
WHERE sale_date > CURRENT_DATE - INTERVAL '4 years'
GROUP BY st.store_name, TO_CHAR(sale_date, 'YYYY-MM') 
ORDER BY st.store_name, Sales_Month


-- Analyze product sales trends over time, 		
--			segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.

SELECT *
FROM (
    SELECT
        p.product_id,
        p.product_name,
        CASE
            WHEN s.sale_date >= p.launch_date
                 AND s.sale_date < p.launch_date + INTERVAL '6 Month'
                THEN '0-6 Months'

            WHEN s.sale_date >= p.launch_date + INTERVAL '6 Month'
                 AND s.sale_date < p.launch_date + INTERVAL '12 Month'
                THEN '6-12 Months'

            WHEN s.sale_date >= p.launch_date + INTERVAL '12 Month'
                 AND s.sale_date < p.launch_date + INTERVAL '18 Month'
                THEN '12-18 Months'

            ELSE '18+ Months'
        END AS sale_interval,

        SUM(s.quantity) AS total_sold

    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        sale_interval
) AS sales_summary

ORDER BY
    product_name,
    CASE sale_interval
        WHEN '0-6 Months' THEN 1
        WHEN '6-12 Months' THEN 2
        WHEN '12-18 Months' THEN 3
        WHEN '18+ Months' THEN 4
    END;
