-- Clean All Tables

-- 1. Customers Table
CREATE MATERIALIZED VIEW customers_stage AS 
SELECT
    customer_key::int,
    NULLIF(TRIM(REGEXP_REPLACE(full_name,'\s+',' ','g')), '')::varchar AS full_name,

    CASE
      WHEN LOWER(gender) IN ('m','male') THEN 'Male'
      WHEN LOWER(gender) IN ('f','female') THEN 'Female'
      ELSE NULL
    END::varchar AS gender,
    INITCAP(LOWER(NULLIF(TRIM(city),'')))::varchar AS city,
    state_code::varchar,    
    NULLIF(TRIM(REGEXP_REPLACE(state, '\s+', ' ', 'g')), '')::varchar AS state,    
    zip_code::varchar,
    UPPER(NULLIF(TRIM(country),''))::varchar AS country,    
    NULLIF(TRIM(REGEXP_REPLACE(continent, '\s+', ' ', 'g')), '')::varchar AS continent,
    birthday,    
    EXTRACT(YEAR FROM AGE(birthday))::int AS age /* create a new column to put age from birthday date column*/
FROM (
	SELECT
		customer_key,
        full_name,
        gender,
        city,
        state_code,
        state,
        zip_code,
        country,
        continent,
		NULLIF(NULLIF(TRIM(birthday), ''), 'N/A')::date AS birthday /* Fix data types*/
	FROM public.customers) AS table_customers
WHERE  birthday <= CURRENT_DATE;


-- 2. Products Table

CREATE MATERIALIZED VIEW products_stage AS
SELECT 
	product_key,	
	NULLIF(TRIM(regexp_replace(product_name,'\s+',' ','g')), '')::varchar AS product_name,	
	NULLIF(TRIM(regexp_replace(brand, '\s+', ' ', 'g')), '')::varchar AS brand,	
	NULLIF(TRIM(regexp_replace(color, '\s+',' ', 'g')), '')::varchar AS color,	
	unit_cost_usd::float AS unit_cost_usd,	
	unit_price_usd::float AS unit_price_usd,	
	subcategory_key,	
	NULLIF(TRIM(regexp_replace(subcategory, '\s+',' ', 'g')), '')::varchar AS subcategory,	
	category_key,	
	NULLIF(TRIM(regexp_replace(category, '\s+',' ','g')), '')::varchar AS category
FROM public.products;

-- 3. Sales Table
 
CREATE MATERIALIZED VIEW sales_stage AS
SELECT
	order_number,
	line_item,
	NULLIF(NULLIF(TRIM(order_date), ''), 'N/A')::date AS order_date,
	NULLIF(NULLIF(TRIM(delivery_date), ''), 'N/A')::date AS delivery_date,
	customer_key,
	store_key,
	product_key,
	quantity,
	UPPER(NULLIF(TRIM(regexp_replace(currency_code,'\s+', ' ', 'g')), ''))::varchar AS currency_code
FROM public.sales;


-- 4. Stores Table

CREATE MATERIALIZED VIEW stores_stage AS
SELECT 
	store_key,
	NULLIF(trim(regexp_replace(country, '\s+', ' ', 'g')), '') AS country,
	NULLIF(trim(regexp_replace(state,'\s+', ' ', 'g')), '') AS state,
	square_meters,
	NULLIF(NULLIF(TRIM(open_date), ''), 'N/A')::date AS open_date
FROM public.stores;

-- 5. Exchange Rates Table

CREATE MATERIALIZED VIEW exchange_rates_stage AS
SELECT
	NULLIF(NULLIF(TRIM(date), ''), 'N/A')::date AS date,
	NULLIF(trim(regexp_replace(currency, '\s+', ' ', 'g')), '') AS currency,
	exchange::NUMERIC
FROM public.exchange_rates;