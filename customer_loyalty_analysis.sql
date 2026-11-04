-- =======================
-- 01. CLEANING 
-- =======================
-- 


-- 1. CREATE STATES TABLE TO REPLACE ALL STATES NAMES

DROP TABLE IF EXISTS modeling.states;
CREATE TABLE modeling.states (
state_name TEXT PRIMARY KEY
);

INSERT INTO states (state_name) VALUES
('Alabama'), ('Alaska'), ('Arizona'), ('Arkansas'), ('California'),
('Colorado'), ('Connecticut'), ('Delaware'), ('Florida'), ('Georgia'),
('Hawaii'), ('Idaho'), ('Illinois'), ('Indiana'), ('Iowa'),
('Kansas'), ('Kentucky'), ('Louisiana'), ('Maine'), ('Maryland'),
('Massachusetts'), ('Michigan'), ('Minnesota'), ('Mississippi'), ('Missouri'),
('Montana'), ('Nebraska'), ('Nevada'), ('New Hampshire'), ('New Jersey'),
('New Mexico'), ('New York'), ('North Carolina'), ('North Dakota'),
('Ohio'), ('Oklahoma'), ('Oregon'), ('Pennsylvania'), ('Rhode Island'),
('South Carolina'), ('South Dakota'), ('Tennessee'), ('Texas'), ('Utah'),
('Vermont'), ('Virginia'), ('Washington'), ('West Virginia'),
('Wisconsin'), ('Wyoming');


CREATE SCHEMA IF NOT EXISTS cleaning;
DROP TABLE IF EXISTS modeling.cleaned_shopping_behavior_data;

CREATE TABLE modeling.cleaned_shopping_behavior_data AS
WITH raw AS (
	SELECT
		sbd.*,
		ROUND(sbd.age::numeric) AS clean_age,
		CASE
			WHEN similarity(LOWER(sbd.location), LOWER(ds.state_name)) >= 0.40 THEN ds.state_name
			ELSE 'Unknown'
		END AS cleaned_location
	FROM cleaning.shopping_behavior_data AS sbd
	CROSS JOIN LATERAL (
		SELECT state_name FROM modeling.states
		ORDER BY similarity(LOWER(sbd.location), LOWER(state_name)) DESC
		LIMIT 1
	) AS ds
)
SELECT
	customer_id::numeric::integer AS customer_id,
	CASE
		WHEN clean_age IS NULL THEN 0
		WHEN LOWER(TRIM(clean_age::text)) IN ('nan','unknown') THEN 0
		WHEN LENGTH(TRIM(clean_age::text)) > 2 THEN 0
		ELSE TRIM(clean_age::text)::numeric
	END AS age,
	CASE
		WHEN LOWER(gender) LIKE 'm%' THEN 'Male'
		WHEN LOWER(gender) LIKE 'f%' THEN 'Female'
		WHEN LOWER(gender) LIKE '%emale' THEN 'Female'
		WHEN LOWER(gender) LIKE '_ale%' THEN 'Male'
		ELSE LOWER(gender)
	END AS gender,
	item_purchased,
	CASE
		WHEN LOWER(category) LIKE 'ac%' THEN 'Accessories'
		WHEN LOWER(category) LIKE '%sories' THEN 'Accessories'
		WHEN LOWER(category) LIKE 'clo%' THEN 'Clothing'
		WHEN LOWER(category) LIKE '%thing' THEN 'Clothing'
		WHEN LOWER(category) LIKE 'foo%' THEN 'Footwear'
		WHEN LOWER(category) LIKE '____wear%' THEN 'Footwear'
		WHEN LOWER(category) LIKE 'ou%' THEN 'Outerwear'
		WHEN LOWER(category) LIKE '_____wear' THEN 'Outerwear'
		ELSE LOWER(category)
	END AS category,
	CASE
		WHEN purchase_amount_usd IS NULL THEN 0
		WHEN LOWER(purchase_amount_usd) = 'nan' THEN 0
		ELSE ROUND(ABS(purchase_amount_usd::numeric))
	END AS purchase_amount_usd,
	CASE WHEN cleaned_location = 'Unknown' THEN NULL ELSE cleaned_location END AS location,
	size, color, season, shipping_type,
	CASE
		WHEN review_rating IS NULL THEN NULL
		WHEN LOWER(review_rating) = 'nan' THEN NULL
		ELSE review_rating::numeric(10,1)
	END AS review_rating,
	CASE
		WHEN LOWER(subscription_status) LIKE 'n%'   THEN 'No'
		WHEN LOWER(subscription_status) LIKE '_o%'  THEN 'No'
		WHEN LOWER(subscription_status) LIKE 'y%'   THEN 'Yes'
		WHEN LOWER(subscription_status) LIKE '_es%' THEN 'Yes'
		ELSE subscription_status
	END AS subscription_status,
	CASE
		WHEN LOWER(discount_applied) LIKE 'n_%'  THEN 'No'
		WHEN LOWER(discount_applied) LIKE '_o%'  THEN 'No'
		WHEN LOWER(discount_applied) LIKE 'y__%' THEN 'Yes'
		WHEN LOWER(discount_applied) LIKE '_es%' THEN 'Yes'
		ELSE discount_applied
	END AS discount_applied,
	CASE
		WHEN LOWER(promo_code_used) LIKE 'n_%'  THEN 'No'
		WHEN LOWER(promo_code_used) LIKE '_o%'  THEN 'No'
		WHEN LOWER(promo_code_used) LIKE 'y__%' THEN 'Yes'
		WHEN LOWER(promo_code_used) LIKE '_es%' THEN 'Yes'
		WHEN promo_code_used IS NULL THEN 'No'
		ELSE promo_code_used
	END AS promo_code_used,
	CASE
		WHEN previous_purchases IS NULL THEN NULL
		WHEN previous_purchases = 'nan' THEN NULL
		ELSE ROUND(previous_purchases::numeric)
	END AS previous_purchases,
	CASE
		WHEN LOWER(payment_method) LIKE 'debit%'       THEN 'Debit Card'
		WHEN LOWER(payment_method) LIKE '_____ card%'  THEN 'Debit Card'
		WHEN LOWER(payment_method) LIKE 'credit%'      THEN 'Credit Card'
		WHEN LOWER(payment_method) LIKE '______ card%' THEN 'Credit Card'
		WHEN LOWER(payment_method) LIKE 'ven%'         THEN 'Venmo'
		WHEN LOWER(payment_method) LIKE '%mo'          THEN 'Venmo'
		WHEN LOWER(payment_method) LIKE 'pay%'         THEN 'Paypal'
		WHEN LOWER(payment_method) LIKE '%pal'         THEN 'Paypal'
		WHEN LOWER(payment_method) LIKE '%ash'         THEN 'Debit Card'
		WHEN LOWER(payment_method) LIKE 'bank%'        THEN 'Bank Transfer'
		WHEN LOWER(payment_method) LIKE '%transfer'    THEN 'Bank Transfer'
		WHEN LOWER(payment_method) LIKE '____'         THEN 'Cash'
		ELSE LOWER(payment_method)
	END AS payment_method,
	CASE
		WHEN LOWER(frequency_of_purchases) LIKE 'fort%' OR LOWER(frequency_of_purchases) LIKE '%igh%' THEN 'Fortnightly'
		WHEN LOWER(frequency_of_purchases) LIKE '%-%'       THEN 'Bi-Weekly'
		WHEN LOWER(frequency_of_purchases) LIKE '_______'   THEN 'Monthly'
		WHEN LOWER(frequency_of_purchases) LIKE '______'    THEN 'Weekly'
		WHEN LOWER(frequency_of_purchases) LIKE '________'  THEN 'Annually'
		WHEN LOWER(frequency_of_purchases) LIKE '_________' THEN 'Quarterly'
		WHEN LOWER(frequency_of_purchases) LIKE '%3%' OR LOWER(frequency_of_purchases) LIKE 'every%' THEN 'Every 3 Months'
		ELSE LOWER(frequency_of_purchases)
	END AS purchase_frequency
FROM raw;

SELECT *
FROM modeling.cleaned_shopping_behavior_data

-- ===================
-- 02. MODELING 
-- ===================

DROP TABLE IF EXISTS modeling.shopping_behavior_final;

CREATE TABLE modeling.shopping_behavior_final AS
SELECT
	customer_id,
	CASE 
		WHEN age = 0 THEN NULL
		ELSE age
	END AS age,
	gender,
	category,
	purchase_amount_usd,
	location,
	review_rating,
	subscription_status,
	discount_applied,
	promo_code_used,
	previous_purchases,
	payment_method,
	purchase_frequency,
	CASE
		WHEN age = 0 THEN 'Unknown'
		WHEN age BETWEEN 18 AND 25 THEN '18-25' -- young adults, gen z
		WHEN age BETWEEN 26 AND 35 THEN '26-35' -- young professionals, more spending power
		WHEN age BETWEEN 36 AND 45 THEN '36-45' -- family oriented
		WHEN age BETWEEN 46 AND 54 THEN '46-54' -- higher income individuals, less leisure spending
		ELSE '55+'                              -- seniors, stable but minimal leisure spending
	END AS age_group,
	CASE WHEN subscription_status = 'Yes' THEN 1 ELSE 0 END AS subscriber_indicator,
	CASE WHEN promo_code_used     = 'Yes' THEN 1 ELSE 0 END AS promo_indicator,
	CASE WHEN discount_applied    = 'Yes' THEN 1 ELSE 0 END AS discount_indicator
FROM modeling.cleaned_shopping_behavior_data
WHERE customer_id IS NOT NULL
  AND purchase_amount_usd > 0
  AND subscription_status IS NOT NULL
  AND discount_applied IS NOT NULL
  AND previous_purchases IS NOT NULL
  AND purchase_amount_usd < 1000;  -- found outliers valued at either $5000 or $9999

 SELECT *
 FROM modeling.shopping_behavior_final

-- ============================
-- 03. ANALYSIS
-- ============================
SELECT purchase_amount_usd, COUNT(*)
FROM modeling.shopping_behavior_final
WHERE purchase_amount_usd > 150 
GROUP BY purchase_amount_usd ORDER BY purchase_amount_usd;


-- analyzing distribution of purchase frequency between subscribers and non subscribers
WITH purchase_freq_sub AS (
SELECT purchase_frequency, COUNT(*) as count_sub
FROM modeling.shopping_behavior_final
WHERE subscription_status = 'Yes' AND purchase_frequency IS NOT NULL
GROUP BY purchase_frequency
),

purchase_freq_nonsub AS (
SELECT purchase_frequency, COUNT(*) AS count_nonsub
FROM modeling.shopping_behavior_final
WHERE subscription_status = 'No' AND purchase_frequency IS NOT NULL
GROUP BY purchase_frequency
)

SELECT s.purchase_frequency, 
	   count_sub, 
	   count_nonsub, 
	   ROUND(count_sub::numeric / SUM(count_sub::numeric) OVER() * 100, 1) AS pct_sub,
	   ROUND(count_nonsub::numeric / SUM(count_nonsub::numeric) OVER() * 100, 1) AS pct_nonsub,
	   (((ROUND(count_sub::numeric / SUM(count_sub::numeric) OVER() * 100, 1)) - 
	   		(ROUND(count_nonsub::numeric / SUM(count_nonsub::numeric) OVER() * 100, 1))) / 
	   		(ROUND(count_nonsub::numeric / SUM(count_nonsub::numeric) OVER() * 100, 1))) * 100 AS pct_change
FROM purchase_freq_sub AS s
LEFT JOIN purchase_freq_nonsub AS ns
ON s.purchase_frequency = ns.purchase_frequency

-- 2995 UNIQUE CUSTOMERS
SELECT COUNT(*)
FROM(
SELECT customer_id
FROM modeling.shopping_behavior_final
GROUP BY customer_id)

--3147 unique rows
SELECT *
FROM modeling.shopping_behavior_final

-- product cateogry distribution

SELECT category, count,
	   count / SUM(count) OVER() * 100 AS share
FROM(
SELECT category, count(*) AS count
FROM modeling.shopping_behavior_final
GROUP BY category )

--product category distribtuion by sub status
SELECT category, count(*) AS count,
	   count(*) / SUM(count(*)) over() * 100 AS share
FROM modeling.shopping_behavior_final
WHERE subscription_status = 'Yes'
GROUP BY category


