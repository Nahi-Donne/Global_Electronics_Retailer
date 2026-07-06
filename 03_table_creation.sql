-- products dimension table

CREATE TABLE dim_product AS
SELECT DISTINCT
  product_key,
  product_name,
  brand,
  color,
  unit_cost_usd,
  unit_price_usd,
  subcategory_key,
  subcategory,
  category_key,
  category
FROM products_stage;

-- customers dimension table

CREATE TABLE dim_customer AS
SELECT DISTINCT
  customer_key,
  gender,
  full_name,
  city,
  state,
  country,
  continent,
  birthday
FROM customers_stage;

-- stores dimension table

CREATE TABLE dim_store AS
SELECT DISTINCT
  store_key,
  country,
  state,
  square_meters,
  open_date
FROM stores_stage;

-- date dimension table
CREATE TABLE dim_date AS
SELECT DISTINCT
  order_date AS date,
  EXTRACT(MONTH FROM order_date) AS month,
  EXTRACT(YEAR FROM order_date) AS year,
  EXTRACT(DAY from order_date) AS day
FROM sales_stage;

-- exchange rate dimension table

CREATE TABLE dim_currency AS
SELECT DISTINCT
  currency,
  exchange,
  date
FROM exchange_rates_stage;

-- sales fact table

CREATE TABLE fact_sales AS
SELECT
  s.order_number,
  s.line_item,
  s.order_date,
  s.delivery_date,

  -- keys (dimensions)
  s.customer_key,
  s.product_key,
  s.store_key,
  s.currency_code,

  -- measures
  s.quantity,
  p.unit_price_usd,

  -- base revenue
  s.quantity * p.unit_price_usd AS revenue_native
FROM sales_stage AS s 
JOIN products_stage AS p ON p.product_key = s.product_key;