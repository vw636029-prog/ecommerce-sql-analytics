CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

-- Ensure we are using the correct database
USE ecommerce_analytics;

-- Drop tables if they exist to ensure a clean slate (in reverse order of dependencies)
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS inventory_logs;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS vendors;
DROP TABLE IF EXISTS customers;

-- 1. Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    signup_date DATE NOT NULL,
    country VARCHAR(50) NOT NULL
);

-- 2. Vendors Table
CREATE TABLE vendors (
    vendor_id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name VARCHAR(100) NOT NULL,
    commission_rate DECIMAL(4,2) NOT NULL 
);

-- 3. Products Table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    vendor_id INT,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);

-- 4. Orders Table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME NOT NULL,
    order_status VARCHAR(20) CHECK (order_status IN ('Completed', 'Shipped', 'Cancelled', 'Returned')),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 5. Order Items Table
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 6. Payments Table
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    payment_date DATETIME NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(30) CHECK (payment_method IN ('Credit Card', 'PayPal', 'Debit Card', 'Apple Pay')),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- 7. Inventory Logs Table
CREATE TABLE inventory_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    stock_change INT NOT NULL, 
    log_date DATETIME NOT NULL,
    reason VARCHAR(50),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Indexes for performance optimization
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

USE ecommerce_analytics;

-- Insert Vendors
INSERT INTO vendors (vendor_name, commission_rate) VALUES 
('Apex Electronics', 0.08),
('Urban Threads', 0.12),
('Home Essentials Co.', 0.10);

-- Insert Products
INSERT INTO products (product_name, category, price, cost, vendor_id) VALUES 
('Wireless Noise-Canceling Headphones', 'Electronics', 199.99, 120.00, 1),
('Ergonomic Office Chair', 'Home Essentials', 249.99, 150.00, 3),
('Slim Fit Denim Jeans', 'Apparel', 59.99, 22.00, 2),
('Smart Fitness Watch', 'Electronics', 129.99, 70.00, 1),
('Stainless Steel Water Bottle', 'Home Essentials', 24.99, 8.00, 3),
('Cotton Crewneck Sweatshirt', 'Apparel', 45.00, 18.00, 2);

-- Insert Customers
INSERT INTO customers (first_name, last_name, email, signup_date, country) VALUES 
('Alice', 'Johnson', 'alice.j@example.com', '2024-01-15', 'USA'),
('Bob', 'Smith', 'bob.smith@example.com', '2024-02-20', 'Canada'),
('Charlie', 'Brown', 'charlie.b@example.com', '2024-03-10', 'UK'),
('Diana', 'Prince', 'diana.p@example.com', '2025-01-05', 'USA'),
('Ethan', 'Hunt', 'ethan.h@example.com', '2025-02-18', 'Australia');

-- Insert Orders
INSERT INTO orders (customer_id, order_date, order_status) VALUES 
(1, '2025-03-01 10:15:00', 'Completed'),
(1, '2025-06-12 14:30:00', 'Completed'),
(2, '2025-04-05 09:20:00', 'Completed'),
(3, '2025-05-11 16:45:00', 'Cancelled'),
(3, '2025-07-19 11:10:00', 'Completed'),
(4, '2026-01-10 13:00:00', 'Completed'),
(5, '2026-02-14 18:25:00', 'Completed'),
(1, '2026-03-01 08:00:00', 'Completed');

-- Insert Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES 
(1, 1, 1, 199.99),
(1, 5, 2, 24.99),
(2, 4, 1, 129.99),
(3, 3, 2, 59.99),
(4, 2, 1, 249.99),
(5, 6, 3, 45.00),
(6, 1, 1, 199.99),
(7, 2, 1, 249.99),
(8, 3, 1, 59.99);

-- Insert Payments
INSERT INTO payments (order_id, payment_date, payment_amount, payment_method) VALUES 
(1, '2025-03-01 10:18:00', 249.97, 'Credit Card'),
(2, '2025-06-12 14:32:00', 129.99, 'Apple Pay'),
(3, '2025-04-05 09:22:00', 119.98, 'PayPal'),
(5, '2025-07-19 11:12:00', 135.00, 'Credit Card'),
(6, '2026-01-10 13:02:00', 199.99, 'Debit Card'),
(7, '2026-02-14 18:28:00', 249.99, 'Credit Card'),
(8, '2026-03-01 08:02:00', 59.99, 'PayPal');

USE ecommerce_analytics;

--------------------------------------------------------------------------------
-- QUERY 1: Customer RFM Segmentation & Customer Lifetime Value (CLV) Engine
--------------------------------------------------------------------------------

/*
What it does: The Business Value: This allows marketing teams to instantly identify their most valuable VIP spenders versus dormant users 
who need targeted win-back campaigns.
*/

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        MAX(o.order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_amount) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name
),
rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        last_purchase_date,
        frequency,
        monetary_value,
        NTILE(4) OVER (ORDER BY monetary_value DESC) AS monetary_score,
        NTILE(4) OVER (ORDER BY frequency DESC) AS frequency_score,
        NTILE(4) OVER (ORDER BY last_purchase_date ASC) AS recency_score
    FROM customer_metrics
)
SELECT 
    customer_id,
    customer_name,
    frequency,
    monetary_value AS total_clv,
    CASE 
        WHEN monetary_score = 1 AND frequency_score = 1 THEN 'Champions'
        WHEN monetary_score <= 2 AND frequency_score <= 2 THEN 'Loyal Customers'
        WHEN recency_score >= 3 THEN 'At Risk'
        ELSE 'Standard'
    END AS customer_segment
FROM rfm_scores
ORDER BY total_clv DESC;

/* 
What it does: Uses window functions (SUM() OVER) to calculate cumulative financial performance month-over-month, which finance teams 
use to track company growth.
*/


WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS sales_month,
        COUNT(DISTINCT o.customer_id) AS monthly_active_buyers,
        COUNT(o.order_id) AS total_orders,
        SUM(p.payment_amount) AS monthly_revenue
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT 
    sales_month,
    monthly_active_buyers,
    total_orders,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY sales_month) AS running_total_revenue
FROM monthly_sales
ORDER BY sales_month;

/*
What it does: Uses the LAG() window function to look at a customer's previous order date and calculate the exact number of days between 
purchases. This shows hiring managers you know how to analyze customer retention cycles.
*/

WITH ordered_customer_purchases AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT 
    customer_id,
    order_id,
    order_date,
    previous_order_date,
    DATEDIFF(order_date, previous_order_date) AS days_since_last_order
FROM ordered_customer_purchases
WHERE previous_order_date IS NOT NULL;