COPY customers (customer_id, customer_name, segment, country, city, state, postal_code, region)
FROM '/path/to/data/customers.csv'
DELIMITER ','
CSV HEADER;

COPY products (product_id, product_name, category, sub_category)
FROM '/path/to/data/products.csv'
DELIMITER ','
CSV HEADER;

COPY orders (row_id, order_id, order_date, ship_date, ship_mode, customer_id, region,
             sales, quantity, discount, profit)
FROM '/path/to/data/orders.csv'
DELIMITER ','
CSV HEADER;

SELECT 'customers' AS tbl, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'products',          COUNT(*)          FROM products
UNION ALL
SELECT 'orders',            COUNT(*)          FROM orders;
