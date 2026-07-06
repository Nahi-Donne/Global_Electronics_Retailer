/*
==================================================
Customer Analysis Views
Project: Sales Performance Dashboard

Description:
Contains views used to analyze:
- Customer Churn
- Profit by Customer Category
==================================================
*/

-- Churn evolving year over year analysis.

CREATE OR REPLACE VIEW analytics.customer_churn AS
  WITH customer_appearance AS(
    SELECT
      DISTINCT customer_key,
      EXTRACT(YEAR FROM order_date)::INT AS active_year
    FROM fact_sales
),
  customer_activity AS(
    SELECT
      active_year,
      customer_key,
      MIN(active_year) OVER (PARTITION BY customer_key ORDER BY active_year) AS first_year,
      LAG(active_year) OVER (PARTITION BY customer_key ORDER BY active_year) AS prev_year,
      LEAD(active_year) OVER (PARTITION BY customer_key ORDER BY active_year) AS next_year,
      MAX(active_year) OVER () AS max_year_dataset
    FROM customer_appearance
),
  customer_summary AS(
    SELECT
      active_year AS year,
      max_year_dataset,
      COUNT(DISTINCT customer_key) AS total_customers,
      COUNT(CASE WHEN first_year = active_year THEN customer_key END) AS new_customers,
      COUNT(CASE WHEN prev_year = active_year - 1 THEN customer_key END) AS retained_customers,
      COUNT(CASE WHEN active_year < max_year_dataset AND
      (next_year IS NULL OR next_year > active_year + 1) THEN customer_key END) AS churned_customers
    FROM customer_activity
    GROUP BY active_year, max_year_dataset
  )

SELECT
  year,
  total_customers,
  new_customers,
  retained_customers,
  churned_customers,
  CASE
    WHEN year = max_year_dataset THEN 0
  ELSE ROUND((churned_customers * 100.0 / NULLIF(total_customers, 0))::NUMERIC, 2) END AS churn_rate_pct
FROM customer_summary
ORDER BY year;

-- How profitable are customers in each age group? and Which age groups contribute the most profit to the business?

CREATE OR REPLACE VIEW analytics.customer_age AS
WITH customer_profits AS(
  SELECT
    f.customer_key,
    f.order_number,
    f.order_date,
    EXTRACT(YEAR FROM AGE(f.order_date, c.birthday))::INT AS age,
    SUM(f.revenue_native * ex.exchange) - SUM(f.quantity * p.unit_cost_usd) AS profit
  FROM fact_sales AS f
  JOIN dim_product AS p USING(product_key)
  JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
  JOIN dim_customer AS c USING(customer_key)
  GROUP BY f.customer_key, f.order_number, f.order_date, c.birthday
),

customer_metrics AS(
  SELECT
    customer_key,
    age,
    COUNT(*) AS total_orders,
    AVG(profit) AS avg_profit_order,
    SUM(profit) AS lifetime_profit
  FROM customer_profits
  GROUP BY customer_key, age
),
customer_age_partition AS(
  SELECT
    CASE
      WHEN age BETWEEN 3 AND 19 THEN '03 - 19'
      WHEN age BETWEEN 20 AND 35 THEN '20 - 35'
      WHEN age BETWEEN 36 AND 45 THEN '36 - 45'
      WHEN age BETWEEN 46 AND 55 THEN '46 - 55'
      WHEN age BETWEEN 56 AND 65 THEN '56 - 65'
      WHEN age BETWEEN 66 AND 75 THEN '66 - 75'
      WHEN age BETWEEN 76 AND 85 THEN '76 - 85'
      WHEN age BETWEEN 86 AND 95 THEN '86 - 95'
      ELSE '96+'
    END AS age_group,
    COUNT(DISTINCT customer_key) AS total_customers,
    ROUND(AVG(total_orders)::NUMERIC, 2) AS avg_total_orders,
    ROUND(AVG(avg_profit_order)::NUMERIC, 2) AS avg_profit_order,
    ROUND(AVG(lifetime_profit)::NUMERIC, 2) AS avg_lifetime_profit,
    ROUND(SUM(lifetime_profit)::NUMERIC, 2) AS total_profit
  FROM customer_metrics
  GROUP BY age_group
)

SELECT *,
  ROUND((total_profit * 100.0 / SUM(total_profit) OVER ())::NUMERIC, 2) AS profit_share_pct
FROM customer_age_partition
ORDER BY age_group;

-- Which customer/product/region segments are most profitable, and how has that ranking shifted over time?
-- Most profitable customer segment over time

CREATE OR REPLACE VIEW  analytics.customer_segments AS
  WITH customer_revenue AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      f.customer_key,
      COUNT(f.order_number) AS customer_order,
      SUM(revenue_native * exchange) - SUM(quantity * unit_cost_usd) AS profit
    FROM fact_sales AS f
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    JOIN dim_product AS p USING(product_key)
    GROUP BY customer_key, year
),
  customer_partition AS(
    SELECT
      year,
      customer_key,
      customer_order,
      profit,
      NTILE(10) OVER (PARTITION BY year ORDER BY customer_order) AS decile
    FROM customer_revenue
),
  customer_segment AS(
    SELECT
      year,
      CASE
        WHEN decile BETWEEN 1 AND 4 THEN 'Low Value'
        WHEN decile BETWEEN 5 AND 7 THEN 'Medium Value'
        WHEN decile BETWEEN 8 AND 9 THEN 'High Value'
      ELSE 'VIP' END AS segment,
      COUNT(*) AS total_customer_segment,
      SUM(customer_order) AS total_order,
      AVG(customer_order) AS avg_order,
      SUM(profit) AS total_profit,
      AVG(profit) AS avg_profit
    FROM customer_partition
    GROUP BY year, segment
)
SELECT
  *,
  DENSE_RANK() OVER (PARTITION BY YEAR ORDER BY avg_order DESC) AS rank_segment
FROM customer_segment
ORDER BY year;

  
