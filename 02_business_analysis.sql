USE corporate_sales_analytics_db;


-- 1. What are the company's overall sales performance KPIs,
-- including total orders, revenue and profit?
SELECT 
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(sales) AS total_revenue,
	SUM(profit) AS total_profit,
    ROUND(
        SUM(profit) * 100.0 / SUM(sales), 2
    ) AS profit_margin_pct
FROM orders;



-- 2. Identify our top 10 elite customers whose total value exceeds three 
-- times the average order value baseline
WITH order_value AS (
SELECT 
	SUM(sales) / COUNT(DISTINCT order_id) 
	AS avg_order_value
FROM orders 
)

SELECT TOP 10
	c.customer_name,
	SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
CROSS JOIN order_value ov
GROUP BY 
    c.customer_name, 
    ov.avg_order_value
HAVING 
    SUM(o.sales) > 3 * ov.avg_order_value
ORDER BY 
    SUM(o.sales) DESC;



-- 3. Which customers generate high revenue but deliver poor profitability, indicating potential 
-- pricing or discount issues?
WITH customer_summary AS(
SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.sales) AS total_sales,
    SUM(o.profit) AS total_profit,
    ROUND((SUM(o.profit) * 100.0 / SUM(o.sales)), 2) AS profit_margin_pct
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
),

avg_profit_tbl AS(
SELECT
    AVG(profit_margin_pct) AS avg_profit_margin
FROM customer_summary
)

SELECT TOP 10
    cs.customer_name,
    cs.total_sales,
    cs.total_profit,
    cs.profit_margin_pct
FROM customer_summary cs
CROSS JOIN avg_profit_tbl ap
WHERE
    cs.total_sales >
    (
        SELECT AVG(total_sales)
        FROM customer_summary
    )
    AND cs.profit_margin_pct < ap.avg_profit_margin
ORDER BY
    cs.total_sales DESC,
    cs.profit_margin_pct ASC;



-- 4. Which products consistently generate losses despite strong sales,
-- indicating candidates for pricing or cost optimization (top 10)?

WITH product_summary AS(
SELECT 
    p.product_id,
    p.product_name,
    SUM(o.quantity) AS total_quantity,
    SUM(o.sales) AS total_sales,
    SUM(o.profit) AS total_profit    
FROM products p
JOIN orders o
    ON p.product_id = o.product_id
GROUP BY 
    p.product_id,
    p.product_name
)

SELECT TOP 10
    product_id,
    product_name,
    total_quantity,
    total_sales,
    total_profit,
    ROUND(
        total_profit / total_quantity, 2
    ) AS profit_loss_per_unit
FROM product_summary
WHERE 
    total_sales > 
    (
        SELECT AVG(total_sales) 
        FROM product_summary
    )
    AND total_profit < 0
ORDER BY
    total_sales DESC,
    total_profit ASC;



-- 5. Which markets and regions deliver the highest profit margins,
-- helping management prioritize future investments?
SELECT
    l.market,
    l.region,
    SUM(o.sales) AS total_sales,
    SUM(o.profit) AS total_profit,
    ROUND( 
        SUM(o.profit) * 100.0 / SUM(o.sales), 2
    ) AS profit_margin_pct
FROM locations l
JOIN orders o
    ON l.location_id = o.location_id
GROUP BY
    l.market,
    l.region
ORDER BY
    profit_margin_pct DESC,
    total_profit DESC;



-- 6. Which markets incur the highest shipping cost relative to sales,
-- indicating opportunities to optimize logistics expenses?
SELECT 
    l.market,
    SUM(o.shipping_cost) AS total_shipping_cost,
    SUM(o.sales) AS total_sales,
    ROUND( 
        SUM(o.shipping_cost) * 100.0 / SUM(o.sales), 2
    ) AS shipping_cost_pct
FROM locations l
JOIN orders o
    ON l.location_id = o.location_id
GROUP BY 
    l.market
ORDER BY
    shipping_cost_pct DESC;



-- 7. How have monthly sales and profit changed over time,
-- and are there any seasonal trends in business performance?
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY
    YEAR(order_date),
    MONTH(order_date);



-- 8. Rank customers within each market based on total revenue generated,
-- helping identify high-value customers across different business regions.

WITH customer_ranking AS (
SELECT 
    c.customer_id,
    c.customer_name,
    l.market,
    SUM(o.sales) AS total_sales,
    DENSE_RANK() OVER( 
        PARTITION BY l.market 
        ORDER BY SUM(o.sales) DESC
    ) AS customer_rank        
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN locations l
    ON l.location_id = o.location_id
GROUP BY
    c.customer_id,
    c.customer_name,
    l.market
)

SELECT * FROM customer_ranking
WHERE customer_rank = 1;



-- 9. How has annual business performance changed compared to the previous year,
-- and what is the year-over-year sales growth percentage?
WITH yearly_sales_comparison AS (
SELECT
    YEAR(order_date) AS year_date,
    SUM(sales) AS total_sales,
    LAG( SUM(sales) ) OVER(
            ORDER BY YEAR(order_date)
    ) AS previous_year_total_sales
FROM orders
GROUP BY YEAR(order_date)
)

SELECT 
    *,
    ROUND(
    (total_sales - previous_year_total_sales) * 100.0
    / previous_year_total_sales, 2
    ) AS yoy_sales_growth_pct
FROM yearly_sales_comparison;



-- 10. Does offering higher discounts lead to improved profitability,
-- or does it negatively impact business margins?
SELECT
    discount,
    COUNT(*) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(
        SUM(profit) * 100.0 / SUM(sales), 2
    ) AS profit_margin_pct
FROM orders
GROUP BY
    discount
ORDER BY
    discount;



-- 11. Identify the best-performing customer segment by evaluating
-- revenue, profitability, average order value, and profit margin.
SELECT
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.sales) AS total_sales,
    SUM(o.profit) AS total_profit,
    ROUND(
        SUM(o.sales) * 1.0 /
        COUNT(DISTINCT o.order_id), 2
    ) AS average_order_value,
    ROUND(
        SUM(o.profit) * 100.0 /
        SUM(o.sales), 2
    ) AS profit_margin_pct
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.segment
ORDER BY
    total_profit DESC;