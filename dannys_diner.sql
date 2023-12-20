CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

--1. What is the total amount each customer spent at the restaurant?

SELECT a.customer_id , SUM(b.price) AS total_amount_spent
FROM dannys_diner.sales a
JOIN dannys_diner.menu b
 ON a.product_id = b.product_id
GROUP BY a.customer_id
ORDER BY a.customer_id

--2.How many days has each customer visited the restaurant

SELECT customer_id , COUNT ( order_date) AS days_visited
FROM dannys_diner.sales a
GROUP BY customer_id
ORDER BY customer_id


--3. What was the first item from the menu purchased by each customer?

With CTE AS (SELECT a.customer_id , a.order_date, b.product_id , product_name,
 ROW_NUMBER() OVER (PARTITION BY a.customer_id  ORDER BY a.order_date ) AS first_item_purchased
FROM dannys_diner.sales a
JOIN dannys_diner.menu b
 ON a.product_id = b.product_id)
 
SELECT * 
FROM CTE
WHERE first_item_purchased = 1
ORDER BY customer_id

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

   
SELECT m.product_name AS most_purchased_item, COUNT(*) AS purchase_count
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
 ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count desc  
LIMIT 1

--5. Which item was the most popular for each customer

With items_counts AS (
SELECT s.customer_id , m.product_id, COUNT(m.product_name) AS Total,
	ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) desc ) AS row_num
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
 ON s.product_id = m.product_id
GROUP BY s.customer_id , m.product_id
)

SELECT ic.customer_id, m.product_name AS most_popular_item ,ic.total
FROM items_counts ic
JOIN dannys_diner.menu m
 ON ic.product_id = m.product_id
WHERE ic.row_num = 1

--6. Which item was purchased first by the customer after they became a member?

With Cte AS ( 
SELECT s.customer_id ,m.product_name , s.order_date, ms.join_date , 
	ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date)
FROM dannys_diner.sales s
 JOIN dannys_diner.menu m
ON s.product_id = m.product_id
 JOIN dannys_diner.members ms
ON s.customer_id = ms.customer_id
WHERE order_date >= join_date
)
 
SELECT *
FROM cte
WHERE row_number = 1


--7. Which item was purchased just before the customer became a member?
With Cte AS ( 
SELECT s.customer_id ,m.product_name , s.order_date, ms.join_date , 
	ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date)
FROM dannys_diner.sales s
 JOIN dannys_diner.menu m
ON s.product_id = m.product_id
 JOIN dannys_diner.members ms
ON s.customer_id = ms.customer_id
WHERE order_date < join_date
)
 
SELECT *
FROM cte
WHERE row_number = 1

--8. What is the total items and amount spent for each member before they became a member?

With Cte AS ( 
SELECT s.customer_id ,m.product_name ,m.price, s.order_date, ms.join_date , 
	ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date )
FROM dannys_diner.sales s
 JOIN dannys_diner.menu m
ON s.product_id = m.product_id
 JOIN dannys_diner.members ms
ON s.customer_id = ms.customer_id
WHERE order_date < join_date
)
 
SELECT customer_id , sum(cte.price)
FROM cte
GROUP BY customer_id


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

With cte AS (
 SELECT s.customer_id, m.product_name, m.price,
	CASE 
	 WHEN m.product_name = 'sushi' THEN 2 *  m.price * 10
	ELSE m.price * 10
	END AS points
FROM dannys_diner.sales s
	 JOIN dannys_diner.menu m
ON s.product_id = m.product_id
)

SELECT customer_id , SUM(cte.points) as total_points
FROM CTE
GROUP BY customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

With cte AS (
 SELECT s.customer_id, m.product_name, m.price,
	CASE 
	 WHEN m.product_name = 'sushi' THEN 2 *  m.price * 10
	 WHEN m.product_name = 'ramen' THEN 2 *  m.price * 10
	 WHEN m.product_name = 'curry' THEN 2 *  m.price * 10
	END AS points
FROM dannys_diner.sales s
	 JOIN dannys_diner.menu m
ON s.product_id = m.product_id
      JOIN dannys_diner.members ms
ON s.customer_id = ms.customer_id
WHERE ms.join_date >='2021-01-01' AND s.order_date <='2021-01-31'
)

SELECT customer_id , SUM(points)ASotal_points
FROM CTE
GROUP BY customer_id

