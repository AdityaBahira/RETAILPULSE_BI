-- =====================================================================
-- 🔍 1: Data Audit & Verification Commands
-- =====================================================================
USE retailpulse;

-- 1. Total Record Count Check (Should return 4,995)
SELECT COUNT(*) AS total_records FROM orders;

-- 2. Check for Duplicate Order IDs
SELECT order_id, COUNT(*) AS dup_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Check for Nulls or Missing Data
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_orders,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue,
    SUM(CASE WHEN `month` IS NULL THEN 1 ELSE 0 END) AS null_month
FROM orders;

-- 4. Audit Data Range & Extremes
SELECT 
    MIN(order_date) AS start_date,
    MAX(order_date) AS end_date,
    MIN(revenue) AS min_order_revenue,
    MAX(revenue) AS max_order_revenue
FROM orders;

-- ====================================================================================
-- 📊 2: Baseline Performance & KPI Queries
-- ====================================================================================

-- Query 1: Total Company Revenue
SELECT 
    ROUND(SUM(revenue), 2) AS total_revenue
FROM orders;

-- Query 2: Total Company Profit
SELECT 
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS overall_margin_pct
FROM orders;

-- Query 3: Revenue & Profit Performance by Category
SELECT 
    category,
    COUNT(order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;

-- Query 4: Profit & Revenue Performance by Region
SELECT 
    region,
    COUNT(order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue), 2) AS regional_revenue,
    ROUND(SUM(profit), 2) AS regional_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY region
ORDER BY regional_revenue DESC;

-- Query 5: Top 10 Products by Sales & Revenue
SELECT 
    product_name,
    category,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY product_name, category
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 6: Monthly Revenue & Profit Trend Analysis
SELECT 
    `year_month` AS period,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(revenue), 2) AS monthly_revenue,
    ROUND(SUM(profit), 2) AS monthly_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY `year_month`
ORDER BY period ASC;

-- ===================================================================================
-- 🎯 3: Business Questions & Executive Findings
-- ===================================================================================

-- Q1: Top Revenue
SELECT category, ROUND(SUM(revenue), 2) AS total_revenue 
FROM orders GROUP BY category ORDER BY total_revenue DESC LIMIT 1;

-- Q2:Profit Category
SELECT category, ROUND(SUM(profit), 2) AS total_profit 
FROM orders GROUP BY category ORDER BY total_profit DESC LIMIT 1;

-- Q3: Highest Revenue vs Profitability Alignment
SELECT 
    category,
    ROUND(SUM(revenue), 2) AS category_revenue,
    ROUND(SUM(profit), 2) AS category_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY category
ORDER BY category_revenue DESC;

-- Q4: Region Needing Attention (Revenue Share Analysis)
SELECT 
    region,
    COUNT(order_id) AS order_count,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND((SUM(revenue) / (SELECT SUM(revenue) FROM orders)) * 100, 2) AS revenue_share_pct,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY region
ORDER BY total_revenue ASC;

-- Q5: Products with High Sales but Weak Profitability (Margin Leakage)
SELECT 
    product_name,
    category,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_pct,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY product_name, category
HAVING total_revenue > 400000 AND profit_margin_pct < 25.00
ORDER BY total_revenue DESC;

-- Q6 & Q7: Peak Sales & Peak Profit Month
SELECT 
    `year_month` AS peak_month,
    ROUND(SUM(revenue), 2) AS monthly_revenue,
    ROUND(SUM(profit), 2) AS monthly_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS margin_pct
FROM orders
GROUP BY `year_month`
ORDER BY monthly_revenue DESC
LIMIT 1;

-- Q8: Sales Channel Comparison (Online vs. Store)
SELECT 
    sales_channel,
    COUNT(order_id) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(revenue) / COUNT(order_id), 2) AS avg_order_value,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY sales_channel
ORDER BY total_revenue DESC;

-- Q9: Top 10 Customer Leaderboard
SELECT 
    customer_id,
    region,
    COUNT(order_id) AS order_count,
    SUM(quantity) AS items_purchased,
    ROUND(SUM(revenue), 2) AS total_spent,
    ROUND(SUM(profit), 2) AS profit_generated
FROM orders
GROUP BY customer_id, region
ORDER BY total_spent DESC
LIMIT 10;

-- ======================================================================================
-- 🚀 4: Advanced SQL Queries
-- ======================================================================================

-- Advanced 1: Customer Segmentation (VIP vs Standard Ranking with DENSE_RANK())
WITH CustomerSummary AS (
    SELECT 
        customer_id,
        region,
        COUNT(order_id) AS total_orders,
        ROUND(SUM(revenue), 2) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(revenue) DESC) AS customer_rank
    FROM orders
    GROUP BY customer_id, region
)
SELECT 
    customer_rank,
    customer_id,
    region,
    total_orders,
    total_spent,
    CASE 
        WHEN customer_rank <= 10 THEN 'VIP Customer (Top 10)'
        WHEN customer_rank <= 50 THEN 'High-Value Customer'
        ELSE 'Regular Customer'
    END AS customer_tier
FROM CustomerSummary
LIMIT 20;

-- Advanced 2: Discount Tier Profitability Impact Analysis
SELECT 
    CASE 
        WHEN discount = 0 THEN '0% No Discount'
        WHEN discount > 0 AND discount <= 0.10 THEN '1% - 10% Discount'
        WHEN discount > 0.10 AND discount <= 0.20 THEN '11% - 20% Discount'
        ELSE '21%+ Deep Discount'
    END AS discount_bracket,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY discount_bracket
ORDER BY profit_margin_pct DESC;

-- Advanced 3: Top 3 Products Per Region (Partitioned Window Function)
WITH RegionalProducts AS (
    SELECT 
        region,
        category,
        product_name,
        ROUND(SUM(revenue), 2) AS product_revenue,
        DENSE_RANK() OVER (PARTITION BY region ORDER BY SUM(revenue) DESC) AS regional_rank
    FROM orders
    GROUP BY region, category, product_name
)
SELECT 
    region,
    regional_rank,
    product_name,
    category,
    product_revenue
FROM RegionalProducts
WHERE regional_rank <= 3
ORDER BY region ASC, regional_rank ASC;
