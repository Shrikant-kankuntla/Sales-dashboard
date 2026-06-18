-- ============================================================
-- Sales Dashboard for Regional Performance
-- Script 04: SQLite Version (runs locally, no server needed)
-- Usage: sqlite3 sales_dashboard.db < 04_sqlite_queries.sql
-- ============================================================

-- Create tables
CREATE TABLE IF NOT EXISTS customers (
    customer_id   TEXT PRIMARY KEY,
    customer_name TEXT,
    segment       TEXT,
    country       TEXT,
    city          TEXT,
    state         TEXT,
    postal_code   TEXT,
    region        TEXT
);

CREATE TABLE IF NOT EXISTS products (
    product_id   TEXT PRIMARY KEY,
    product_name TEXT,
    category     TEXT,
    sub_category TEXT
);

CREATE TABLE IF NOT EXISTS orders (
    row_id      INTEGER PRIMARY KEY,
    order_id    TEXT,
    order_date  TEXT,
    ship_date   TEXT,
    ship_mode   TEXT,
    customer_id TEXT,
    region      TEXT,
    sales       REAL,
    quantity    INTEGER,
    discount    REAL,
    profit      REAL
);

-- Load CSV data (SQLite .import command)
-- Run these in the sqlite3 shell:
-- .mode csv
-- .headers on
-- .import customers.csv customers
-- .import products.csv products
-- .import orders.csv orders

-- ============================================================
-- KPI 1: Sales summary by region
-- ============================================================
SELECT
    region,
    COUNT(DISTINCT order_id)          AS total_orders,
    ROUND(SUM(sales), 2)              AS total_sales,
    ROUND(SUM(profit), 2)             AS total_profit,
    ROUND(AVG(profit / CASE WHEN sales = 0 THEN NULL ELSE sales END) * 100, 2) AS avg_margin_pct,
    SUM(quantity)                     AS total_units
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

-- ============================================================
-- KPI 2: Monthly trend
-- ============================================================
SELECT
    region,
    SUBSTR(order_date, 1, 7)   AS month,
    ROUND(SUM(sales), 2)        AS monthly_sales,
    ROUND(SUM(profit), 2)       AS monthly_profit
FROM orders
GROUP BY region, SUBSTR(order_date, 1, 7)
ORDER BY region, month;

-- ============================================================
-- KPI 3: Post-festival drop (Oct-Nov vs Dec-Jan)
-- ============================================================
WITH festival AS (
    SELECT region, SUM(sales) AS fest_sales
    FROM orders
    WHERE CAST(SUBSTR(order_date, 6, 2) AS INTEGER) IN (10, 11)
    GROUP BY region
),
post AS (
    SELECT region, SUM(sales) AS post_sales
    FROM orders
    WHERE CAST(SUBSTR(order_date, 6, 2) AS INTEGER) IN (12, 1)
    GROUP BY region
)
SELECT
    f.region,
    ROUND(f.fest_sales, 2)   AS festival_sales,
    ROUND(p.post_sales, 2)   AS post_festival_sales,
    ROUND((p.post_sales - f.fest_sales) / f.fest_sales * 100, 2) AS pct_change
FROM festival f
JOIN post p ON f.region = p.region
ORDER BY pct_change;

-- ============================================================
-- KPI 4: Discount impact on profitability
-- ============================================================
SELECT
    CASE
        WHEN discount = 0              THEN '0%'
        WHEN discount <= 0.10          THEN '1-10%'
        WHEN discount <= 0.20          THEN '11-20%'
        WHEN discount <= 0.30          THEN '21-30%'
        ELSE '30%+'
    END AS discount_band,
    COUNT(*) AS orders,
    ROUND(AVG(profit), 2) AS avg_profit,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) AS loss_pct
FROM orders
GROUP BY discount_band
ORDER BY discount_band;

-- ============================================================
-- KPI 5: Loss orders by region (proxy for returns)
-- ============================================================
SELECT
    region,
    COUNT(*) AS loss_orders,
    ROUND(SUM(profit), 2) AS total_loss,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS loss_rate_pct
FROM orders
WHERE profit < 0
GROUP BY region
ORDER BY total_loss;
