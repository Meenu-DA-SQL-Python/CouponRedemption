
--To Show the directory to load the data from csv file to table
SHOW VARIABLES LIKE 'secure_file_priv';

--Creting a temp table as the date format doesn't match the DB requirement 
Creating a temp table as the date are in different format(DD-MM-YYYY) in csv and the server accepts only (YYYY-MM-DD) 

CREATE TABLE temp_campaign_data (
    campaign_id INT,
    campaign_type CHAR(1),
    start_date VARCHAR(10),
    end_date VARCHAR(10),
    campaigning_days INT
);
--Load the file from CSV to DB
LOAD DATA INFILE '/usr/local/mysql-files/campaign_data.csv'
INTO TABLE temp_campaign_data 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

--Create table Original table for campaign_data
CREATE TABLE campaign_data (
    campaign_id INT PRIMARY KEY,
    campaign_type CHAR(1),  -- 'Y' or 'X' as per your example
    start_date DATE,
    end_date DATE,
    campaigning_days INT
);
--Insert table data from temp table to Original table
INSERT INTO campaign_data (campaign_id, campaign_type, start_date, end_date, campaigning_days)
SELECT 
    campaign_id,
    campaign_type,
    STR_TO_DATE(start_date, '%d-%m-%Y'),
    STR_TO_DATE(end_date, '%d-%m-%Y'),
    campaigning_days
FROM temp_campaign_data;

--Check the Count
select count(*) from campaign_data;
select count(*) from customer_demographics;

---Row count didn't match with the file for customer_demographics
TRUNCATE customer_demographics;

ALTER TABLE customer_demographics 
MODIFY COLUMN family_size VARCHAR(3);


LOAD DATA INFILE '/usr/local/mysql-files/customer_demographics.csv'
INTO TABLE customer_demographics 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select count(*) from customer_demographics;--Row count passed

---Truncate coupon_item_mapping

TRUNCATE coupon_item_mapping;

ALTER TABLE coupon_item_mapping
DROP PRIMARY KEY;


LOAD DATA INFILE '/usr/local/mysql-files/coupon_item_mapping.csv'
INTO TABLE coupon_item_mapping 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-----Create Customer transaction

CREATE TABLE customer_transactions (
    transaction_date DATE,
    customer_id INT,
    item_id INT,
    quantity INT,
    selling_price DECIMAL(10,2),
    other_discount DECIMAL(10,2),
    coupon_discount DECIMAL(10,2)
);


LOAD DATA INFILE '/usr/local/mysql-files/customer_transaction_data.csv'
INTO TABLE customer_demographics 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

ALTER TABLE customer_transactions MODIFY customer_id VARCHAR(20);--altering because of the error"Data truncated for column 'customer_id' at row "

LOAD DATA INFILE '/usr/local/mysql-files/customer_transaction_data.csv'  
INTO TABLE customer_transactions  
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n'  
IGNORE 1 LINES  
(transaction_date,customer_id, item_id, quantity, selling_price, other_discount, coupon_discount)
SET customer_id = TRIM(customer_id);


select count(*) from customer_transactions;--Row count passed


--Create Item_data

CREATE TABLE item_data (
    item_id INT PRIMARY KEY,  -- Unique ID for item
    brand VARCHAR(50),        -- Unique ID for item brand
    brand_type ENUM('Local', 'Established'), -- Brand Type (Local/Established)
    category VARCHAR(100)      -- Item Category
);

ALTER TABLE item_data 
MODIFY COLUMN category TEXT;


LOAD DATA  INFILE '/usr/local/mysql-files/item_data.csv'
INTO TABLE item_data
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select count(*) from item_data;

--Create train
ALTER TABLE coupon_item_mapping
ADD PRIMARY KEY (coupon_id);


ALTER TABLE coupon_item_mapping
ADD PRIMARY KEY (coupon_id);


desc coupon_item_mapping


CREATE TABLE train (
    id INT AUTO_INCREMENT PRIMARY KEY,               -- Unique id for coupon customer impression
    campaign_id INT NOT NULL,                        -- Unique id for a discount campaign
    coupon_id INT NOT NULL,                          -- Unique id for a discount coupon
    customer_id INT NOT NULL,                        -- Unique id for a customer
    redemption_status TINYINT(1) NOT NULL,           -- Redemption status (0 - Coupon not redeemed, 1 - Coupon redeemed)
    FOREIGN KEY (campaign_id) REFERENCES campaign_data(campaign_id),  -- Assuming the 'campaign_data' table exists
 -- Assuming the 'coupon_data' table exists
    FOREIGN KEY (customer_id) REFERENCES customer_demographics(customer_id)  -- Assuming the 'customer_data' table exists
);

SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'credemption' AND REFERENCED_TABLE_NAME ='train';

ALTER TABLE train
DROP FOREIGN KEY train_ibfk_3;



LOAD DATA  INFILE '/usr/local/mysql-files/train.csv'
INTO TABLE train
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


select concat( 'select count(*) as [Total Rows] from ', select TABLE_NAME
from INFORMATION_SCHEMA.TABLEs
where table_schema='credemption'
and table_type='BASE TABLE') ;

--- Check the count of all the tables added
SELECT CONCAT(
  'SELECT "', TABLE_NAME, '" AS table_name, COUNT(*) AS row_count FROM ', TABLE_NAME , ' Union'
) AS query
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'credemption'
  AND TABLE_TYPE = 'BASE TABLE';


SELECT "campaign_data" AS table_name, COUNT(*) AS row_count FROM campaign_data Union
SELECT "coupon_item_mapping" AS table_name, COUNT(*) AS row_count FROM coupon_item_mapping Union
SELECT "customer_demographics" AS table_name, COUNT(*) AS row_count FROM customer_demographics Union
SELECT "customer_transactions" AS table_name, COUNT(*) AS row_count FROM customer_transactions Union
SELECT "item_data" AS table_name, COUNT(*) AS row_count FROM item_data Union
SELECT "temp_campaign_data" AS table_name, COUNT(*) AS row_count FROM temp_campaign_data Union
SELECT "train" AS table_name, COUNT(*) AS row_count FROM train    