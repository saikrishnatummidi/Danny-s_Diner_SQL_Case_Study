-- 1.What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, sum(me.price) as Amount_Spent 
FROM sales s 
left join menu me on me.product_id = s.product_id 
GROUP BY s.customer_id;

-- 2.How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(*) AS Days_Visited
FROM sales 
GROUP BY customer_id;

-- 3.What was the first item from the menu purchased by each customer?
WITH cte as(
SELECT s.*, m.product_name, dense_rank() OVER(PARTITION BY customer_id ORDER BY order_date) AS RN
FROM sales s 
JOIN menu m ON m.product_id = s.product_id
)
SELECT cte.customer_id, cte.product_name 
FROM cte 
WHERE RN = 1;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_id, m.product_name, COUNT(*) AS No_of_Times_Purchased
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_id, m.product_name
ORDER BY No_of_Times_Purchased DESC
LIMIT 1;

-- 5.Which item was the most popular for each customer?
WITH sales_ranking AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(s.product_id) AS total_purchases,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id,
    product_name AS most_popular_item,
    total_purchases
FROM sales_ranking
WHERE rnk = 1;


-- 6.Which item was purchased first by the customer after they became a member?
WITH first_item AS (
    SELECT s.customer_id, m.product_name, mem.join_date, s.order_date,
        ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_rank
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date > mem.join_date
)
SELECT 
    customer_id,
    product_name AS first_purchased_item,
    join_date as Join_date,
    order_date AS purchase_date
FROM first_item
WHERE purchase_rank = 1;


-- 7.Which item was purchased just before the customer became a member?
WITH first_item AS (
    SELECT s.customer_id, m.product_name, me.join_date, s.order_date,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date desc) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members me ON s.customer_id = me.customer_id
    WHERE s.order_date < me.join_date
)
SELECT 
    customer_id, product_name AS first_purchased_item, join_date as Join_date,
    order_date AS purchase_date
FROM first_item
WHERE rnk = 1;

-- 8.What is the total items and amount spent for each member before they became a member?
WITH cte AS (
    SELECT 
        mem.customer_id,
        SUM(m.price) AS total_amount,
        COUNT(*) AS total_items
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date OR mem.customer_id IS NULL
    GROUP BY s.customer_id
	ORDER  BY mem.customer_id
)
SELECT customer_id, total_items, total_amount
FROM cte;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
    s.customer_id,
    SUM(CASE WHEN m.product_name = 'sushi' THEN 20 * m.price
             ELSE 10 * m.price
	     END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
