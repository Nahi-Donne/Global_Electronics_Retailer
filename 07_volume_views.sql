/*
==================================================
Volume Analysis Views
Project: Sales Performance Dashboard

Description:
Contains views used to analyze:
- Volume trends
- YoY volume growth
- Seasonal volume patterns
==================================================
*/

-- Sales volume for each product category evolving year over year analysis.

CREATE OR REPLACE VIEW analytics.yearly_volume AS
  WITH volume_metrics AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      p.category,
      SUM(f.quantity) AS total_volume
    FROM fact_sales AS f
    JOIN dim_product AS p USING(product_key)
    GROUP BY year, p.category  
),
  prev_volume AS(
    SELECT
      year,
      category,
      total_volume,
      LAG(total_volume) OVER(PARTITION BY category ORDER BY year ASC) AS prev_year_volume
    FROM volume_metrics
)

SELECT
  year,
  category,
  ROUND(total_volume::NUMERIC, 2) AS total_volume,
  ROUND(((total_volume - prev_year_volume) * 100.0 / NULLIF(prev_year_volume, 0))::NUMERIC, 2) AS volume_growth_pct
FROM prev_volume
ORDER BY category, year;

-- Revenue and volume evolving each year

CREATE OR REPLACE VIEW analytics.yearly_volume_revenue AS
WITH volume_metrics AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      p.category,
      SUM(f.quantity) AS total_volume,
      SUM(f.revenue_native * ex.exchange) AS total_revenue
    FROM fact_sales AS f
    JOIN dim_product AS p USING(product_key)
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP BY year, p.category  
),
  prev_volumes AS(
    SELECT
      year,
      category,
      total_volume,
      total_revenue,
      LAG(total_volume) OVER(PARTITION BY category ORDER BY year ASC) AS prev_volume,
      LAG(total_revenue) OVER (PARTITION BY category ORDER BY year ASC) AS prev_revenue
    FROM volume_metrics
)

SELECT
  year,
  category,
  total_volume,
  ROUND(((total_volume - prev_volume) * 100.0 / NULLIF(prev_volume, 0))::NUMERIC, 2) AS volume_growth_pct,
  ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
  ROUND(((total_revenue - prev_revenue) * 100.0 / NULLIF(prev_revenue, 0))::NUMERIC, 2) AS revenue_growth_pct
FROM prev_volumes
ORDER BY category, year;

-- Volume seasonal patterns check

CREATE OR REPLACE VIEW analytics.seasonal_volume AS
  WITH month_track AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      EXTRACT(MONTH FROM f.order_date) AS month,
      p.category,
      SUM(f.quantity) AS total_volume
    FROM fact_sales AS f
    JOIN dim_product AS p USING(product_key)
    GROUP BY 1, 2, p.category
),

  avg_volume_month AS(
    SELECT
      *,
      AVG(total_volume) OVER (PARTITION BY category, month) AS monthly_avg
    FROM month_track
  )

SELECT
  year,
  month,
  category,
  total_volume,
  ROUND(monthly_avg::NUMERIC, 2) AS monthly_avg,
  ROUND(((total_volume - monthly_avg) * 100.0 /
  NULLIF(monthly_avg, 0))::NUMERIC, 2) AS pct_above_month_avg
FROM avg_volume_month
ORDER BY category, year, month;
