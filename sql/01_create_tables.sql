-- ============================================================
-- Sales Dashboard for Regional Performance
-- Script 01: Create Tables
-- Author: Sales Analytics Team
-- Date: April 2026
-- ============================================================

-- Drop tables if they exist (clean slate)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

-- ============================================================
-- TABLE 1: customers
-- ============================================================
CREATE TABLE customers (
    customer_id   VARCHAR(20)  PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment       VARCHAR(30)  NOT NULL,  -- Consumer / Corporate / Home Office
    country       VARCHAR(50)  NOT NULL,
    city          VARCHAR(100) NOT NULL,
    state         VARCHAR(50)  NOT NULL,
    postal_code   VARCHAR(10),
    region        VARCHAR(20)  NOT NULL   -- East / West / Central / South
);

-- ============================================================
-- TABLE 2: products
-- ============================================================
CREATE TABLE products (
    product_id   VARCHAR(30)  PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category     VARCHAR(50)  NOT NULL,   -- Furniture / Office Supplies / Technology
    sub_category VARCHAR(50)  NOT NULL
);

-- ============================================================
-- TABLE 3: orders (fact table – one row per order)
-- ============================================================
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

-- Index for common filter patterns
CREATE INDEX idx_orders_region    ON orders(region);
CREATE INDEX idx_orders_date      ON orders(order_date);
CREATE INDEX idx_orders_customer  ON orders(customer_id);

-- ============================================================
-- Verification
-- ============================================================
SELECT 'Tables created successfully' AS status;
