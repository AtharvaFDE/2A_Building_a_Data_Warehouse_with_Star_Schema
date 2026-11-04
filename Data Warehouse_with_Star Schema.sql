CREATE DATABASE IF NOT EXISTS sales_datawarehouse_example;

USE sales_datawarehouse_example;

SHOW DATABASES;

CREATE TABLE IF NOT EXISTS dim_time (
    time_key INT,
    full_date DATE NOT NULL,
    day INT,
    month INT,
    month_name VARCHAR(100),
    quarter INT,
    year INT,
    CONSTRAINT pk_time_key PRIMARY KEY (time_key)
);


INSERT INTO dim_time
(time_key, full_date, day, month, month_name, quarter, year)
VALUES
(20260101, '2026-01-01', 1, 1, 'January', 1, 2026),
(20260102, '2026-01-02', 2, 1, 'January', 1, 2026),
(20260201, '2026-02-01', 1, 2, 'February', 1, 2026),
(20260301, '2026-03-01', 1, 3, 'March', 1, 2026);



CREATE TABLE IF NOT EXISTS dim_region (
    region_key INT AUTO_INCREMENT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    CONSTRAINT pk_region_key PRIMARY KEY (region_key)
);

INSERT INTO dim_region
(city, state, country)
VALUES
('Pune', 'Maharashtra', 'India'),
('Mumbai', 'Maharashtra', 'India'),
('Delhi', 'Delhi', 'India'),
('Bangalore', 'Karnataka', 'India');


SELECT *  FROM dim_region;


CREATE TABLE IF NOT EXISTS dim_product (
    product_key INT AUTO_INCREMENT,
    product_id INT NOT NULL,
    product_name VARCHAR(100),
    category VARCHAR(100),
    brand VARCHAR(100),
    CONSTRAINT pk_product_key PRIMARY KEY (product_key)
);


INSERT INTO dim_product
(product_id, product_name, category, brand)
VALUES
(501, 'Laptop', 'Electronics', 'Dell'),
(502, 'Mobile', 'Electronics', 'Samsung'),
(503, 'Headphones', 'Accessories', 'Sony'),
(504, 'Keyboard', 'Accessories', 'Logitech');


CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INT AUTO_INCREMENT,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(100),
    CONSTRAINT pk_customer_key PRIMARY KEY (customer_key)
);

INSERT INTO dim_customer
(customer_id, customer_name, email, city)
VALUES
(101, 'Rahul Sharma', 'rahul@gmail.com', 'Pune'),
(102, 'Priya Patil', 'priya@gmail.com', 'Mumbai'),
(103, 'Amit Verma', 'amit@gmail.com', 'Delhi'),
(104, 'Sneha Rao', 'sneha@gmail.com', 'Bangalore');



CREATE TABLE IF NOT EXISTS fact_sales (
    sales_key INT AUTO_INCREMENT,
    time_key INT,
    region_key INT,
    product_key INT,
    customer_key INT,
    order_id INT,
    quantity INT,
    sales_amount DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),

    CONSTRAINT fk_time_key FOREIGN KEY (time_key)
    REFERENCES dim_time(time_key),

    CONSTRAINT fk_region_key FOREIGN KEY (region_key)
    REFERENCES dim_region(region_key),

    CONSTRAINT fk_product_key FOREIGN KEY (product_key)
    REFERENCES dim_product(product_key),

    CONSTRAINT fk_customer_key FOREIGN KEY (customer_key)
    REFERENCES dim_customer(customer_key),

    CONSTRAINT pk_sales_key PRIMARY KEY (sales_key)
);


INSERT INTO fact_sales
(
    time_key,
    region_key,
    product_key,
    customer_key,
    order_id,
    quantity,
    sales_amount,
    discount_amount,
    total_amount
)

SELECT
    t.time_key,
    r.region_key,
    p.product_key,
    c.customer_key,

    x.order_id,
    x.quantity,
    x.sales_amount,
    x.discount_amount,
    x.sales_amount - x.discount_amount

FROM
(
    SELECT 1001 AS order_id, '2026-01-01' AS sale_date,
           101 AS customer_id, 501 AS product_id,
           1 AS quantity, 50000.00 AS sales_amount,
           2000.00 AS discount_amount

    UNION ALL

    SELECT 1002, '2026-01-02', 102, 502,
           2, 30000.00, 1000.00

    UNION ALL

    SELECT 1003, '2026-02-01', 103, 503,
           1, 3000.00, 0.00

    UNION ALL

    SELECT 1004, '2026-03-01', 104, 504,
           2, 4000.00, 500.00
) AS x

JOIN dim_time t
    ON t.full_date = x.sale_date

JOIN dim_customer c
    ON c.customer_id = x.customer_id

JOIN dim_product p
    ON p.product_id = x.product_id

JOIN dim_region r
    ON r.city = c.city;
    
    
SELECT * FROM fact_sales;


-- Implementating SCD Type 2

ALTER TABLE dim_customer
ADD COLUMN effective_start_date DATE,
ADD COLUMN effective_end_date DATE,
ADD COLUMN is_current BOOLEAN;


UPDATE dim_customer
SET
    effective_start_date = '2026-01-01',
    effective_end_date = '9999-12-31',
    is_current = TRUE
WHERE customer_key > 0;


SELECT * FROM dim_customer
WHERE
	customer_id = 101;
    
SET SQL_SAFE_UPDATES = 0;

UPDATE dim_customer
SET
    effective_end_date = '2026-05-31',
    is_current = FALSE
WHERE customer_id = 101
AND is_current = TRUE;

SET SQL_SAFE_UPDATES = 1;


INSERT INTO dim_customer
(
    customer_id,
    customer_name,
    email,
    city,
    effective_start_date,
    effective_end_date,
    is_current
)

VALUES
(
    101,
    'Rahul Sharma',
    'rahul@gmail.com',
    'Mumbai',
    '2026-06-01',
    '9999-12-31',
    TRUE
);

SELECT * FROM dim_customer 
WHERE customer_id = 101;


-- SCD Type 3 

-- ALTER TABLE dim_customer
-- ADD COLUMN previous_city VARCHAR(100),
-- ADD COLUMN current_city VARCHAR(100);

-- UPDATE dim_customer
-- SET current_city = city
-- WHERE customer_key > 0;


-- UPDATE dim_customer
-- SET
--     previous_city = current_city,
--     current_city = 'Mumbai',
--     city = 'Mumbai'
-- WHERE customer_key = 1;


-- SELECT *
-- FROM dim_customer
-- WHERE customer_id = 101;


-- Implement SCD Type 1 

-- SELECT *
-- FROM dim_customer
-- WHERE customer_id = 101;

-- UPDATE dim_customer
-- SET city = 'Mumbai'
-- WHERE customer_key = 1;

-- SELECT
--     customer_id,
--     customer_name,
--     city
-- FROM dim_customer
-- WHERE customer_id = 101;


-- Reporting and Analysis

DESC fact_sales;

SELECT 
	SUM(total_amount) as total_sales
FROM
	fact_sales;
    
    
-- Sales By Product 

SELECT
	p.product_name,
    SUM(f.quantity) as total_quantity,
    SUM(f.total_amount) as total_sales
FROM
	fact_sales f 

JOIN dim_product p 
	ON f.product_key = p.product_key
GROUP BY p.product_name;


-- Sales by Region

SELECT
    r.city,
    SUM(f.total_amount) AS total_sales
FROM fact_sales f
JOIN dim_region r
    ON f.region_key = r.region_key
GROUP BY r.city;



-- Monthly Sales Report

SELECT
    t.month_name,
    t.year,
    SUM(f.total_amount) AS monthly_sales
FROM fact_sales f
JOIN dim_time t
    ON f.time_key = t.time_key
GROUP BY
    t.year,
    t.month,
    t.month_name
ORDER BY
    t.year,
    t.month;
    
-- Customer Purchase History

SELECT
    c.customer_name,
    c.city,
    SUM(f.total_amount) AS total_purchase
FROM fact_sales f
JOIN dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.customer_name,
    c.city;
    
