-- Create the tables before importing the csv files
-- Due to constraints from the data source, I was only provided with a separate csv files with the transactions per 4 month period between July 2019 to October 2021

CREATE TABLE OCS_sales_Jul_Oct_2019 (
	sales_channel VARCHAR(50) NOT NULL,
	category VARCHAR (50) NOT NULL,
	sub_category VARCHAR (50) NOT NULL,
	supplier VARCHAR (100) NOT NULL,
	brand VARCHAR (100) NOT NULL,
	item_name VARCHAR (200) NOT NULL,
	sku VARCHAR (50) NOT NULL,
	region VARCHAR (50),
	sales NUMERIC NOT NULL,
	sales_units INTEGER NOT NULL,
	ocs_price NUMERIC NOT NULL,
	thc_range VARCHAR (50) NOT NULL, 
	cbd_range VARCHAR (50) NOT NULL,
	species VARCHAR (50) NOT NULL,
	format NUMERIC NOT NULL,
	units_pack SMALLINT,
	UPC BIGINT,
	terp_1 VARCHAR (100),
	terp_2 VARCHAR (100),
	terp_3 VARCHAR (100),
	terp_4 VARCHAR (100),
	terp_5 VARCHAR (100),
	trans_date DATE NOT NULL,
	vendor_id INTEGER NOT NULL
);

CREATE TABLE ocs_sales_nov_feb_2020
AS TABLE ocs_sales_jul_oct_2019
WITH NO DATA
;

CREATE TABLE ocs_sales_mar_jun_2020
AS TABLE ocs_sales_jul_oct_2019
WITH NO DATA
;

CREATE TABLE ocs_sales_jul_oct_2020
AS TABLE ocs_sales_jul_oct_2019
WITH NO DATA
;

CREATE TABLE ocs_sales_nov_feb_2021
AS TABLE ocs_sales_jul_oct_2019
WITH NO DATA
;

CREATE TABLE ocs_sales_mar_jun_2021
AS TABLE ocs_sales_jul_oct_2019
WITH NO DATA

;

CREATE TABLE ocs_sales_jul_oct_2021
AS TABLE ocs_sales_jul_oct_2019
WITH NO DATA

;

-- Import csv files
-- Merge all tables into one single OCS sales table. This will contain all the 

CREATE TABLE ocs_sales
AS
	SELECT * FROM ocs_sales_jul_oct_2019
		UNION ALL
	SELECT * FROM ocs_sales_nov_feb_2020
		UNION ALL
	SELECT * FROM ocs_sales_mar_jun_2020
		UNION ALL
	SELECT * FROM ocs_sales_jul_oct_2020
		UNION ALL
	SELECT * FROM ocs_sales_nov_feb_2021
		UNION ALL
	SELECT * FROM ocs_sales_mar_jun_2021
		UNION ALL
	SELECT * FROM ocs_sales_jul_oct_2021
;

-- Simple queries to verify the integrity of the new ocs_sales table

SELECT * FROM ocs_sales
SLECT COUNT(*) FROM ocs_sales

-- To avoid confusion, drop all individual 4-monthly table

DROP TABLE 
	ocs_sales_jul_oct_2019,
	ocs_sales_nov_feb_2020,
	ocs_sales_mar_jun_2020,
	ocs_sales_jul_oct_2020,
	ocs_sales_nov_feb_2021,
	ocs_sales_mar_jun_2021,
	ocs_sales_jul_oct_2021

-- Add a serial primary key into the OCS sales table to identify every individual transaction

ALTER TABLE ocs_sales
ADD COLUMN trans_id SERIAL PRIMARY KEY

-- Get the average price per gram (ppg) by brand

SELECT brand, ROUND((AVG ((sales/sales_units)/format)),2) AS ppg
FROM ocs_sales
GROUP BY brand
ORDER BY ppg DESC

-- See the average ppg by brand in Q3 2021

SELECT brand, ROUND((AVG ((sales/sales_units)/format)),2) AS ppg
FROM ocs_sales
WHERE trans_date > '2021-07-01' AND trans_date < '2021-09-30'
GROUP BY brand
ORDER BY ppg DESC

-- See the average ppg by sales channel in Q3 2021

SELECT sales_channel, ROUND((AVG ((sales/sales_units)/format)),2) AS ppg
FROM ocs_sales
WHERE trans_date > '2021-07-01' AND trans_date < '2021-09-30'
GROUP BY sales_channel
ORDER BY ppg DESC

-- Get the share of each sales channel in Q3 2021

SELECT sales_channel,
	ROUND ((SUM(sales) * 100.0 / SUM(SUM(sales)) OVER ()), 2) AS percentage
FROM ocs_sales
WHERE trans_date > '2021-07-01' AND trans_date < '2021-09-30'
GROUP BY sales_channel
ORDER BY percentage DESC

-- Price segmentation is defined as follows (all values are in ppg):
-- Ultra Premium = 13+ , Super Premium 10-12.99, Premium 7.50-9.99, Value 6-7.49, Super Discount 4-5.99

-- Get the concentration of transactions per segment for Q3 2021

SELECT 
	SUM(CASE WHEN (ocs_price/format) BETWEEN 4 AND 5.99 THEN 1 ELSE 0 END) as super_discount,
	SUM(CASE WHEN (ocs_price/format) BETWEEN 6 AND 7.49 THEN 1 ELSE 0 END) as value,
	SUM(CASE WHEN (ocs_price/format) BETWEEN 7.50 AND 9.99 THEN 1 ELSE 0 END) as premium,
	SUM(CASE WHEN (ocs_price/format) BETWEEN 10 AND 12.99 THEN 1 ELSE 0 END) as super_premium,
	SUM(CASE WHEN (ocs_price/format) > 13 THEN 1 ELSE 0 END) as ultra_premium
FROM ocs_sales
WHERE trans_date > '2021-07-01' AND trans_date < '2021-09-30'

-- Get the the total sales per segment for Q3 2021
SELECT 
	(SELECT ROUND (SUM(sales), 2) AS super_discount 
		FROM ocs_sales
		WHERE (ocs_price/format) BETWEEN 4 AND 5.99 
		AND trans_date > '2021-07-01' AND trans_date < '2021-09-30'),
	(SELECT ROUND (SUM(sales), 2) AS value 
		FROM ocs_sales
		WHERE (ocs_price/format) BETWEEN 6 AND 7.49 
		AND trans_date > '2021-07-01' AND trans_date < '2021-09-30'),
	(SELECT ROUND (SUM(sales), 2) AS premium 
		FROM ocs_sales
		WHERE (ocs_price/format) BETWEEN 7.50 AND 9.99 
		AND trans_date > '2021-07-01' AND trans_date < '2021-09-30'),
	(SELECT ROUND (SUM(sales), 2) AS super_premium 
		FROM ocs_sales
		WHERE (ocs_price/format) BETWEEN 10 AND 12.99 
		AND trans_date > '2021-07-01' AND trans_date < '2021-09-30'),
	(SELECT ROUND (SUM(sales), 2) AS ultra_premium 
		FROM ocs_sales
		WHERE (ocs_price/format) >= 13
		AND trans_date > '2021-07-01' AND trans_date < '2021-09-30')

