-- Create Category Table
CREATE TABLE category (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(100)
);

-- Create Products Table
CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(255),
    category_id VARCHAR(10),
    launch_date DATE,
    price NUMERIC(10,2),

    CONSTRAINT fk_category
        FOREIGN KEY (category_id)
        REFERENCES category(category_id)
);

-- Create Stores Table
CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY,
    store_name VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100)
);

-- Create Sales Table
CREATE TABLE sales (
    sale_id VARCHAR(15) PRIMARY KEY,
    sale_date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INT,

    CONSTRAINT fk_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- Create Warranty Table
CREATE TABLE warranty (
    claim_id VARCHAR(15) PRIMARY KEY,
    claim_date DATE,
    sale_id VARCHAR(15),
    repair_status VARCHAR(20),

    CONSTRAINT fk_sale
        FOREIGN KEY (sale_id)
        REFERENCES sales(sale_id)
);
