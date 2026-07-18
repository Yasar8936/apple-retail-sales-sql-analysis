-- ==========================================
-- Indexes for Performance Optimization
-- Apple Retail Sales SQL Analysis
-- ==========================================

-- Improve filtering and joins by product
CREATE INDEX sales_product_id
ON sales(product_id);

-- Improve joins between sales and stores
CREATE INDEX sales_store_id
ON sales(store_id);

-- Improve date-based filtering and sorting
CREATE INDEX sales_sale_date
ON sales(sale_date);
