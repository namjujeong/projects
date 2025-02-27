CREATE TABLE regions (
  region_id INTEGER,
  region_name VARCHAR(9)
);

INSERT INTO regions
  (region_id, region_name)
VALUES
  ('1', 'Australia'),
  ('2', 'America'),
  ('3', 'Africa'),
  ('4', 'Asia'),
  ('5', 'Europe');

CREATE TABLE customer_nodes (
  customer_id INTEGER,
  region_id INTEGER,
  node_id INTEGER,
  start_date DATE,
  end_date DATE
);

INSERT INTO customer_nodes
  (customer_id, region_id, node_id, start_date, end_date)
VALUES
  ('497', '5', '4', '2020-05-27', '9999-12-31'),
  ('498', '1', '2', '2020-04-05', '9999-12-31'),
  ('499', '5', '1', '2020-02-03', '9999-12-31'),
  ('500', '2', '2', '2020-04-15', '9999-12-31');

CREATE TABLE customer_transactions (
  customer_id INTEGER,
  txn_date DATE,
  txn_type VARCHAR(10),
  txn_amount INTEGER
);

INSERT INTO customer_transactions
  (customer_id, txn_date, txn_type, txn_amount)
VALUES
  ('189', '2020-03-17', 'purchase', '726'),
  ('189', '2020-03-18', 'withdrawal', '462'),
  ('189', '2020-01-30', 'purchase', '956'),
  ('189', '2020-02-03', 'withdrawal', '870'),
  ('189', '2020-03-22', 'purchase', '718'),
  ('189', '2020-02-06', 'purchase', '393'),
  ('189', '2020-01-22', 'deposit', '302'),
  ('189', '2020-01-27', 'withdrawal', '861');


/* How many unique nodes are there on the Data Bank system? */
SELECT COUNT(DISTINCT node_id) AS nodes FROM customer_nodes

/* What is the number of nodes per region? */
SELECT region_name, COUNT(DISTINCT node_id) AS nodes FROM customer_nodes CN
JOIN regions R ON R.region_id = CN.region_id
GROUP BY region_name

/* How many customers are allocated to each region? */
SELECT region_name, COUNT(DISTINCT customer_id) AS customers FROM customer_nodes CN
JOIN regions R ON R.region_id = CN.region_id
GROUP BY region_name

/* How many days on average are customers reallocated to a different node? */
SELECT customer_id, AVG(days_before_change) AS avg_days
FROM(
	SELECT customer_id, node_id, DATEDIFF(day, start_date, end_date) AS days_before_change,
	ROW_NUMBER() OVER(PARTITION BY customer_id, node_id ORDER BY start_date) AS change_order
	FROM customer_nodes
	WHERE end_date != '9999-12-31') Final
GROUP BY customer_id
ORDER BY customer_id

/* What is the median, 80th and 95th percentile for this same reallocation days metric
for each region? */
?????????????/
SELECT * FROM customer_nodes
ORDER BY customer_id


/* What is the unique count and total amount for each transaction type? */
SELECT txn_type, COUNT(txn_amount) AS transaction_count, SUM(txn_amount) AS total_amount FROM customer_transactions
GROUP BY txn_type

/* What is the average total historical deposit counts and amounts for all customers? */
WITH CTE AS(
	SELECT customer_id, COUNT(txn_amount) AS counts, AVG(txn_amount) AS amounts FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id)

SELECT AVG(counts) AS avg_counts, AVG(amounts) AS avg_amounts FROM CTE

/* For each month - how many Data Bank customers make more than 1 deposit
and either 1 purchase or 1 withdrawal in a single month? */
WITH CTE AS(
	SELECT customer_id, txn_month, SUM(type) AS monthly_value
	FROM(	
		SELECT DISTINCT customer_id, MONTH(txn_date) AS txn_month,
		CASE
			WHEN txn_type = 'deposit' THEN 1
			WHEN txn_type = 'purchase' THEN 2
			WHEN txn_type = 'withdrawal' THEN 4
			ELSE 0
			END AS type
		FROM customer_transactions) Final
	GROUP BY customer_id, txn_month)

SELECT txn_month, COUNT(customer_id) AS customers FROM CTE
WHERE monthly_value > 1
GROUP BY txn_month

/* What is the closing balance for each customer at the end of the month? */
WITH CTE AS(
	SELECT customer_id, closing_month, SUM(balance_change) AS monthly_change
	FROM(
		SELECT customer_id, MONTH(txn_date) AS closing_month,
		CASE
			WHEN txn_type = 'deposit' THEN txn_amount
			ELSE txn_amount*(-1)
			END AS balance_change
		FROM customer_transactions) Final
	GROUP BY customer_id, closing_month)

SELECT customer_id, closing_month, monthly_change, SUM(monthly_change) OVER(PARTITION BY customer_id ORDER BY closing_month) AS closing_balance
FROM CTE


/* What is the percentage of customers who increase their closing balance by more than 5%? */
???????????????
SELECT customer_id, SUM(balance_change) AS closing_balance
FROM(
	SELECT customer_id, MONTH(txn_date) AS txn_month,
		CASE
			WHEN txn_type = 'deposit' THEN txn_amount
			ELSE txn_amount*(-1)
			END AS balance_change
	FROM customer_transactions) Final
GROUP BY customer_id
ORDER BY customer_id

/*  */
