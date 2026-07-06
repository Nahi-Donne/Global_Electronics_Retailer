/*
==================================================
Profit Analysis Views
Project: Sales Performance Dashboard

Description:
Contains views used to analyze:
- Profit trends
- YoY Profit growth
- Profit by Category
- Profit by Country
==================================================
*/

-- Yearly Total Profit

CREATE OR REPLACE VIEW analytics.yearly_profit AS
  WITH yearly_profit_product AS(
    SELECT
      EXTRACT(YEAR FROM order_date)::INT AS year,
      SUM(f.revenue_native * ex.exchange) - SUM(f.quantity * p.unit_cost_usd) AS profit
    FROM fact_sales AS f
    JOIN dim_product AS p ON p.product_key = f.product_key
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP by year
),
  profit_trends_product AS(
    SELECT
      *,
      LAG(profit) OVER (ORDER BY  year) AS prev_year_profit
    FROM yearly_profit_product
)

SELECT
  year,
  ROUND(profit::NUMERIC, 2) AS profit,
  ROUND(prev_year_profit::NUMERIC, 2) AS prev_year_profit,
  ROUND((((profit - prev_year_profit) /
    NULLIF(prev_year_profit, 0)) * 100)::NUMERIC, 2) AS yoy_profit_growth_rate
FROM profit_trends_product
ORDER BY year;

-- Most profitable product segment over time

CREATE OR REPLACE VIEW analytics.product_segments AS
  WITH yearly_profit_product AS(
    SELECT
      p.category,
      EXTRACT(YEAR FROM order_date)::INT AS year,
      SUM(f.revenue_native * ex.exchange) - SUM(f.quantity * p.unit_cost_usd) AS profit
    FROM fact_sales AS f
    JOIN dim_product AS p ON p.product_key = f.product_key
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP by year, p.category
),
  rank_profit_product AS(
    SELECT
      *,
      DENSE_RANK() OVER(PARTITION BY year ORDER BY profit DESC) AS yearly_rank
    FROM yearly_profit_product
),
  profit_trends_product AS(
    SELECT
      *,
      LAG(profit) OVER(PARTITION BY category ORDER BY  year) AS prev_year_profit,
      LAG(yearly_rank) OVER(PARTITION BY category ORDER BY year) AS prev_year_rank
    FROM rank_profit_product
)

SELECT
  year,
  category,
  ROUND(profit::NUMERIC, 2) AS profit,
  ROUND((profit * 100.0 / SUM(profit) OVER (PARTITION BY year))::NUMERIC, 2) AS profit_share_pct,
  ROUND(prev_year_profit::NUMERIC, 2) AS prev_year_profit,
  ROUND((((profit - prev_year_profit) /
    NULLIF(prev_year_profit, 0)) * 100)::NUMERIC, 2) AS yoy_profit_growth_rate,
  yearly_rank,
  prev_year_rank,
  prev_year_rank - yearly_rank as rank_change
FROM profit_trends_product
ORDER BY year, yearly_rank;

-- Most profitable region segments over time

CREATE OR REPLACE VIEW analytics.region_segments AS
  WITH yearly_profit_region AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      country,
      SUM(f.revenue_native * ex.exchange) - SUM(f.quantity * p.unit_cost_usd) AS profit
    FROM fact_sales AS f JOIN dim_customer AS c USING(customer_key)
    JOIN dim_product AS p USING(product_key)
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP BY EXTRACT(YEAR FROM f.order_date), country 
),
  profit_rank_region AS(
  SELECT
    *,
    DENSE_RANK() OVER(PARTITION BY year ORDER BY profit DESC) AS yearly_rank
  FROM yearly_profit_region
),
  profit_trends_region AS(
    SELECT
      *,
    LAG(profit) OVER (PARTITION BY country ORDER BY year) AS prev_year_profit,
    LAG(yearly_rank) OVER (PARTITION BY country ORDER by year) AS prev_year_rank
  FROM profit_rank_region 
) 

SELECT
  year,
  country,
  ROUND(profit::NUMERIC, 2) AS profit,
  ROUND((profit * 100.0 / SUM(profit) OVER (PARTITION BY year))::NUMERIC, 2) AS profit_share,
  ROUND(prev_year_profit::NUMERIC, 2) AS prev_year_profit,
  ROUND(( ((profit - prev_year_profit) / 
    NULLIF(prev_year_profit, 0)) * 100)::NUMERIC, 2) AS yoy_profit_growth_pct,
  yearly_rank, prev_year_rank, prev_year_rank - yearly_rank AS rank_change
FROM profit_trends_region 
ORDER BY year, yearly_rank;
