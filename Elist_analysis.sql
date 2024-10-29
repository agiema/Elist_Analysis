-- What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 

SELECT
DATE_TRUNC(o.purchase_ts, quarter) as quarter,
g.region as region,
COUNT(DISTINCT o.id) as orders_count,
ROUND(SUM(o.usd_price),2) as total_sales,
ROUND(AVG(o.usd_price),2) as aov
FROM core.orders o
JOIN core.customers c
  ON o.customer_id = c.id
JOIN core.geo_lookup g
  ON g.country_code = c.country_code
WHERE product_name like '%Macbook%'
AND g.region = 'NA'
GROUP BY 1, 2
ORDER BY 1;

-- For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 

SELECT gl.region,
      ROUND(AVG(DATE_DIFF(os.delivery_ts, os.purchase_ts, day)),0) AS days_to_deliver
FROM core.order_status AS os
LEFT JOIN core.orders AS o
ON os.order_id = o.id
LEFT JOIN core.customers AS c
ON o.customer_id = c.id
LEFT JOIN core.geo_lookup AS gl
ON c.country_code = gl.country_code
WHERE (EXTRACT(year from os.purchase_ts) = 2022
AND o.purchase_platform = 'website')
OR o.purchase_platform = 'mobile'
GROUP BY 1
ORDER BY 2 DESC;

-- What was the refund rate and refund count for each product overall? 

SELECT CASE WHEN o.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor'
      ELSE o.product_name END AS cleaned_product_name,
      ROUND(AVG(CASE WHEN os.refund_ts IS NULL THEN 0 ELSE 1 END)*100,2) AS refund_rate,
      COUNT(CASE WHEN os.refund_ts IS NULL THEN 0 ELSE 1 END) AS refund_count
FROM core.orders AS o
JOIN core.order_status AS os
ON o.id = os.order_id
GROUP BY 1
ORDER BY 2 DESC, 3;

-- Within each region, what is the most popular product?
WITH region_orders AS(
SELECT gl.region,
      CASE WHEN o.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor'
      ELSE o.product_name END AS cleaned_product_name,
      COUNT(o.id) AS order_count
FROM core.orders AS o
LEFT JOIN core.customers AS c
ON o.customer_id = c.id
LEFT JOIN core.geo_lookup AS gl
ON c.country_code = gl.country_code
GROUP BY 1, 2),

product_rank AS(
SELECT *,
      RANK() OVER (PARTITION BY region ORDER BY order_count DESC) AS order_rank
FROM region_orders
GROUP BY 1, 2, 3)

SELECT *
FROM product_rank
WHERE order_rank = 1
AND region IS NOT NULL;

-- What were the top 3 products for each region?

WITH region_orders AS(
SELECT gl.region,
      CASE WHEN o.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor'
      ELSE o.product_name END AS cleaned_product_name,
      COUNT(o.id) AS order_count
FROM core.orders AS o
LEFT JOIN core.customers AS c
ON o.customer_id = c.id
LEFT JOIN core.geo_lookup AS gl
ON c.country_code = gl.country_code
GROUP BY 1, 2),

product_rank AS(
SELECT *,
      RANK() OVER (PARTITION BY region ORDER BY order_count DESC) AS order_rank
FROM region_orders
GROUP BY 1, 2, 3)

SELECT *
FROM product_rank
WHERE order_rank <= 3
AND region IS NOT NULL;

-- How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 
SELECT CASE WHEN c.loyalty_program = 0 THEN 'Non Loyalty'
      ELSE 'Loyalty' END AS loyalty_program,
      ROUND(AVG(DATE_DIFF(o.purchase_ts, c.created_on, day)),1) AS days_to_purchase,
      ROUND(AVG(DATE_DIFF(o.purchase_ts, c.created_on, month)),1) AS months_to_purchase
FROM core.customers AS c
JOIN core.orders AS o
ON c.id = o.customer_id
GROUP BY 1;

-- What were the sales revenue for each marketing channel?

SELECT COALESCE(c.marketing_channel, 'guest purchase') AS marketing_channel,
        ROUND(SUM(o.usd_price),2) AS sales_revenue,
        ROUND(AVG(o.usd_price),2) AS AOV,
        COUNT(o.id) AS order_count
FROM core.orders AS o
LEFT JOIN core.customers AS c
ON o.customer_id = c.id
GROUP BY 1
ORDER BY 2 DESC, 3 DESC, 4 DESC

-- How do the time to deliver differ between loyalty customers vs. non-loyalty customers?

SELECT CASE WHEN c.loyalty_program = 0 THEN 'Non Loyalty'
      ELSE 'Loyalty' END AS loyalty_program,
      ROUND(AVG(DATE_DIFF(os.ship_ts, os.purchase_ts, day)),1) AS days_to_ship,
      ROUND(AVG(DATE_DIFF(os.delivery_ts, os.ship_ts, day)),1) AS days_to_deliver,
FROM core.order_status AS os
LEFT JOIN core.orders AS o
ON os.order_id = o.id
LEFT JOIN core.customers AS c
ON o.customer_id = c.id
GROUP BY 1;
