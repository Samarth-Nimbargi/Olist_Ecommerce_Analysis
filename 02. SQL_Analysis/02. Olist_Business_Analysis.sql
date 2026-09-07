-- C) BUSINESS_ANALYSIS

-- 1. SALES AND CUSTOMER ANALYSIS

-- 1.1 Which product categories and customer states generate the highest revenue?
--     How it helps: Helps the company identify its strongest markets and product categories
--     for focused investment and expansion.

SELECT
    COALESCE(
        pcnt.product_category_name_english,
        p.product_category_name
    ) AS product_category,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation AS pcnt
    ON p.product_category_name = pcnt.product_category_name
GROUP BY
    COALESCE(
        pcnt.product_category_name_english,
        p.product_category_name
    )
ORDER BY
    total_revenue DESC;

SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items AS oi
JOIN orders AS o
    ON oi.order_id = o.order_id
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_state
ORDER BY
    total_revenue DESC;

-- 1.2 How do monthly revenue and Average Order Value (AOV) change over time,
--     and which months have the highest and lowest values?
--     How it helps: Helps the company identify growth trends and seasonal periods
--     so it can plan marketing, inventory, and sales strategies.

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders AS o
JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY
    order_month;

-- 1.3 What percentage of customers are repeat buyers, and how does their average spending
--     compare with one-time customers?
--     How it helps: Helps determine the value of customer retention and whether the company should
--     invest more in loyalty and repeat-purchase strategies.

SELECT
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,
    ROUND(AVG(total_spending), 2) AS average_spending
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS total_spending,
        CASE
            WHEN COUNT(DISTINCT o.order_id) > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS customer_type
    FROM customers AS c
    JOIN orders AS o
        ON c.customer_id = o.customer_id
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.customer_unique_id
) AS customer_summary
GROUP BY
    customer_type
ORDER BY
    customer_count DESC;

-- 1.4 Which customer states have the highest number of customers but the lowest
--     Average Revenue per Customer?
--     How it helps: Identifies high-potential markets where the company may be able
--     to increase customer spending.

SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS average_revenue_per_customer
FROM customers AS c
JOIN orders AS o
    ON c.customer_id = o.customer_id
JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_state
ORDER BY
    customer_count DESC,
    average_revenue_per_customer ASC;
    
    

-- 2. PRODUCT AND SELLER ANALYSIS

-- 2.1 Which product categories generate the highest revenue, and which categories
--     have the highest number of orders?
--     How it helps: Helps the company identify products with strong financial performance
--     versus strong customer demand for better product and inventory decisions.

SELECT
    COALESCE(
        pcnt.product_category_name_english,
        p.product_category_name
    ) AS product_category,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS order_count
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation AS pcnt
    ON p.product_category_name = pcnt.product_category_name
GROUP BY
    COALESCE(
        pcnt.product_category_name_english,
        p.product_category_name
    )
ORDER BY
    total_revenue DESC;

-- 2.2 Which product categories have high sales volume but low average review scores?
--     How it helps: Identifies popular categories where product quality or customer
--     experience may need improvement.

SELECT
    COALESCE(
        pcnt.product_category_name_english,
        p.product_category_name
    ) AS product_category,
    COUNT(DISTINCT oi.order_id) AS order_count,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN order_reviews AS r
    ON oi.order_id = r.order_id
LEFT JOIN product_category_name_translation AS pcnt
    ON p.product_category_name = pcnt.product_category_name
GROUP BY
    COALESCE(
        pcnt.product_category_name_english,
        p.product_category_name
    )
HAVING
    COUNT(DISTINCT oi.order_id) >= 100
ORDER BY
    average_review_score ASC,
    order_count DESC;

-- 2.3 Which sellers have the highest revenue and order volume?
--     How it helps: Helps identify sellers that are important to the business based on both revenue
--     and customer order activity.

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS order_volume,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM sellers AS s
JOIN order_items AS oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY
    total_revenue DESC,
    order_volume DESC;

-- 2.4 Which sellers have low sales volume despite selling multiple unique products?
--     How it helps: Helps the company identify sellers whose products have low demand, allowing
--     management to review their pricing, product selection, promotions, or seller performance.

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(oi.product_id) AS products_sold,
    COUNT(DISTINCT oi.product_id) AS unique_products,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM sellers AS s
JOIN order_items AS oi
    ON s.seller_id = oi.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING
    COUNT(oi.product_id) <= 10
    AND COUNT(DISTINCT oi.product_id) > 1
ORDER BY
    products_sold ASC,
    unique_products DESC;
    

-- 3. DELIVERY AND OPERATIONS ANALYSIS

-- 3.1 Which states and sellers have the longest average delivery times?
--     How it helps: Helps management identify states and sellers with slower deliveries, allowing them
--     to improve logistics, optimize shipping processes, and prioritize areas where delivery performance needs improvement.

SELECT
    c.customer_state,
    oi.seller_id,
    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
        2
    ) AS average_delivery_days
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE
    o.order_delivered_customer_date IS NOT NULL
GROUP BY
    c.customer_state,
    oi.seller_id
ORDER BY
    average_delivery_days DESC;

-- 3.2 Which states have the longest average time from order approval to customer delivery?
--     How it helps: Helps management identify states with slower order fulfillment and delivery processes,
--     allowing them to improve logistics and allocate resources more effectively.

SELECT
    c.customer_state,
    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_approved_at
            )
        ),
        2
    ) AS average_delivery_days
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE
    o.order_approved_at IS NOT NULL
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY
    c.customer_state
ORDER BY
    average_delivery_days DESC;

-- 3.3 Which order statuses contribute the most orders, and what percentage of total orders
--     does each status represent?
--     How it helps: Helps management understand the overall order pipeline and identify operational
--     areas that require attention.

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY
    order_status
ORDER BY
    order_count DESC;

-- 3.4 Which payment methods are used most frequently, and what is their average transaction value?
--     How it helps: Helps the company understand customer payment preferences and identify which payment
--     methods generate higher-value transactions, supporting payment strategy and optimization.

SELECT
    payment_type,
    COUNT(*) AS transaction_count,
    ROUND(AVG(payment_value), 2) AS average_transaction_value
FROM order_payments
GROUP BY
    payment_type
ORDER BY
    transaction_count DESC;

