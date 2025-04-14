## Case Study #4: Data Bank

<img src="https://user-images.githubusercontent.com/81607668/130343294-a8dcceb7-b6c3-4006-8ad2-fab2f6905258.png" alt="Image" width="500" height="520">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

Please note that all the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-4/). 

***

## Business Task
Danny launched a new initiative, Data Bank which runs **banking activities** and also acts as the world’s most secure distributed **data storage platform**!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. 

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Entity Relationship Diagram

<img width="631" alt="image" src="https://user-images.githubusercontent.com/81607668/130343339-8c9ff915-c88c-4942-9175-9999da78542c.png">

**Table 1: `regions`**

This regions table contains the `region_id` and their respective `region_name` values.

<img width="176" alt="image" src="https://user-images.githubusercontent.com/81607668/130551759-28cb434f-5cae-4832-a35f-0e2ce14c8811.png">

**Table 2: `customer_nodes`**

Customers are randomly distributed across the nodes according to their region. This random distribution changes frequently to reduce the risk of hackers getting into Data Bank’s system and stealing customer’s money and data!

<img width="412" alt="image" src="https://user-images.githubusercontent.com/81607668/130551806-90a22446-4133-45b5-927c-b5dd918f1fa5.png">

**Table 3: Customer Transactions**

This table stores all customer deposits, withdrawals and purchases made using their Data Bank debit card.

<img width="343" alt="image" src="https://user-images.githubusercontent.com/81607668/130551879-2d6dfc1f-bb74-4ef0-aed6-42c831281760.png">

***

## Question and Solution

If you have any questions, reach out to me on [LinkedIn](https://www.linkedin.com/in/namjujeong/).

## 🏦 A. Customer Nodes Exploration

**1. How many unique nodes are there on the Data Bank system?**

````sql
SELECT COUNT(DISTINCT node_id) AS nodes FROM customer_nodes
````

**Answer:**

|unique_nodes|
|:----|
|5|

- There are 5 unique nodes on the Data Bank system.

***

**2. What is the number of nodes per region?**

````sql
SELECT region_name, COUNT(DISTINCT node_id) AS nodes FROM customer_nodes CN
JOIN regions R ON R.region_id = CN.region_id
GROUP BY region_name
````

**Answer:**

|region_name|node_count|
|:----|:----|
|Africa|5|
|America|5|
|Asia|5|
|Australia|5|
|Europe|5|

***

**3. How many customers are allocated to each region?**

````sql
SELECT region_name, COUNT(DISTINCT customer_id) AS customers FROM customer_nodes CN
JOIN regions R ON R.region_id = CN.region_id
GROUP BY region_name
````

**Answer:**

|region_id|customer_count|
|:----|:----|
|1|770|
|2|735|
|3|714|
|4|665|
|5|616|

***

**4. How many days on average are customers reallocated to a different node?**

````sql
SELECT customer_id, AVG(days_before_change) AS avg_days
FROM(
	SELECT customer_id, node_id, DATEDIFF(day, start_date, end_date) AS days_before_change,
	ROW_NUMBER() OVER(PARTITION BY customer_id, node_id ORDER BY start_date) AS change_order
	FROM customer_nodes
	WHERE end_date != '9999-12-31') Final
GROUP BY customer_id
ORDER BY customer_id
````

**Answer:**

|avg_node_reallocation_days|
|:----|
|24|

- On average, customers are reallocated to a different node every 24 days.



## 🏦 B. Customer Transactions

**1. What is the unique count and total amount for each transaction type?**

````sql
SELECT txn_type, COUNT(txn_amount) AS transaction_count, SUM(txn_amount) AS total_amount FROM customer_transactions
GROUP BY txn_type
````

**Answer:**

|txn_type|transaction_count|total_amount|
|:----|:----|:----|
|purchase|1617|806537|
|deposit|2671|1359168|
|withdrawal|1580|793003|

***

**2. What is the average total historical deposit counts and amounts for all customers?**

````sql
WITH CTE AS(
	SELECT customer_id, COUNT(txn_amount) AS counts, AVG(txn_amount) AS amounts FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id)

SELECT AVG(counts) AS avg_counts, AVG(amounts) AS avg_amounts FROM CTE
````
**Answer:**

|avg_deposit_count|avg_deposit_amt|
|:----|:----|
|5|509|

- The average historical deposit count is 5 and the average historical deposit amount is $ 509.

***

**3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?**

First, create a CTE called `monthly_transactions` to determine the count of deposit, purchase and withdrawal for each customer categorised by month using `CASE` statement and `SUM()`. 

In the main query, select the `mth` column and count the number of unique customers where:
- `deposit_count` is greater than 1, indicating more than one deposit (`deposit_count > 1`).
- Either `purchase_count` is greater than or equal to 1 (`purchase_count >= 1`) OR `withdrawal_count` is greater than or equal to 1 (`withdrawal_count >= 1`).

````sql
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
````

**Answer:**

|month|customer_count|
|:----|:----|
|1|170|
|2|277|
|3|292|
|4|103|

***

**4. What is the closing balance for each customer at the end of the month? Also show the change in balance each month in the same table output.**

Update Jun 2, 2023: Even after 2 years, I continue to find this question incredibly challenging. I have cleaned up the code and provided additional explanations. 

The key aspect to understanding the solution is to build up the tabele and run the CTEs cumulatively (run CTE 1 first, then run CTE 1 & 2, and so on). This approach allows for a better understanding of why specific columns were created or how the information in the tables progressed. 

```sql
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
```

**Answer:**

Showing results for customers ID 1, 2 and 3 only:
|customer_id|ending_month|total_monthly_change|ending_balance|
|:----|:----|:----|:----|
|1|2020-01-31T00:00:00.000Z|312|312|
|1|2020-02-29T00:00:00.000Z|0|312|
|1|2020-03-31T00:00:00.000Z|-952|-964|
|1|2020-04-30T00:00:00.000Z|0|-640|
|2|2020-01-31T00:00:00.000Z|549|549|
|2|2020-02-29T00:00:00.000Z|0|549|
|2|2020-03-31T00:00:00.000Z|61|610|
|2|2020-04-30T00:00:00.000Z|0|610|
|3|2020-01-31T00:00:00.000Z|144|144|
|3|2020-02-29T00:00:00.000Z|-965|-821|
|3|2020-03-31T00:00:00.000Z|-401|-1222|
|3|2020-04-30T00:00:00.000Z|493|-729|

***

**5. Comparing the closing balance of a customer’s first month and the closing balance from their second nth, what percentage of customers:**

For this question, I have created 2 temporary tables to solve the questions below:
- Create temp table #1 `customer_monthly_balances` by copying and pasting the code from the solution to Question 4. 
- Use temp table #1 `ranked_monthly_balances` to create temp table #2 by applying the `ROW_NUMBER()` function. 

```sql

```

**- What percentage of customers have a negative first month balance? What percentage of customers have a positive first month balance?**

To address both questions, I'm using one solution since the questions are asking opposite spectrums of each other.  

````sql

````

**Answer:**

|negative_first_month_percentage|positive_first_month_percentage|
|:----|:----|
|44.8|55.2|

**- What percentage of customers increase their opening month’s positive closing balance by more than 5% in the following month?**

I'm using `LEAD()` window function to query the balances for the following month and then, filtering the results to select only the records with balances for the 1st and 2nd month. 

Important assumptions:
- Negative balances in the `following_balance` field have been excluded from the results. This is because a higher negative balance in the following month does not represent a true increase in balances. 
- Including negative balances could lead to a misrepresentation of the answer as the percentage of variance would still appear as a positive percentage. 

````sql

````

**Answer:**

|increase_5_percentage|
|:----|
|20.0|

- Among the customers, 20% experience a growth of more than 5% in their positive closing balance from the opening month to the following month.

**- What percentage of customers reduce their opening month’s positive closing balance by more than 5% in the following month?**

````sql

````

**Answer:**

|reduce_5_percentage|
|:----|
|25.6|

- Among the customers, 25.6% experience a drop of more than 5% in their positive closing balance from the opening month to the following month.

**- What percentage of customers move from a positive balance in the first month to a negative balance in the second month?**

````sql

````

**Answer:**

|positive_to_negative_percentage|
|:----|
|20.2|

- Among the customers, 20.2% transitioned from having a positive balance (`ending_balance`) in the first month to having a negative balance (`following_balance`) in the following month.

***

Do give me a 🌟 if you like what you're reading. Thank you! 🙆🏻‍♀️
