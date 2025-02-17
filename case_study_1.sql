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


/* What is the total amount each customer spend at the restaurant? */
SELECT customer_id, SUM(price) FROM sales S
JOIN menu M on M.product_id = S.product_id
GROUP BY customer_id

/* How many days has each customer visited the restaurant? */
SELECT customer_id, COUNT(DISTINCT order_date) FROM sales
GROUP BY customer_id

/* What was the first item from the menu purchased by each customer? */
SELECT customer_id, product_name AS first_item_purchased
FROM (
	SELECT customer_id, order_date, product_id,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS No
	FROM sales
	) AddNo
JOIN menu M on M.product_id = AddNo.product_id
WHERE No = 1

/* What is the most purchased item on the menu and how many times was it purchased by all customers? */
SELECT product_name, COUNT(S.product_id) AS qty_purchased FROM sales S
JOIN menu M on S.product_id = M.product_id
GROUP BY product_name

/* Which item was the most popular for each customer? */
SELECT customer_id, product_name
FROM(
	SELECT customer_id, product_name, COUNT(S.product_id) AS QtyOrder,
	rank() OVER (PARTITION BY customer_id ORDER BY COUNT(S.product_id) DESC) AS PopularMenu
	FROM sales S
	JOIN menu M ON M.product_id = S.product_id
	GROUP BY customer_id, product_name
	) Final
WHERE PopularMenu = 1

/* Which item was purchased first by the customer after they became a member? */
SELECT customer_id, order_date, product_name
FROM(
	SELECT S.customer_id, product_name, order_date,
	ROW_NUMBER() OVER (PARTITION BY S.customer_id ORDER BY order_date) AS FirstOrderAfterMember
	FROM sales S
	JOIN menu M ON M.product_id = S.product_id
	JOIN members MS ON MS.customer_id = S.customer_id
	WHERE join_date < order_date) Final
WHERE FirstOrderAfterMember = 1

/* Which item was purchased just before the customer became a member? */
SELECT customer_id, order_date, product_name
FROM(
	SELECT S.customer_id, product_name, order_date, join_date,
	ROW_NUMBER() OVER (PARTITION BY S.customer_id ORDER BY order_date DESC) AS LastOrderBeforeMember
	FROM sales S
	JOIN menu M ON M.product_id = S.product_id
	JOIN members MS ON MS.customer_id = S.customer_id
	WHERE join_date > order_date) Final
WHERE LastOrderBeforeMember = 1

/* What is the total items and amount spent for each member before they became a member? */
SELECT customer_id, COUNT(product_id) AS total_item, SUM(price) AS amount_spent
FROM(
	SELECT S.customer_id, order_date, S.product_id, price, COALESCE(join_date, GETDATE()+1) AS JoinDate FROM sales S
	LEFT JOIN members MS ON MS.customer_id = S.customer_id
	JOIN menu M ON M.product_id = S.product_id) FinalTable
WHERE order_date < JoinDate
GROUP BY customer_id

/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */
SELECT customer_id, SUM(point) AS point
FROM(
	SELECT S.customer_id, 
	CASE
		WHEN S.product_id=1 THEN price*20
		ELSE price*10
	END AS point
	FROM sales S
	JOIN members MS ON MS.customer_id = S.customer_id
	JOIN menu M ON M.product_id = S.product_id
	WHERE join_date < order_date) Final
GROUP BY customer_id

/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */
SELECT customer_id, SUM(point)
FROM(
	SELECT S.customer_id, join_date, order_date, price, S.product_id,
	CASE
		WHEN DATEADD(day, 6, join_date) > order_date OR S.product_id = 1 THEN price*20
		ELSE price*10
	END AS point
	FROM sales S
	JOIN members MS ON MS.customer_id = S.customer_id
	JOIN menu M ON M.product_id = S.product_id
	WHERE order_date > join_date) Final
WHERE order_date <= EOMONTH('2021-01-01')
GROUP BY customer_id