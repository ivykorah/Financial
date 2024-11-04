/*
On average, credit card fraud rings typically operate on a group of 
compromised accounts for about 3 to 6 months before moving on, 
although this can vary widely based on detection and response times. 
This analysis will be focusing on the latest 6 months data
The data is between 01.01.2019 and 06.2020.
So analysis will focus on 01.01.2020 to 06.2020*/


-- 1 what customers had the highest daily transaction frequency, and total for the  6 months.  This can help detect annolamies in transactions 
SELECT 
    credit_card_number,
    (COUNT(first_name) / (DATE '2020-06-21' - DATE '2020-01-01')) AS avg_daily_trans_freq,
    sum(amount) as total_trans_amt
FROM
    credit_card_transaction
where tranx_date >= (DATE '2020-01-01')
GROUP BY credit_card_number
order BY avg_daily_trans_freq DESC;


--2 people that did an average of 5 and 4 transactions per day, to what merchants?
WITH merchant_analysis AS (
    SELECT 
        credit_card_number,
        (COUNT(first_name) / (DATE '2020-06-21' - DATE '2020-01-01')) AS avg_daily_trans_freq,
        sum(amount) as total_trans_amt
    FROM
        credit_card_transaction
    where tranx_date >= (DATE '2020-01-01')
    GROUP BY credit_card_number
    --order BY avg_daily_trans_freq DESC
)

SELECT 
    m.credit_card_number,
    c.merchant,
    sum(c.amount) AS total_amt_spent,
    count(c.merchant) as times_patronised
from merchant_analysis m
inner join credit_card_transaction c ON m.credit_card_number = c.credit_card_number
where m.avg_daily_trans_freq >= 4
Group BY m.credit_card_number, c.merchant
ORDER BY times_patronised DESC, total_amt_spent DESC
LIMIT 20;


--3 which merchants were patronised rapidly within a day or less (hours) and the transaction was more than 2times.
SELECT 
    credit_card_number,
    merchant,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount_spent,
    MAX(tranx_date) - MIN(tranx_date) AS active_days
FROM 
    credit_card_transaction
WHERE tranx_date >= '2020-01-01'
GROUP BY credit_card_number, merchant
HAVING count(*) >= 2 AND (MAX(tranx_date) - MIN(tranx_date)) <=1
ORDER BY transaction_count DESC, total_amount_spent DESC
--LIMIT 25;



--4 for those merchants above with amount over 1000, what category of items are they selling to justify the multiple purchase/amount
WITH multiple_purchase AS (
    SELECT 
        credit_card_number,
        merchant,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount_spent,
        MAX(tranx_date) - MIN(tranx_date) AS active_days
    FROM credit_card_transaction
    WHERE tranx_date >= '2020-01-01'
    GROUP BY credit_card_number, merchant
    HAVING count(*) >= 2 AND (MAX(tranx_date) - MIN(tranx_date)) <=1
)

SELECT 
    m.merchant,
    m.credit_card_number,
    m.total_amount_spent,
    c.category
FROM 
    multiple_purchase m 
INNER JOIN 
    credit_card_transaction c ON m.merchant = c.merchant
WHERE 
    m.total_amount_spent >= 1000
GROUP BY m.credit_card_number, m.merchant, c.category, m.total_amount_spent


--5 for those merchant with high value above (over 1k spent), how far is the merchant from the customer? this can indicate some sus activities

WITH multiple_purchase AS (
    SELECT 
        credit_card_number,
        merchant,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount_spent,
        MAX(tranx_date) - MIN(tranx_date) AS active_days,
        MIN(latitude) AS customer_latitude,
        MIN(longitude) AS customer_longitude,
        MIN(merchant_latitude) AS merchant_latitude,
        MIN(merchant_longitude) AS merchant_longitude
    FROM credit_card_transaction
    WHERE tranx_date >= '2020-01-01'
    GROUP BY credit_card_number, merchant
    HAVING count(*) >= 2
        AND (MAX(tranx_date) - MIN(tranx_date)) <= 1 
        AND SUM(amount) >= 1000
)

SELECT
    m.credit_card_number,
    m.merchant,
    m.transaction_count,
    m.total_amount_spent,
    (6371 * ACOS(
        COS(RADIANS(customer_latitude)) * COS(RADIANS(merchant_latitude)) * 
        COS(RADIANS(merchant_longitude) - RADIANS(customer_longitude)) + 
        SIN(RADIANS(customer_latitude)) * SIN(RADIANS(merchant_latitude))
    )) AS distance_km
FROM multiple_purchase m 
ORDER BY distance_km DESC;


--6 To further see if this analysis was correct, I want to see the column that confirms if the transaction is fraudulent or not for each of the above transactions I suspect

WITH multiple_purchase AS (
    SELECT 
        credit_card_number,
        merchant,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount_spent,
        MAX(tranx_date) - MIN(tranx_date) AS active_days,
        MIN(latitude) AS customer_latitude,
        MIN(longitude) AS customer_longitude,
        MIN(merchant_latitude) AS merchant_latitude,
        MIN(merchant_longitude) AS merchant_longitude,
        is_fraud
    FROM credit_card_transaction
    WHERE tranx_date >= '2020-01-01'
    GROUP BY credit_card_number, merchant, is_fraud
    HAVING count(*) >= 2
        AND (MAX(tranx_date) - MIN(tranx_date)) <= 1 
        AND SUM(amount) >= 1000
)

SELECT
    m.credit_card_number,
    m.merchant,

    (6371 * ACOS(
        COS(RADIANS(customer_latitude)) * COS(RADIANS(merchant_latitude)) * 
        COS(RADIANS(merchant_longitude) - RADIANS(customer_longitude)) + 
        SIN(RADIANS(customer_latitude)) * SIN(RADIANS(merchant_latitude))
    )) AS distance_km,
    is_fraud
FROM multiple_purchase m
ORDER BY distance_km DESC;


--7 Identifying High-Risk Age Groups according to the full dataset. Fraud can be more prevalent among certain age groups. You can analyze the fraud rate by age.

--max and min age in the dataset
SELECT 
    MAX(customer_age) as max_age,
    MIN(customer_age) AS min_age
FROM credit_card_transaction
/* maximum customer age is 95 and minimun is 13. We want 5 bins as below
 - 13-29: Youth
 - 30-49: Adult
 - 50-69: Advanced
 - 70-79: Old
 - 80-100: Very Old*/


--create bins and return age bin, count of is_fraud, total transaction for each age bin, percentage fraud
WITH fraud_calc AS (
    SELECT
        CASE
            WHEN customer_age BETWEEN 13 AND 29 THEN 'Youth'
            WHEN customer_age BETWEEN 30 AND 49 THEN 'Adult'
            WHEN customer_age BETWEEN 50 AND 69 THEN 'Advanced'
            WHEN customer_age BETWEEN 70 AND 79 THEN 'Old'
        ELSE
            'Very Old'
        END AS age_group,
        COUNT(CASE WHEN is_fraud = 'TRUE' THEN 1 END) AS fraud_count,
        COUNT(*) AS total_count
    FROM credit_card_transaction
    GROUP BY age_group
)

SELECT
    age_group,
    fraud_count,
    total_count,
    (fraud_count / total_count :: NUMERIC)*100 AS fraud_percentage
FROM 
    fraud_calc
ORDER BY fraud_percentage DESC;
