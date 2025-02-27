DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" DATETIME
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

/* Changed Data type of pizza_name from TEXT to VARCHAR */
DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" VARCHAR(20)
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

/* Data Cleaning and Transformation */
SELECT order_id, customer_id, pizza_id,
	CASE
		WHEN exclusions IS NULL OR exclusions LIKE 'null' THEN ''
		ELSE exclusions
		END AS exclusions,
	CASE
		WHEN extras IS NULL OR extras LIKE 'null' THEN ''
		ELSE extras
		END AS extras,
	order_time
INTO new_customer_orders
FROM customer_orders


SELECT order_id, runner_id,
	CASE
		WHEN pickup_time LIKE 'null' THEN ''
		ELSE pickup_time
		END AS pickup_time,
	CASE
		WHEN distance LIKE 'null' THEN ''
		WHEN distance LIKE '%km' THEN TRIM('km' from distance)
		ELSE distance
		END AS distance,
	CASE
		WHEN duration LIKE 'null' THEN ''
		WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
		ELSE duration
		END AS duration,
	CASE
		WHEN cancellation IS NULL OR cancellation LIKE 'null' THEN ''
		ELSE cancellation
		END AS cancellation
INTO new_runner_orders
FROM runner_orders


/* A. Pizza Metrics
How many pizzas were ordered? */
SELECT COUNT(order_id) FROM customer_orders

/* How many unique customer orders were made? */
SELECT COUNT(DISTINCT customer_id) FROM customer_orders

/* How many successful orders were delivered by each runner? */
SELECT COUNT(order_id) FROM runner_orders
WHERE pickup_time IS NOT NULL

/* How many of each type of pizza was delivered? */
SELECT pizza_name, COUNT(CO.order_id) AS delivered_pizza FROM new_customer_orders CO
JOIN new_runner_orders RO ON CO.order_id = RO.order_id
JOIN pizza_names PN ON PN.pizza_id = CO.pizza_id
WHERE duration != 0
GROUP BY pizza_name

/* How many Vegetarian and Meatlovers were ordered by each customer? */
SELECT customer_id, pizza_name, COUNT(order_id) AS ordered_pizza FROM new_customer_orders CO
JOIN pizza_names PZ ON PZ.pizza_id = CO.pizza_id
GROUP BY customer_id, pizza_name

/* What was the maximum number of pizzas delivered in a single order? */
SELECT MAX(number_of_pizzas) AS max_number
FROM(
	SELECT order_id, COUNT(pizza_id) AS number_of_pizzas FROM new_customer_orders
	GROUP BY order_id) Final

/* For each customer, how many delivered pizzas had at least 1 change and how many had no changes? */
SELECT customer_id, change, COUNT(order_id) AS orders
FROM(
	SELECT CO.order_id, customer_id,
		CASE
			WHEN exclusions = '' AND extras = '' THEN 'no_change'
			ELSE 'yes'
			END AS change
	FROM new_customer_orders CO
	JOIN new_runner_orders RO ON RO.order_id = CO.order_id
	WHERE duration > 0) Final
GROUP BY customer_id, change

/* How many pizzas were delivered that had both exclusions and extras? */
SELECT COUNT(*) AS delivered_pizza_w_both_ex FROM new_customer_orders CO
JOIN new_runner_orders RO ON RO.order_id = CO.order_id
WHERE exclusions <> '' AND extras <> '' AND duration > 0

/* What was the total volume of pizzas ordered for each hour of the day? */
SELECT DATEPART(hour, order_time) AS hour, COUNT(order_id) AS ordered_pizza FROM new_customer_orders
GROUP BY DATEPART(hour, order_time)

/* What was the volume of orders for each day of the week? */
SELECT FORMAT(order_time, 'dddd') AS day_of_week, COUNT(order_id) AS ordered_pizza FROM new_customer_orders
GROUP BY FORMAT(order_time, 'dddd')

/* How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) */
SELECT COUNT(runner_id) FROM runners
WHERE registration_date >= '20210101' AND registration_date < DATEADD(day, 7, '20210101')

SELECT CONCAT('week', DATEPART(week, registration_date)) AS registration, COUNT(runner_id) AS signed_runner FROM runners
GROUP BY DATEPART(week, registration_date)

/* What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order? */
SELECT runner_id, AVG(DATEPART(minute, pickup_time - order_time)) AS avg_pickup_min FROM new_customer_orders CO
JOIN new_runner_orders RO ON CO.order_id = RO.order_id
WHERE pickup_time <> ''
GROUP BY runner_id

/* Is there any relationship between the number of pizzas and how long the order takes to prepare? */
SELECT ordered_pizza, AVG(DATEPART(minute, pickup_time - order_time)) AS avg_min_to_prepare
FROM(
	SELECT CO.order_id, order_time, pickup_time, COUNT(pizza_id) AS ordered_pizza FROM new_customer_orders CO
	JOIN new_runner_orders RO ON CO.order_id = RO.order_id
	WHERE pickup_time <> ''
	GROUP BY CO.order_id, order_time, pickup_time) Final
GROUP BY ordered_pizza

/* What was the average distance travelled for each customer? */
ALTER TABLE new_runner_orders
ALTER COLUMN distance FLOAT
ALTER TABLE new_runner_orders
ALTER COLUMN duration FLOAT

SELECT customer_id, AVG(distance) AS avg_distance FROM new_customer_orders CO
JOIN new_runner_orders RO ON CO.order_id = RO.order_id
WHERE distance <> 0
GROUP BY customer_id

/* What was the difference between the longest and shortest delivery times for all orders? */
SELECT MAX(duration) - MIN(duration) FROM new_runner_orders
WHERE duration != 0

/* What was the average speed for each runner for each delivery and do you notice any trend for these values? */
SELECT runner_id, CO.order_id, customer_id, COUNT(*) AS pizza_qty, AVG(distance/(duration/60)) AS speed FROM new_runner_orders RO
JOIN new_customer_orders CO ON CO.order_id = RO.order_id
WHERE duration != 0
GROUP BY runner_id, CO.order_id, customer_id

/* What is the successful delivery percentage for each runner? */
SELECT runner_id,
	100 * SUM(
		CASE WHEN distance != 0 THEN 1
		ELSE 0 END)/COUNT(*) AS successful_perc
FROM new_runner_orders
GROUP BY runner_id


/* What are the standard ingredients for each pizza? */
SELECT SUBSTRING(toppings, 0, CHARINDEX(', ', toppings)) FROM pizza_recipes

SELECT * FROM STRING_SPLIT((SELECT toppings FROM pizza_recipes WHERE pizza_id=1), ',')

SELECT
  pizza_id,
  REGEXP_SPLIT_TO_ARRAY(toppings, '\s+') AS topping_id
FROM pizza_recipes

/* What was the most commonly added extra? */

/* What was the most common exclusion? */

/* Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */

/* Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */

/* What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first? */



/* If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees? */
SELECT SUM(price) AS profit
FROM(
	SELECT
		CASE
			WHEN pizza_id = 1 THEN 12
			ELSE 10
			END AS price
	FROM new_customer_orders) Final

/* What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra */


/* The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5. */


/* Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas */

/* If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled
- how much money does Pizza Runner have left over after these deliveries? */
SELECT SUM(price) - SUM(delivery_fee) AS profit
FROM(
	SELECT
		CASE
			WHEN pizza_id = 1 THEN 12
			ELSE 10
			END AS price,
		0.3*distance AS delivery_fee
		FROM new_customer_orders CO
JOIN new_runner_orders RO ON RO.order_id = CO.order_id) Final

/* If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu? */
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme')

INSERT INTO pizza_recipes(pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12')
