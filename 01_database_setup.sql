CREATE DATABASE corporate_sales_analytics_db;
USE corporate_sales_analytics_db;


SELECT * FROM superstore_raw;


-- create customers table from superstore_raw table
CREATE TABLE customers(
customer_id VARCHAR(40) PRIMARY KEY,
customer_name VARCHAR(90),
segment varchar(70)
);

INSERT INTO customers
SELECT DISTINCT Customer_ID ,
    Customer_Name,
    Segment
FROM superstore_raw;

SELECT * FROM customers;


-- products table
CREATE TABLE products(
product_id VARCHAR(40) PRIMARY KEY,
product_name VARCHAR(150),
category VARCHAR(50),
sub_category VARCHAR(60)
);

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT product_id, product_name, category, sub_category
FROM (
    SELECT 
        Product_ID,
        Product_Name,
        Category,
        Sub_Category,
        ROW_NUMBER() OVER 
        (
            PARTITION BY Product_ID 
            ORDER BY Product_Name DESC
        ) 
        as row_num
    FROM superstore_raw
) AS ranked_products
WHERE row_num = 1;

select * from products;


-- locations table
CREATE TABLE locations (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(60),
    country VARCHAR(50),
    market VARCHAR(40),
    region VARCHAR(30)
);

INSERT INTO locations (city, state, country, market, region)
SELECT DISTINCT City,
    State,
    Country,
    Market,
    Region
FROM superstore_raw;

SELECT * FROM locations;


-- orders table
CREATE TABLE orders (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(30),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),

    customer_id VARCHAR(40),
    product_id VARCHAR(40),
    location_id INT,

    sales DECIMAL(18,2),
    quantity INT,
    discount DECIMAL(10,4),
    profit DECIMAL(18,2),
    shipping_cost DECIMAL(18,2),

    order_priority VARCHAR(50),

    CONSTRAINT FK_orders_customer_id
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT FK_orders_product_id
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT FK_orders_location_id
        FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
);

INSERT INTO orders( row_id, order_id, order_date, ship_date, ship_mode, customer_id,
                product_id, location_id, sales, quantity, discount, profit,
                shipping_cost, order_priority)
SELECT
    sr.[Row_ID],
    sr.[Order_ID],
    TRY_CONVERT(DATE, sr.[Order_Date], 105),
    TRY_CONVERT(DATE, sr.[Ship_Date], 105),
    sr.[Ship_Mode],
    sr.[Customer_ID],
    sr.[Product_ID],
    l.location_id,
    sr.Sales,
    sr.Quantity,
    sr.Discount,
    sr.Profit,
    sr.[Shipping_Cost],
    sr.[Order_Priority]
FROM superstore_raw sr
JOIN locations l
    ON sr.City = l.city
    AND sr.State = l.state
    AND sr.Country = l.country
    AND sr.Market = l.market
    AND sr.Region = l.region;

SELECT * FROM orders;

CREATE INDEX idx_orders_order_date
ON orders(order_date);

CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_orders_product
ON orders(product_id);

CREATE INDEX idx_orders_sales
ON orders(sales);

