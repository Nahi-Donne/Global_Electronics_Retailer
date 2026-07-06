/*
==================================================
Revenue Analysis Views
Project: Sales Performance Dashboard

Description:
Contains views used to analyze:
- Revenue trends
- YoY revenue growth
- Revenue by country
- Seasonal revenue patterns
==================================================
*/

-- Revenue evolving year over year analysis.

CREATE OR REPLACE VIEW analytics.yearly_revenues AS
  WITH yearly_metrics AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      SUM(f.revenue_native * exchange) AS revenue
    FROM fact_sales AS f
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP BY year
),

  prev_year_revenues AS(
    SELECT
      year,
      revenue,
      LAG(revenue) OVER (ORDER BY year) AS prev_year_revenue
    FROM yearly_metrics
)

SELECT
  year,
  ROUND(revenue::NUMERIC, 2) AS revenue,
  ROUND(((revenue - prev_year_revenue) * 100.0 / NULLIF(prev_year_revenue, 0))::NUMERIC, 2)  AS yoy_revenue_growth_pct
FROM prev_year_revenues;

-- Revenue by country

CREATE OR REPLACE VIEW analytics.revenue_country AS
WITH yearly_metrics AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      SUM(f.revenue_native * exchange) AS revenue,
      c.country
    FROM fact_sales AS f
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    JOIN dim_customer AS c USING(customer_key)
    GROUP BY year, c.country
),

  prev_year_revenues AS(
    SELECT
      year,
      country,
      revenue,
      LAG(revenue) OVER (PARTITION BY country ORDER BY year) AS prev_year_revenue
    FROM yearly_metrics
)

SELECT
  year,
  country,
  ROUND(revenue::NUMERIC, 2) AS revenue,
  ROUND(((revenue - prev_year_revenue) * 100.0 / NULLIF(prev_year_revenue, 0))::NUMERIC, 2)  AS yoy_revenue_growth_pct
FROM prev_year_revenues;

-- Revenue seasonal patterns check.

CREATE OR REPLACE VIEW analytics.seasonal_revenue AS
  WITH month_track AS(
    SELECT
      EXTRACT(YEAR FROM f.order_date)::INT AS year,
      EXTRACT(MONTH FROM f.order_date) AS month,
      SUM(f.revenue_native * ex.exchange) AS revenue
    FROM fact_sales AS f
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP BY 1, 2
),

  avg_revenue_month AS(
    SELECT
      year,
      month,
      revenue,
      AVG(revenue) OVER (PARTITION BY month) AS monthly_avg
    FROM month_track
)

SELECT
  year,
  month,
  ROUND(revenue::NUMERIC, 2) AS revenue,
  ROUND(monthly_avg::NUMERIC, 2) AS monthly_avg,
  ROUND(((revenue - monthly_avg) * 100.0 /
  NULLIF(monthly_avg, 0))::NUMERIC, 2) AS pct_above_month_avg
FROM avg_revenue_month
ORDER BY year, month;

-- Which periods show anomalies or inflection points, and what events correlate with them?

CREATE OR REPLACE VIEW analytics.periods_anomalies AS
  WITH monthly_metrics AS(
    SELECT
      EXTRACT(YEAR FROM order_date)::INT AS year,
      EXTRACT(MONTH FROM order_date) AS month,
      SUM(revenue_native * ex.exchange) AS revenue
    FROM fact_sales AS f
    JOIN dim_currency AS ex ON ex.currency = f.currency_code AND ex.date = f.order_date
    GROUP BY 1, 2
),
   stats AS(
    SELECT
      *,
      AVG(revenue) OVER (PARTITION BY month) AS avg_revenue,
      STDDEV_SAMP(revenue) OVER (PARTITION BY month) AS stdv_revenue
    FROM monthly_metrics
)

SELECT
  year,
  month,
  ROUND(revenue::NUMERIC, 2) AS revenue,
  ROUND(((revenue - avg_revenue) / NULLIF(stdv_revenue, 0))::NUMERIC, 2) AS z_score
FROM stats
ORDER BY ABS((revenue - avg_revenue) / NULLIF(stdv_revenue, 0)) DESC, month DESC;
