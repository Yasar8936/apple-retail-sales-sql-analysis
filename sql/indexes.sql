-- ==========================================
-- Indexes for Performance Optimization
-- Apple Retail Sales SQL Analysis
-- ==========================================

-- Sales Table
CREATE INDEX idx_sales_product_id
ON sales(product_id);

CREATE INDEX idx_sales_store_id
ON sales(store_id);

CREATE INDEX idx_sales_sale_date
ON sales(sale_date);

-- Warranty Table
CREATE INDEX idx_warranty_sale_id
ON warranty(sale_id);

CREATE INDEX idx_warranty_claim_date
ON warranty(claim_date);

-- Products Table
CREATE INDEX idx_products_category_id
ON products(category_id);

-- Stores Table
CREATE INDEX idx_stores_country
ON stores(country);
