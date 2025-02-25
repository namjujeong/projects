CREATE TABLE plans (
  plan_id INTEGER,
  plan_name VARCHAR(13),
  price DECIMAL(5,2)
);

INSERT INTO plans
  (plan_id, plan_name, price)
VALUES
  ('0', 'trial', '0'),
  ('1', 'basic monthly', '9.90'),
  ('2', 'pro monthly', '19.90'),
  ('3', 'pro annual', '199'),
  ('4', 'churn', null);



CREATE TABLE subscriptions (
  customer_id INTEGER,
  plan_id INTEGER,
  start_date DATE
);

INSERT INTO subscriptions
  (customer_id, plan_id, start_date)
VALUES
  ('1', '0', '2020-08-01'),
  ('1', '1', '2020-08-08'),
  ('2', '0', '2020-09-20'),
  ('2', '3', '2020-09-27'),
  ('3', '0', '2020-01-13'),
  ... (2650 rows)


/* Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier! */
SELECT * FROM subscriptions S
JOIN plans P ON S.plan_id = P.plan_id
WHERE customer_id IN (1,2,3,4,5)

/* How many customers has Foodie-Fi ever had? */
SELECT COUNT(DISTINCT customer_id) AS customer_count FROM subscriptions

/* What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value */
SELECT DATEPART(month, start_date) AS month_name, COUNT(customer_id) AS customer_count FROM subscriptions
WHERE plan_id = 0
GROUP BY DATEPART(month, start_date)
ORDER BY DATEPART(month, start_date)

/* What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name */
SELECT plan_name, COUNT(customer_id) AS customer_count FROM subscriptions S
JOIN plans P ON P.plan_id = S.plan_id
WHERE DATEPART(year, start_date) > 2020
GROUP BY plan_name

/* What is the customer count and percentage of customers who have churned rounded to 1 decimal place? */
SELECT COUNT(customer_id) AS chrun_count,
ROUND(100.0*COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 1) AS churn_perc FROM subscriptions
WHERE plan_id = 4

/* How many customers have churned straight after their initial free trial
- what percentage is this rounded to the nearest whole number? */
SELECT COUNT(customer_id) AS customers, 100*COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)
FROM(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS plan_order
	FROM subscriptions) Final
WHERE plan_id = 4 AND plan_order = 2

/* What is the number and percentage of customer plans after their initial free trial? */
SELECT plan_name, COUNT(customer_id) AS customer,
CAST(100.0*COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS float) AS customer_perc
FROM(
	SELECT customer_id, S.plan_id, start_date, plan_name,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY S.plan_id) AS plan_order
	FROM subscriptions S
	JOIN plans P ON P.plan_id = S.plan_id
	WHERE S.plan_id IN (1,2,3,4)) Final
WHERE plan_order = 1
GROUP BY plan_name

/* What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31? */
SELECT plan_name, COUNT(customer_id) AS customers,
	CAST(100.0*COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS float) AS perc
	FROM(
		SELECT customer_id, plan_name, start_date,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS new_row
		FROM subscriptions S
		JOIN plans P ON P.plan_id = S.plan_id
		WHERE start_date < '2021-01-01') Final
WHERE new_row = 1
GROUP BY plan_name

/* How many customers have upgraded to an annual plan in 2020? */
SELECT COUNT(DISTINCT customer_id) AS annual_plan_customer_2020 FROM subscriptions
WHERE plan_id = 3 AND start_date < '2021-01-01'

/* How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi? */
SELECT AVG(days_to_annual) AS avg_days_annual
FROM(
	SELECT customer_id, DATEDIFF(day, MIN(start_date), MAX(start_date)) AS days_to_annual FROM subscriptions
	WHERE plan_id = 0 OR plan_id = 3
	GROUP BY customer_id) Final
WHERE days_to_annual > 0

/* Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc) */
?????????????????????
SELECT *, WIDTH_BUCKET(days_to_annual, 0, 360, 12)
FROM(
	SELECT customer_id, DATEDIFF(day, MIN(start_date), MAX(start_date)) AS days_to_annual FROM subscriptions
	WHERE plan_id = 0 OR plan_id = 3
	GROUP BY customer_id
	ORDER BY days_to_annual) Final

/* How many customers downgraded from a pro monthly to a basic monthly plan in 2020? */
WITH CTE AS(
	SELECT * FROM subscriptions
	WHERE plan_id = 2)

SELECT * FROM CTE
JOIN subscriptions S ON S.customer_id = CTE.customer_id
WHERE CTE.start_date < S.start_date AND YEAR(S.start_date) = 2020 AND S.plan_id = 1