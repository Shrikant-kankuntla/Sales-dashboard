DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

CREATE TABLE customers (
    customer_id   VARCHAR(20)  PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment       VARCHAR(30)  NOT NULL,
    country       VARCHAR(50)  NOT NULL,
    city          VARCHAR(100) NOT NULL,
    state         VARCHAR(50)  NOT NULL,
    postal_code   VARCHAR(10),
    region        VARCHAR(20)  NOT NULL   
);

CREATE TABLE products (
    product_id   VARCHAR(30)  PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category     VARCHAR(50)  NOT NULL,   
    sub_category VARCHAR(50)  NOT NULL
);


CREATE TABLE orders (
    row_id      INT          PRIMARY KEY,
    order_id    VARCHAR(20)  NOT NULL,
    order_date  DATE         NOT NULL,
    ship_date   DATE,
    ship_mode   VARCHAR(30),
    customer_id VARCHAR(20)  NOT NULL REFERENCES customers(customer_id),
    region      VARCHAR(20)  NOT NULL,
    sales       NUMERIC(12,4),
    quantity    INT,
    discount    NUMERIC(5,2),
    profit      NUMERIC(12,4)
);

CREATE INDEX idx_orders_region    ON orders(region);
CREATE INDEX idx_orders_date      ON orders(order_date);
CREATE INDEX idx_orders_customer  ON orders(customer_id);

SELECT 'Tables created successfully' AS status;
