-- create table in db
CREATE TABLE public.credit_card_transaction (
    index INT,
    trans_date TIMESTAMP,
    credit_card_number NUMERIC,
    merchant VARCHAR(100),
    category VARCHAR(50),
    amount NUMERIC,
    first_name VARCHAR(30),
    last_name VARCHAR(30),
    gender TEXT,
    street VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(20),
    zip INT,
    latitute NUMERIC,
    longitude NUMERIC,
    city_pop NUMERIC,
    job TEXT,
    d_o_b DATE,
    transaction_number VARCHAR(32),
    unix_time INT,
    merchant_latitude NUMERIC,
    merchant_longitude NUMERIC,
    is_fraud BOOLEAN,
    merchant_zip_code NUMERIC
);


-- Set ownership of the tables to the postgres user
ALTER TABLE public.credit_card_transaction OWNER to postgres;


--load the csv files
COPY credit_card_transaction
FROM 'C:\Users\user\Desktop\QA\SQL_personal_practise\Finance\credit_card\csv_file\credit_card_transactions.csv' 
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');


--use this
\copy credit_card_transaction FROM 'C:\Users\user\Desktop\QA\SQL_personal_practise\Finance\credit_card\csv_file\credit_card_transactions.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

SELECT * from credit_card_transaction
LIMIT 10