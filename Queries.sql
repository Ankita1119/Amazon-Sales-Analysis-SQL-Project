select count(*) from sellers;
select * from category;
select * from customer;
select * from inventory;
select * from order_items;
select * from orders;
select * from payments;
select * from products;
select * from sellers;
select * from shipment;

-- ----------------------------------------------
/*
top selling products.
query the top 10 products by total sales value.
challenge: include product name, total quantity sold , and total sales values
*/

SELECT
	p.product_name,
	Round(SUM(oi.quantity * oi.price_per_unit),2) as total_sale,
	SUM(oi.quantity) as total_quantity_sold
FROM order_items oi
JOIN orders o 
ON oi.order_id = o.order_id
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sale DESC
LIMIT 10;

/*
2. Revenue by category
calculate total revenue generated by each product category
challenge: include the percentage contribution of each category to total revenue.
*/

SELECT
p.category_id, c.category_name,
ROUND(SUM(oi.quantity * oi.price_per_unit),2) as total_revenue,
SUM(oi.quantity * oi.price_per_unit)/(select SUM(oi2.quantity * oi2.price_per_unit) from order_items oi2)*100 as contribution_percenatage
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
LEFT JOIN category c
ON p.category_id = c.category_id
GROUP BY p.category_id, c.category_name
ORDER BY category_id;

/*
3. Average order value(AOV)
compute the average order value for each customer
challenge: include only customer with more than 5 orders 
*/

SELECT 
c.customer_id,
concat(c.first_name, " " , c.last_name) as Full_name,
SUM(oi.quantity * oi.price_per_unit)/COUNT(o.order_id) as AOV,
COUNT(o.order_id) as Total_orders 
FROM orders o
JOIN customer c
ON o.customer_id = c.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY c.customer_id,Full_name
HAVING COUNT(o.order_id) > 5;

/*
4- Monthly sales trend
Query monthly total sales over the past year,
challenge: display the sales trend, return current month sale, last month sale 
*/

WITH CTE AS(
		SELECT YEAR(o.order_date) as Years,
		Month(o.order_date) as Months,
		ROUND(SUM(oi.quantity* oi.price_per_unit),2) as Current_sale
		FROM orders o
		JOIN order_items oi
		ON o.order_id = oi.order_id
		WHERE order_date >= current_date - INTERVAL 1 year
		GROUP BY  Month(o.order_date), YEAR(o.order_date)
		ORDER BY Years , Months )
SELECT 
	Years, Months, Current_sale,
	LAG(Current_sale, 1) OVER(ORDER BY Years, Months) as Previous_Month_sale
	FROM CTE
    ORDER BY Years, Months;

/*
5- Customers with no purchase
find the customers who have registred but never places an order
challenge: list customer details and the time since their registration
*/

-- Approach 1
SELECT 
	c.customer_id,
	CONCAT(c.first_name , "  " , c.last_name) as Full_name,
    COUNT(o.order_id) as Order_Placed
FROM customer c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_id is null
GROUP BY c.customer_id, Full_name;

-- Approach 2 using subquery

SELECT customer_id, Full_name, Order_Placed 
FROM (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, " ", c.last_name) AS Full_name,
        COUNT(o.order_id) AS Order_Placed
    FROM customer c
    LEFT JOIN orders o  
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, Full_name
) AS SubQuery
WHERE Order_Placed = 0;  -- Filters only customers with 0 orders

/*
6-Customer lifetime value (CLTV)
calculate total number of order value that customer placed over their lifetime
challenge: Rank customer based on their CLTV
*/

SELECT
	c.customer_id,
    CONCAT(c.first_name, " ", c.last_name) AS full_name,
    ROUND(SUM(oi.quantity * oi.price_per_unit),2) as CLTV,
    DENSE_RANK() over(ORDER BY SUM(oi.quantity * oi.price_per_unit) desc) as RANKING
	FROM customer c
	JOIN orders o 
	ON c.customer_id = o.customer_id
	JOIN order_items oi
	ON o.order_id = oi.order_id
	GROUP BY c.customer_id
    ORDER BY CLTV DESC;

/*
7- Inventory stock alerts
query products with stock level below certain threshold limit ( say 15 units )
challange: include last restock date and warehouse information
*/

SELECT 
	i.inventory_id,
	p.product_name, 
    i.stock as current_stock,
    i.last_stock_date,
    i.warehouse_id
FROM products p
JOIN inventory i
ON p.product_id = i.product_id
where i.stock < 15;

/*
8- shipping delays
identify the orders whose shipping date is 5 days later of the order date
challange: include customer, order details, and delivery provider
*/

SELECT 
    DATEDIFF(s.shipping_date, o.order_date) AS total_days,
    c.customer_id,
    o.order_id, 
    o.order_date,
    s.shipping_providers
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN shipment s ON o.order_id = s.order_id
WHERE DATEDIFF(s.shipping_date, o.order_date) > 5;

/*
9- payment sucess rate
calculate the percentage of succesfull payments across all orders
challenge include breakdown of payments (pending, failed)
*/

SELECT 
    p.payment_status,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments WHERE order_id IS NOT NULL) AS percentage_total_payment
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY p.payment_status;

/*
10- Top performing Sellers
Find the top 5 sellers based on their total sales

*/

SELECT 
	s.seller_id,
	s.seller_name,
	SUM(oi.quantity * oi.price_per_unit) as Total_sale
FROM orders o 
JOIN sellers s 
ON o.seller_id = s.seller_id
JOIN order_items oi
ON oi.order_id = o.order_id
GROUP BY 
	s.seller_id,
    s.seller_name
ORDER BY Total_sale DESC
LIMIT 5;

-- end of quries -- 







