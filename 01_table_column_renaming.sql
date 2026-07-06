-- Column Change for customers Table

ALTER TABLE public.customers RENAME COLUMN "CustomerKey" TO customer_key;
ALTER TABLE public.customers RENAME COLUMN "Gender" TO gender;
ALTER TABLE public.customers RENAME COLUMN "Name" TO full_name;
ALTER TABLE public.customers RENAME COLUMN "City" TO city;
ALTER TABLE public.customers RENAME COLUMN "State Code" TO state_code;
ALTER TABLE public.customers RENAME COLUMN "State" TO state;
ALTER TABLE public.customers RENAME COLUMN "Zip Code" TO zip_code;
ALTER TABLE public.customers RENAME COLUMN "Country" TO country;
ALTER TABLE public.customers RENAME COLUMN "Continent" TO continent;
ALTER TABLE public.customers RENAME COLUMN "Birthday" TO birthday;

-- Column Change for products Table

ALTER TABLE public.products RENAME COLUMN "ProductKey" TO product_key;
ALTER TABLE public.products RENAME COLUMN "Product Name" TO product_name;
ALTER TABLE public.products RENAME COLUMN "Brand" TO brand;
ALTER TABLE public.products RENAME COLUMN "Color" TO color;
ALTER TABLE public.products RENAME COLUMN "Unit Cost USD" TO unit_cost_usd;
ALTER TABLE public.products RENAME COLUMN "Unit Price USD" TO unit_price_usd;
ALTER TABLE public.products RENAME COLUMN "SubcategoryKey" TO subcategory_key;
ALTER TABLE public.products RENAME COLUMN "Subcategory" TO subcategory;
ALTER TABLE public.products RENAME COLUMN "CategoryKey" TO category_key;
ALTER TABLE public.products RENAME COLUMN "Category" TO category;

-- Column Change for exchange_rates Table

ALTER TABLE public.exchange_rates RENAME COLUMN "Date" TO date;
ALTER TABLE public.exchange_rates RENAME COLUMN "Currency" TO currency;
ALTER TABLE public.exchange_rates RENAME COLUMN "Exchange" TO exchange;

-- Column Change for Sales Table

ALTER TABLE public.sales RENAME COLUMN "Order Number" TO order_number;
ALTER TABLE public.sales RENAME COLUMN "Line Item" TO line_item;
ALTER TABLE public.sales RENAME COLUMN "Order Date" TO order_date;
ALTER TABLE public.sales RENAME COLUMN "Delivery Date" TO delivery_date;
ALTER TABLE public.sales RENAME COLUMN "CustomerKey" TO customer_key;
ALTER TABLE public.sales RENAME COLUMN "StoreKey" TO store_key;
ALTER TABLE public.sales RENAME COLUMN "ProductKey" TO product_key;
ALTER TABLE public.sales RENAME COLUMN "Quantity" TO quantity;
ALTER TABLE public.sales RENAME COLUMN "Currency Code" TO currency_code;

-- Column Change for Stores Table

ALTER TABLE public.stores RENAME COLUMN "StoreKey" TO store_key;
ALTER TABLE public.stores RENAME COLUMN "Country" TO country;
ALTER TABLE public.stores RENAME COLUMN "State" TO state;
ALTER TABLE public.stores RENAME COLUMN "Square Meters" TO square_meters;
ALTER TABLE public.stores RENAME COLUMN "Open Date" TO open_date;

