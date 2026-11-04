# Building a Data Warehouse with Star Schema

## 📌 Project Overview

This project focuses on designing and implementing a Data Warehouse using the **Star Schema** architecture in MySQL.

The main objective is to organize transactional data into Fact and Dimension tables to support efficient data analysis, historical tracking, and business reporting.

The project also demonstrates the implementation of Slowly Changing Dimensions (SCD) Types 1, 2, and 3 to manage changes in customer information over time.

## 🎯 Objectives

- Design a Data Warehouse using Star Schema.
- Create Fact and Dimension tables in MySQL.
- Establish relationships using Primary Keys and Foreign Keys.
- Load transactional data into the Fact Table.
- Load descriptive data into Dimension Tables.
- Implement SCD Types 1, 2, and 3.
- Perform business analysis using SQL queries.

## 🛠️ Technologies Used

- **Database:** MySQL
- **Database Tool:** MySQL Workbench
- **Language:** SQL
- **Architecture:** Star Schema
- **Concepts:** Data Warehousing, ETL, Fact Tables, Dimension Tables, Slowly Changing Dimensions

## ⭐ Star Schema Architecture

The Star Schema consists of one central Fact Table connected to four Dimension Tables.

### Dimension Tables

| Table Name | Description |
|---|---|
| dim_time | Stores date, day, month, quarter, and year information |
| dim_region | Stores city, state, and country information |
| dim_product | Stores product name, category, and brand |
| dim_customer | Stores customer name, email, and location details |

### Fact Table

| Table Name | Description |
|---|---|
| fact_sales | Stores sales transactions, quantity, sales amount, discounts, and total amount |

### Database Structure

```text
                 dim_time
                    |
                    |
dim_region ---- fact_sales ---- dim_product
                    |
                    |
               dim_customer
```

## 🗄️ Database Implementation

### Step 1: Create Database

```sql
CREATE DATABASE sales_datawarehouse;

USE sales_datawarehouse;
```

### Step 2: Create Dimension Tables

**1. Time Dimension**

```sql
CREATE TABLE dim_time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT
);
```

**2. Region Dimension**

```sql
CREATE TABLE dim_region (
    region_key INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100)
);
```

**3. Product Dimension**

```sql
CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(100),
    category VARCHAR(100),
    brand VARCHAR(100)
);
```

**4. Customer Dimension**

```sql
CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(100)
);
```

### Step 3: Create Fact Table

```sql
CREATE TABLE fact_sales (
    sales_key INT AUTO_INCREMENT PRIMARY KEY,

    time_key INT,
    region_key INT,
    product_key INT,
    customer_key INT,

    order_id INT,
    quantity INT,
    sales_amount DECIMAL(12,2),
    discount_amount DECIMAL(12,2),
    total_amount DECIMAL(12,2),

    FOREIGN KEY (time_key)
        REFERENCES dim_time(time_key),

    FOREIGN KEY (region_key)
        REFERENCES dim_region(region_key),

    FOREIGN KEY (product_key)
        REFERENCES dim_product(product_key),

    FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key)
);
```

## 📥 Data Loading

Sample data is inserted into the Dimension Tables before loading sales transactions into the Fact Table.

### Step 4: Insert Dimension Data

**Time Data**

```sql
INSERT INTO dim_time
(time_key, full_date, day, month, month_name, quarter, year)
VALUES
(20260101, '2026-01-01', 1, 1, 'January', 1, 2026),
(20260102, '2026-01-02', 2, 1, 'January', 1, 2026),
(20260201, '2026-02-01', 1, 2, 'February', 1, 2026),
(20260301, '2026-03-01', 1, 3, 'March', 1, 2026);
```

**Region Data**

```sql
INSERT INTO dim_region (city, state, country)
VALUES
('Pune', 'Maharashtra', 'India'),
('Mumbai', 'Maharashtra', 'India'),
('Delhi', 'Delhi', 'India'),
('Bangalore', 'Karnataka', 'India');
```

**Product Data**

```sql
INSERT INTO dim_product
(product_id, product_name, category, brand)
VALUES
(501, 'Laptop', 'Electronics', 'Dell'),
(502, 'Mobile', 'Electronics', 'Samsung'),
(503, 'Headphones', 'Accessories', 'Sony'),
(504, 'Keyboard', 'Accessories', 'Logitech');
```

**Customer Data**

```sql
INSERT INTO dim_customer
(customer_id, customer_name, email, city)
VALUES
(101, 'Rahul Sharma', 'rahul@gmail.com', 'Pune'),
(102, 'Priya Patil', 'priya@gmail.com', 'Mumbai'),
(103, 'Amit Verma', 'amit@gmail.com', 'Delhi'),
(104, 'Sneha Rao', 'sneha@gmail.com', 'Bangalore');
```

### Step 5: Load Transactional Data into Fact Table

The following query loads sales transactions by joining the source transaction data with the Dimension Tables.

```sql
INSERT INTO fact_sales (
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

FROM (
    SELECT
        1001 AS order_id,
        '2026-01-01' AS sale_date,
        101 AS customer_id,
        501 AS product_id,
        1 AS quantity,
        50000.00 AS sales_amount,
        2000.00 AS discount_amount

    UNION ALL

    SELECT
        1002, '2026-01-02', 102, 502,
        2, 30000.00, 1000.00

    UNION ALL

    SELECT
        1003, '2026-02-01', 103, 503,
        1, 3000.00, 0.00

    UNION ALL

    SELECT
        1004, '2026-03-01', 104, 504,
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
```

## 🔄 Slowly Changing Dimensions (SCD)

Slowly Changing Dimensions are techniques used in Data Warehousing to manage changes in dimension data over time.

This project demonstrates three types of SCD.

### 1. SCD Type 1 – Overwrite Existing Data

SCD Type 1 replaces old information with new information without maintaining historical records.

**Example:** Updating a customer's city from Pune to Mumbai.

```sql
UPDATE dim_customer
SET city = 'Mumbai'
WHERE customer_key = 1;
```

**Result:**
- Old city is overwritten.
- No new record is created.
- Historical changes are not maintained.

### 2. SCD Type 2 – Maintain Full History

SCD Type 2 maintains historical records by creating a new record whenever a dimension attribute changes.

**Add tracking columns:**

```sql
ALTER TABLE dim_customer
ADD COLUMN effective_start_date DATE,
ADD COLUMN effective_end_date DATE,
ADD COLUMN is_current BOOLEAN;
```

**Initialize existing records:**

```sql
UPDATE dim_customer
SET
    effective_start_date = '2026-01-01',
    effective_end_date = '9999-12-31',
    is_current = TRUE
WHERE customer_key > 0;
```

**Step 1: Expire the old record**

```sql
UPDATE dim_customer
SET
    effective_end_date = '2026-05-31',
    is_current = FALSE
WHERE customer_key = 1
AND is_current = TRUE;
```

**Step 2: Insert a new customer record**

```sql
INSERT INTO dim_customer (
    customer_id,
    customer_name,
    email,
    city,
    effective_start_date,
    effective_end_date,
    is_current
)
VALUES (
    101,
    'Rahul Sharma',
    'rahul@gmail.com',
    'Mumbai',
    '2026-06-01',
    '9999-12-31',
    TRUE
);
```

**Result:**
- Old customer record is preserved.
- A new record is created with a new surrogate key.
- Historical changes can be tracked.

### 3. SCD Type 3 – Maintain Previous and Current Values

SCD Type 3 stores the current value and previous value in separate columns.

**Add tracking columns:**

```sql
ALTER TABLE dim_customer
ADD COLUMN previous_city VARCHAR(100),
ADD COLUMN current_city VARCHAR(100);
```

**Initialize current city:**

```sql
UPDATE dim_customer
SET current_city = city
WHERE customer_key > 0;
```

**Update customer city:**

```sql
UPDATE dim_customer
SET
    previous_city = current_city,
    current_city = 'Mumbai',
    city = 'Mumbai'
WHERE customer_key = 1;
```

**Result:**

| Customer | Previous City | Current City |
|---|---|---|
| Rahul Sharma | Pune | Mumbai |

- Previous value is maintained.
- Current value is updated.
- No new customer record is created.

**Note:** SCD Types 1, 2, and 3 are alternative strategies for handling changes. They should be demonstrated independently when applied to the same attribute. The SQL examples above illustrate each technique.

## 📊 SQL Reporting and Analysis

After loading data into the Data Warehouse, the following queries can be used for business reporting.

### 1. Total Sales

```sql
SELECT SUM(total_amount) AS total_sales
FROM fact_sales;
```

### 2. Sales by Product

```sql
SELECT
    p.product_name,
    SUM(f.quantity) AS total_quantity,
    SUM(f.total_amount) AS total_sales
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
GROUP BY p.product_name;
```

### 3. Sales by Region

```sql
SELECT
    r.city,
    SUM(f.total_amount) AS total_sales
FROM fact_sales f
JOIN dim_region r
    ON f.region_key = r.region_key
GROUP BY r.city;
```

### 4. Monthly Sales Report

```sql
SELECT
    t.month_name,
    t.year,
    SUM(f.total_amount) AS monthly_sales
FROM fact_sales f
JOIN dim_time t
    ON f.time_key = t.time_key
GROUP BY t.year, t.month, t.month_name
ORDER BY t.year, t.month;
```

### 5. Customer Purchase Analysis

```sql
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
```

## 📁 Project Structure

```text
Building-a-Data-Warehouse/
│
├── README.md
│
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_dimension_tables.sql
│   ├── 03_create_fact_table.sql
│   ├── 04_insert_dimension_data.sql
│   ├── 05_load_fact_data.sql
│   ├── 06_scd_type_1.sql
│   ├── 07_scd_type_2.sql
│   ├── 08_scd_type_3.sql
│   └── 09_reporting_queries.sql
│
└── screenshots/
    ├── star_schema.png
    ├── dimension_tables.png
    ├── fact_table.png
    └── reporting_results.png
```

## ✅ Key Learnings

- Understanding Data Warehouse Architecture.
- Designing Star Schema.
- Creating Fact and Dimension Tables.
- Implementing Primary Keys and Foreign Keys.
- Loading transactional and descriptive data.
- Understanding and implementing SCD Types 1, 2, and 3.
- Writing SQL queries for business reporting and analysis.

## 🚀 Conclusion

Successfully designed and implemented a Sales Data Warehouse using MySQL and Star Schema architecture.

The project demonstrates how transactional data can be transformed into an analytical database for efficient reporting, business insights, and historical data management.

---

**Project Name:** Building a Data Warehouse with Star Schema  
**Database:** MySQL  
**Architecture:** Star Schema  
**Focus:** Data Warehousing, SQL, ETL, and Slowly Changing Dimensions
