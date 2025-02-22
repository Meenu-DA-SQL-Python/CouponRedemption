//To Show the directory to load the data from csv file to table
SHOW VARIABLES LIKE 'secure_file_priv'
//Creating a temp table as the date are in different format(DD-MM-YYYY) in csv and the server accepts only (YYYY-MM-DD) 


CREATE TABLE temp_campaign_data (
    campaign_id INT,
    campaign_type CHAR(1),
    start_date VARCHAR(10),
    end_date VARCHAR(10),
    campaigning_days INT
);

LOAD DATA INFILE '/usr/local/mysql-files/campaign_data.csv'
INTO TABLE temp_campaign_data 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

CREATE TABLE campaign_data (
    campaign_id INT PRIMARY KEY,
    campaign_type CHAR(1), 
    start_date DATE,
    end_date DATE,
    campaigning_days INT
);

INSERT INTO campaign_data (campaign_id, campaign_type, start_date, end_date, campaigning_days)
SELECT 
    campaign_id,
    campaign_type,
    STR_TO_DATE(start_date, '%d-%m-%Y'),
    STR_TO_DATE(end_date, '%d-%m-%Y'),
    campaigning_days
FROM temp_campaign_data;

select count(*) from campaign_data

