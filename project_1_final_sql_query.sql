--necessary extensions and supplementary tables

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE states (
state_name TEXT PRIMARY KEY
);

INSERT INTO states (state_name) VALUES -- All correct spelling of states
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

-- convert all columns to lower snake case
ALTER TABLE shopping_behavior_data
RENAME COLUMN "customer id" TO customer_id;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Age" TO age;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Gender" TO gender;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "ItemPurchased" TO item_purchased;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Category" TO category;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Purchase_Amount_USD" TO purchase_amount_USD;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Location" TO location;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Size" TO size;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Color" TO color;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Season" TO season;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Review Rating" TO review_rating;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Subscription Status" TO subscription_status;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Shipping Type" TO shipping_type;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Discount Applied" TO discount_applied;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Promo Code Used" TO promo_code_used;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Previous Purchases" TO previous_purchases;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Payment Method" TO payment_method;

ALTER TABLE shopping_behavior_data
RENAME COLUMN "Frequency of Purchases" TO frequency_of_purchases;


-- final cleaned data
CREATE TABLE shopping_behavior_clean AS 
WITH cleaned_shopping_behavior_data AS (

	SELECT
		s.customer_id,
		s.cleaned_age AS age,
		s.cleaned_gender AS gender,
		s.cleaned_category AS category,
		s.cleaned_purchase_amount_usd AS purchase_amount_usd,
		s.clean_location AS location,
		s.cleaned_review_rating AS review_rating,
		s.cleaned_subscription_status AS subscription_status,
		s.cleaned_discount_applied AS discount_applied,
		s.cleaned_promo_code_used AS promo_code_used,
		s.cleaned_previous_purchases AS previous_purchases,
		s.cleaned_payment_method AS payment_method,
		s.cleaned_purchase_frequency AS purchase_frequency,
		CASE
			WHEN s.cleaned_age = 0 THEN 'Unknown'
			WHEN s.cleaned_age BETWEEN 18 AND 25 THEN '18-25' -- young adults, gen z
			WHEN s.cleaned_age BETWEEN 26 AND 35 THEN '26-35' -- young professionals, more spending power
			WHEN s.cleaned_age BETWEEN 36 AND 50 THEN '36-45' -- family oriented
			WHEN s.cleaned_age BETWEEN 46 AND 54 THEN '46-54' -- higher income individuals, less leisure spending
			ELSE '55+'                                        -- seniors, stable but minimal leisure spending
			END AS age_group,
		CASE 
            WHEN s.cleaned_subscription_status = 'Yes' THEN 1 ELSE 0 
            END AS subscriber_indicator,
		CASE 
            WHEN s.cleaned_promo_code_used = 'Yes' THEN 1 ELSE 0 
            END AS promo_indicator,
		CASE 
            WHEN s.cleaned_discount_applied = 'Yes' THEN 1 ELSE 0 
            END AS discount_indicator

	FROM (
		SELECT
			customer_id,
			
			-- cleaned age
			CASE
			    WHEN s_raw.clean_age IS NULL THEN 0
				WHEN LOWER(TRIM(s_raw.clean_age::text)) IN ('nan', 'unknown') THEN 0
				WHEN LENGTH(TRIM(s_raw.clean_age::text)) > 2 THEN 0
				ELSE TRIM(s_raw.clean_age::text)::numeric
				END AS cleaned_age,
				
			-- cleaned_gender
			CASE  -- transform all spelling and capitalization errors using case when statements
		        WHEN LOWER(gender) LIKE 'm%' THEN 'Male'
				WHEN LOWER(gender) LIKE 'f%' THEN 'Female'
				WHEN LOWER(gender) LIKE '%emale' THEN 'Female'
				WHEN LOWER(gender) LIKE '_ale%' THEN 'Male'
				ELSE LOWER(gender) END AS cleaned_gender,
	
			-- cleaned_category
	        CASE     
				WHEN LOWER(category) LIKE 'ac%' THEN 'Accessories' 
				WHEN LOWER(category) LIKE '%sories' THEN 'Accessories'
				WHEN LOWER(category) LIKE 'clo%' THEN 'Clothing'
				WHEN LOWER(category) LIKE '%thing' THEN 'Clothing'
				WHEN LOWER(category) LIKE 'foo%' THEN 'Footwear'
				WHEN LOWER(category) LIKE '____wear%' THEN 'Footwear'
				WHEN LOWER(category) LIKE 'ou%' THEN 'Outerwear'
				WHEN LOWER(category) LIKE '_____wear' THEN 'Outerwear'
				ELSE LOWER(category) END as cleaned_category,
	
			-- cleaned_purchase_amount_usd
			CASE
				WHEN purchase_amount_usd IS NULL then 0      
				WHEN LOWER(purchase_amount_usd) = 'nan' then 0
				ELSE ROUND(ABS(purchase_amount_usd::numeric)) 
				END AS cleaned_purchase_amount_usd,
	
			-- cleaned_location
			CASE 
				WHEN LOWER(cleaned_location) IS NULL THEN NULL
				WHEN LOWER(cleaned_location) = 'unknown' THEN NULL
				ELSE cleaned_location
				END AS clean_location,
	
			-- cleaned_review_rating
			CASE
				WHEN review_rating IS NULL then NULL  -- transform null and nan values to null
				WHEN LOWER(review_rating) = 'nan' then NULL
				ELSE review_rating::numeric(10,1) -- transform all values to decimals/floats
				END AS cleaned_review_rating,
	
			-- cleaned_subscription_status
			CASE  -- transform spelling and capitalization errors to consistent format
				WHEN LOWER(subscription_status) LIKE 'n%' THEN 'No'
				WHEN LOWER(subscription_status) LIKE '_o%' THEN 'No'
				WHEN LOWER(subscription_status) LIKE 'y%' THEN 'Yes'
				WHEN LOWER(subscription_status) LIKE '_es%' THEN 'Yes'
				ELSE subscription_status
				END AS cleaned_subscription_status,
	
			-- cleaned_discount_applied
			CASE -- -- transform spelling and capitalization errors to consistent format
				WHEN LOWER(discount_applied) LIKE 'n_%' THEN 'No'
				WHEN LOWER(discount_applied) LIKE '_o%' THEN 'No'
				WHEN LOWER(discount_applied) LIKE 'y__%' THEN 'Yes'
				WHEN LOWER(discount_applied) LIKE '_es%' THEN 'Yes'
				ELSE discount_applied
				END AS cleaned_discount_applied,
	
			-- cleaned_promo_code_used
			CASE
				WHEN LOWER(promo_code_used) LIKE 'n_%' THEN 'No'
				WHEN LOWER(promo_code_used) LIKE '_o%' THEN 'No'
				WHEN LOWER(promo_code_used) LIKE 'y__%' THEN 'Yes'
				WHEN LOWER(promo_code_used) LIKE '_es%' THEN 'Yes'
				WHEN promo_code_used IS NULL THEN 'No' -- transform null values to 'no' because null
													   -- values indicate that a promo code was not entered
				ELSE promo_code_used
				END AS cleaned_promo_code_used,
	
			-- cleaned_previous_purchases
			CASE -- transform null and nan values all to NULL values
				WHEN previous_purchases IS NULL THEN NULL
				WHEN previous_purchases = 'nan' THEN NULL
				ELSE ROUND(previous_purchases::numeric) -- remove decimals by rounding
				END AS cleaned_previous_purchases,
	
			-- cleaned_payment_method
			CASE 
				WHEN LOWER(payment_method) LIKE 'debit%' THEN 'Debit Card'
				WHEN LOWER(payment_method) LIKE '_____ card%' THEN 'Debit Card'
				WHEN LOWER(payment_method) LIKE 'credit%' THEN 'Credit Card'
				WHEN LOWER(payment_method) LIKE '______ card%' THEN 'Credit Card'
				WHEN LOWER(payment_method) LIKE 'ven%' THEN 'Venmo'
				WHEN LOWER(payment_method) LIKE '%mo' THEN 'Venmo'
				WHEN LOWER(payment_method) LIKE 'pay%' THEN 'Paypal'
			    WHEN LOWER(payment_method) LIKE '%pal' THEN 'Paypal'
				WHEN LOWER(payment_method) LIKE '%ash' THEN 'Debit Card'
				WHEN LOWER(payment_method) LIKE 'bank%' THEN 'Bank Transfer'
				WHEN LOWER(payment_method) LIKE '%transfer' THEN 'Bank Transfer'
				WHEN LOWER(payment_method) LIKE '____' THEN 'Cash'
				ELSE LOWER(payment_method)
				END AS cleaned_payment_method,
	
			-- cleaned_frequency_of_purchases
			 CASE
				WHEN LOWER(frequency_of_purchases) LIKE 'fort%' OR LOWER(frequency_of_purchases) LIKE '%igh%' THEN 'Fortnightly'
				WHEN LOWER(frequency_of_purchases) LIKE '%-%' THEN 'Bi-Weekly'
				WHEN LOWER(frequency_of_purchases) LIKE '_______' THEN 'Monthly'
				WHEN LOWER(frequency_of_purchases) LIKE '______' THEN 'Weekly'
				WHEN LOWER(frequency_of_purchases) LIKE '________' THEN 'Annually'
				WHEN LOWER(frequency_of_purchases) LIKE '_________' THEN 'Quarterly'
				WHEN LOWER(frequency_of_purchases) LIKE '%3%' OR LOWER(frequency_of_purchases) LIKE 'every%' THEN 'Every 3 Months'
				ELSE LOWER(frequency_of_purchases)
				END AS cleaned_purchase_frequency

		FROM (
			SELECT 
					sbd.*,
					ROUND(sbd.age::numeric) AS clean_age,
					CASE
			        	WHEN similarity(LOWER(sbd.location), LOWER(ds.state_name)) >= 0.40 THEN ds.state_name
			        	ELSE 'Unknown'
			     		END AS cleaned_location
			FROM shopping_behavior_data AS sbd
			CROSS JOIN LATERAL (                  --- Replace state names with proper spelling and capitalization 
				SELECT state_name
				FROM states
				ORDER BY similarity(LOWER(sbd.location), LOWER(state_name)) DESC
				LIMIT 1
			) AS ds
		) AS s_raw
	) AS s
)

SELECT *
FROM cleaned_shopping_behavior_data
WHERE 
	customer_id IS NOT NULL AND  -- Filter out null values that only affect our northstar metric
				                 -- values. Keep nulls for segmenting columns to keep main 
								 -- analysis robust.
	purchase_amount_usd > 0 AND
	subscription_status IS NOT NULL AND
	discount_applied IS NOT NULL AND 
	previous_purchases IS NOT NULL;


