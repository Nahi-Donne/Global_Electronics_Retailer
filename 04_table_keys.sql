-- Add primary key

ALTER TABLE fact_sales ADD PRIMARY KEY (order_number, line_item);

-- Add foreigner key

ALTER TABLE fact_sales ADD FOREIGN KEY (product_key) REFERENCES dim_product(product_key);
ALTER TABLE fact_sales ADD FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key);
ALTER TABLE fact_sales ADD FOREIGN KEY (store_key) REFERENCES dim_store(store_key);

-- Add index Keys

CREATE INDEX idx_product ON fact_sales(product_key, order_date);
CREATE INDEX idx_customer ON fact_sales(customer_key);
CREATE INDEX idx_store ON fact_sales(store_key);
CREATE INDEX idx_ex_currency ON fact_sales(currency_code);

-- Add index Keys on dim_tables

CREATE INDEX idx_product_key ON dim_product(product_key);
CREATE INDEX idx_customer_key ON dim_customer(customer_key);
CREATE INDEX idx_store_key ON dim_store(story_key);
CREATE INDEX idx_date ON dim_date(date);
CREATE INDEX idx_currency ON dim_currency(currency, date);