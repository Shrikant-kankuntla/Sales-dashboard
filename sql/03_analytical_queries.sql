CREATE OR REPLACE VIEW vw_sales_master AS
SELECT
    o.row_id,
    o.order_id,
    o.order_date,
    o.ship_date,
    o.ship_mode,
    o.region,
    EXTRACT(YEAR  FROM o.order_date)  AS order_year,
    EXTRACT(MONTH FROM o.order_date)  AS order_month,
    TO_CHAR(o.order_date, 'Mon YYYY') AS month_label,
    o.sales,
    o.quantity,
    o.discount,
    o.profit,
    ROUND(o.profit / NULLIF(o.sales, 0) * 100, 2) AS profit_margin_pct,
    o.ship_date - o.order_date         AS days_to_ship,

    c.customer_id,
    c.customer_name,
    c.segment,
    c.city,
    c.state,

    p.product_id,
    p.product_name,
    p.category,
    p.sub_category
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products  p ON (

    p.product_id = (
        SELECT product_id FROM order_items oi
        WHERE oi.row_id = o.row_id LIMIT 1
    )
);

SELECT
    region,
    COUNT(DISTINCT order_id)          AS total_orders,
    SUM(sales)                        AS total_sales,
    SUM(profit)                       AS total_profit,
    ROUND(AVG(profit / NULLIF(sales,0)) * 100, 2) AS avg_profit_margin_pct,
    SUM(quantity)                     AS total_units_sold
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

SELECT
    region,
    DATE_TRUNC('month', order_date)   AS sales_month,
    TO_CHAR(order_date, 'Mon YYYY')   AS month_label,
    SUM(sales)                        AS monthly_sales,
    SUM(profit)                       AS monthly_profit,
    COUNT(DISTINCT order_id)          AS orders_count
FROM orders
GROUP BY region, DATE_TRUNC('month', order_date), TO_CHAR(order_date, 'Mon YYYY')
ORDER BY region, sales_month;


WITH festival AS (
    SELECT
        region,
        SUM(sales) AS festival_sales
    FROM orders
    WHERE EXTRACT(MONTH FROM order_date) IN (10, 11)
    GROUP BY region
),
post_festival AS (
    SELECT
        region,
        SUM(sales) AS post_festival_sales
    FROM orders
    WHERE EXTRACT(MONTH FROM order_date) IN (12, 1)
    GROUP BY region
)
SELECT
    f.region,
    ROUND(f.festival_sales, 2)                         AS festival_sales,
    ROUND(pf.post_festival_sales, 2)                   AS post_festival_sales,
    ROUND((pf.post_festival_sales - f.festival_sales)
          / NULLIF(f.festival_sales, 0) * 100, 2)      AS pct_change,
    CASE
        WHEN (pf.post_festival_sales - f.festival_sales)
             / NULLIF(f.festival_sales, 0) <= -0.10
        THEN '⚠ Significant Drop – Recovery Plan Needed'
        WHEN (pf.post_festival_sales - f.festival_sales)
             / NULLIF(f.festival_sales, 0) BETWEEN -0.10 AND 0
        THEN 'Slight Decline'
        ELSE '✓ Stable / Growth'
    END AS status_flag
FROM festival f
JOIN post_festival pf ON f.region = pf.region
ORDER BY pct_change;

SELECT
    p.product_name,
    p.category,
    p.sub_category,
    SUM(o.sales)    AS total_sales,
    SUM(o.profit)   AS total_profit,
    SUM(o.quantity) AS total_qty
FROM orders o
JOIN products p ON o.row_id = p.row_id   
GROUP BY p.product_name, p.category, p.sub_category
ORDER BY total_sales DESC
LIMIT 10;

SELECT
    o.region,
    p.category,
    SUM(o.sales)                              AS total_sales,
    SUM(o.profit)                             AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales),0)*100, 2) AS margin_pct,
    COUNT(DISTINCT o.order_id)                AS orders
FROM orders o
JOIN products p ON o.row_id = p.row_id
GROUP BY o.region, p.category
ORDER BY o.region, total_sales DESC;

SELECT
    CASE
        WHEN discount = 0            THEN '0% – No Discount'
        WHEN discount BETWEEN 0.01 AND 0.10 THEN '1–10%'
        WHEN discount BETWEEN 0.11 AND 0.20 THEN '11–20%'
        WHEN discount BETWEEN 0.21 AND 0.30 THEN '21–30%'
        ELSE '30%+'
    END                         AS discount_band,
    COUNT(*)                    AS orders,
    ROUND(AVG(sales), 2)        AS avg_sales,
    ROUND(AVG(profit), 2)       AS avg_profit,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1)
                                AS loss_order_pct
FROM orders
GROUP BY discount_band
ORDER BY discount_band;

SELECT
    c.segment,
    o.region,
    COUNT(DISTINCT o.order_id)   AS total_orders,
    COUNT(DISTINCT c.customer_id) AS unique_customers,
    ROUND(SUM(o.sales), 2)       AS total_sales,
    ROUND(SUM(o.profit), 2)      AS total_profit,
    ROUND(AVG(o.sales), 2)       AS avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.segment, o.region
ORDER BY total_sales DESC;

SELECT
    ship_mode,
    region,
    COUNT(*)                             AS orders,
    ROUND(AVG(ship_date - order_date), 1) AS avg_days_to_ship,
    MIN(ship_date - order_date)           AS min_days,
    MAX(ship_date - order_date)           AS max_days,
    ROUND(SUM(sales), 2)                  AS total_sales
FROM orders
WHERE ship_date IS NOT NULL
GROUP BY ship_mode, region
ORDER BY avg_days_to_ship;

SELECT
    p.category,
    p.sub_category,
    SUM(o.sales)                                      AS total_sales,
    SUM(o.profit)                                     AS total_profit,
    ROUND(SUM(o.profit)/NULLIF(SUM(o.sales),0)*100,2) AS margin_pct,
    DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(o.profit) DESC)
                                                      AS profit_rank
FROM orders o
JOIN products p ON o.row_id = p.row_id
GROUP BY p.category, p.sub_category
ORDER BY p.category, profit_rank;

WITH monthly AS (
    SELECT
        region,
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS sales
    FROM orders
    GROUP BY region, DATE_TRUNC('month', order_date)
)
SELECT
    region,
    TO_CHAR(month, 'Mon YYYY')              AS period,
    ROUND(sales, 2)                         AS current_sales,
    ROUND(LAG(sales) OVER (PARTITION BY region ORDER BY month), 2) AS prev_month_sales,
    ROUND((sales - LAG(sales) OVER (PARTITION BY region ORDER BY month))
          / NULLIF(LAG(sales) OVER (PARTITION BY region ORDER BY month), 0) * 100, 2)
                                            AS mom_growth_pct
FROM monthly
ORDER BY region, month;

SELECT
    o.region,
    p.category,
    p.sub_category,
    COUNT(*) AS loss_orders,
    ROUND(SUM(o.profit), 2) AS total_loss,
    ROUND(AVG(o.discount), 3) AS avg_discount
FROM orders o
JOIN products p ON o.row_id = p.row_id
WHERE o.profit < 0
GROUP BY o.region, p.category, p.sub_category
ORDER BY total_loss ASC;
