-- create column to hold the transaction date and transaction time
ALTER TABLE credit_card_transaction
ADD COLUMN tranx_date DATE,
ADD COLUMN trans_time TIME;


--split the trans_date column into date and time components
UPDATE credit_card_transaction
SET tranx_date = trans_date::DATE;

UPDATE credit_card_transaction
SET trans_time = trans_date::TIME;

SELECT * from credit_card_transaction
order by trans_time_stamp DESC
LIMIT 10;

--rename the initial column for clarity
ALTER TABLE credit_card_transaction
RENAME COLUMN trans_date to trans_time_stamp;


--add column to hold customer age
ALTER TABLE credit_card_transaction
ADD COLUMN customer_age INT;


--calculate customer age at the time of transaction
UPDATE credit_card_transaction
SET customer_age = DATE_PART('year', age(tranx_date, d_o_b));


SELECT column_name
FROM information_schema.columns
where table_schema = 'public' and table_name = 'credit_card_transaction';

/*to view the metadata (read only) of a database, you canquery the information schema.
It contains tables, schemata, columns, constraints and table constraints.
for example: 
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;
SELECT * FROM INFORMATION_SCHEMA.TABLES;
SELECT * FROM INFORMATION_SCHEMA.SCHEMATA;
SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS; */

--Calculate mean, median, and standard deviation for amount to set a max amount
--cc with frequent transaction


--total merchants in the dataset
select count(distinct merchant)
from credit_card_transaction;

--total categories
select
    DISTINCT category,
    count (*) AS total_transaction
FROM
    credit_card_transaction
GROUP BY category

--rename latitude to the correct spelling
ALTER TABLE credit_card_transaction
RENAME COLUMN latitute TO latitude;


select count(*) from credit_card_transaction
where tranx_date >= '2020-01-01'