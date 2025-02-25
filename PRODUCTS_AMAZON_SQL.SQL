SELECT * FROM products_amazon.amazon;
desc amazon;
USE products_amazon;
/* Data Wrangling: This is the first step where inspection of data is done 
to make sure NULL values and missing values are detected and data replacement
 methods are used to replace missing or NULL values.
1. Build a database
2. Create a table and insert the data.
3. Select columns with null values in them. There are no null values in our database 
as in creating the tables, we set NOT  NULL for each field, hence null values are filtered out.*/
/* changing the columns names , data types and setting not null constraint to each feild*/
ALTER TABLE amazon
CHANGE COLUMN `Invoice ID` invoice_id VARCHAR(30) not null,
ADD PRIMARY KEY (invoice_id),
CHANGE COLUMN `Branch` branch VARCHAR(5) not null,
CHANGE COLUMN `City` city VARCHAR(30) NOT NULL,
CHANGE COLUMN `Customer type` customer_type VARCHAR(30) NOT NULL,
CHANGE COLUMN `Gender` gender VARCHAR(10) NOT NULL,
CHANGE COLUMN `Product line` product_line VARCHAR(100) NOT NULL,
CHANGE COLUMN `Unit price` unit_price DECIMAL(10, 2) NOT NULL,
CHANGE COLUMN `Quantity` quantity INT NOT NULL,
CHANGE COLUMN `Tax 5%` VAT FLOAT(6,4) NOT NULL,
CHANGE COLUMN `Total` total DECIMAL(12, 4) NOT NULL,
CHANGE COLUMN `Date` date DATETIME NOT NULL,
CHANGE COLUMN `Time` time TIME NOT NULL,
CHANGE COLUMN `Payment` payment_method  VARCHAR(15) NOT NULL,
CHANGE COLUMN `cogs` cogs DECIMAL(10, 2) NOT NULL,
CHANGE COLUMN `gross margin percentage` gross_margin_percentage FLOAT(11,9) NOT NULL,
CHANGE COLUMN `gross income` gross_income DECIMAL(12, 4) NOT NULL,
CHANGE COLUMN `Rating` rating FLOAT;
ALTER TABLE amazon
MODIFY `rating` FLOAT NOT NULL;
use products_amazon;
select invoice_id from amazon -- cheking the null values are there or not 
where invoice_id is not null; 

select invoice_id from amazon
where invoice_id is null; 
/* Feature Engineering: This will help us generate some new columns from existing
 ones.
1.1Add a new column named timeofday to give insight of sales in the Morning,
 Afternoon and Evening. This will help answer the question on which part of 
 the day most sales are made.
2.Add a new column named dayname that contains the extracted days of the week 
on which the given transaction took place (Mon, Tue, Wed, Thur, Fri).
 This will help answer the question on which week of the day each branch is busiest.
3 Add a new column named monthname that contains the extracted months
 of the year on which the given transaction took place (Jan, Feb, Mar). 
 Help determine which month of the year has the most sales and profit.*/
 select count(*) from amazon;
 SELECT * FROM products_amazon.amazon;

--------------------/*Feature Engineering*/--------------------
----/*timeofday */--
select time from amazon;
SELECT time,
     (CASE 
          WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning" 
          WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
          ELSE "Evening"
       END) AS  timeofday FROM amazon;
ALTER TABLE amazon ADD COLUMN timeofday VARCHAR(20);

UPDATE amazon 
SET timeofday = (CASE 
          WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning" 
          WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
          ELSE "Evening"
       END);
       
  ----/*dayname */--     
SELECT date FROM amazon;
SELECT date, DAYNAME(date) AS dayname  from amazon;
ALTER TABLE amazon ADD COLUMN dayname  VARCHAR(10);
UPDATE amazon 
SET dayname = DAYNAME(date);

----/*monthname*/-----
SELECT date,  MONTHNAME(date) from amazon;
 ALTER TABLE amazon ADD COLUMN monthname VARCHAR(10);
 UPDATE amazon 
 SET monthname = MONTHNAME(date);
 
ALTER TABLE amazon 
MODIFY timeofday varchar(20) NOT NULL,
MODIFY dayname varchar(10) NOT NULL,
MODIFY monthname varchar(10) NOT NULL; 
 /* 3. Exploratory Data Analysis (EDA): Exploratory data analysis
 is done to answer the listed questions and aims of this project.*/
--------/*Business Questions To Answer:*/------------ 
-- 1.What is the count of distinct cities in the dataset?
  SELECT COUNT(DISTINCT city) as count_city FROM amazon;
  
-- 2.For each branch, what is the corresponding city?--
SELECT DISTINCT branch,city  FROM amazon;

-- 3.What is the count of distinct product lines in the dataset? ------
SELECT COUNT(DISTINCT product_line) AS count_prctline FROM amazon;

--  4.Which payment method occurs most frequently?--
SELECT payment_method, COUNT(payment_method) AS frequent_method FROM amazon
GROUP BY payment_method
ORDER BY frequent_method desc;

-- 5.Which product line has the highest sales?---
SELECT product_line, COUNT(product_line) AS prdt_sale from amazon
GROUP BY product_line
ORDER BY prdt_sale DESC;

-- 6.How much revenue is generated each month?--
SELECT monthname, SUM(total) AS total_revenue FROM amazon
GROUP BY monthname;

-- 7. In which month did the cost of goods sold reach its peak?--
SELECT DISTINCT monthname, SUM(cogs) AS count_cogs FROM amazon
GROUP BY monthname
ORDER BY count_cogs DESC
LIMIT 1;

-- 8. Which product line generated the highest revenue? ---
SELECT product_line, SUM(total) AS highest_revenue from amazon 
GROUP BY product_line
ORDER BY highest_revenue desc
LIMIT 6;


-- 9.In which city was the highest revenue recorded?--
SELECT city, SUM(total) AS high_revenue FROM  amazon 
GROUP BY city
ORDER BY high_revenue desc
LIMIT 3;

-- 10. Which product line incurred the highest Value Added Tax?--
SELECT product_line, SUM(VAT) AS high_tax FROM amazon
GROUP BY product_line
ORDER BY high_tax desc
LIMIT 1;

-- 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."--
SELECT
    product_line,
    quantity,
    CASE
        WHEN quantity > avg_quantity THEN 'Good'
        ELSE 'Bad'
    END AS quantity_status
FROM (
    SELECT
        product_line,
        quantity,
        AVG(quantity) OVER () AS avg_quantity
    FROM
        amazon
) AS with_avg_quantity;

-- 12.Identify the branch that exceeded the average number of products sold.
SELECT branch, SUM(quantity)as sum_qty FROM  amazon
GROUP BY branch
HAVING SUM(quantity) >(SELECT AVG(quantity) FROM amazon);

-- 13. Which product line is most frequently associated with each gender?
SELECT  gender, product_line,count(gender) AS cnt_gender from amazon
GROUP BY gender, product_line
ORDER BY cnt_gender DESC;

-- 14.Calculate the average rating for each product line.
SELECT product_line, AVG(rating) as avg_rating FROM amazon
GROUP BY product_line
ORDER BY avg_rating;

-- 15. Count the sales occurrences for each time of day on every weekday.
SELECT dayname,timeofday,COUNT(quantity) AS sales FROM amazon
WHERE dayname in( "Monday", "Tuesday", "Wednesday","Thursday","Friday" )
GROUP BY dayname,timeofday 
ORDER BY dayname ;

-- 16.Identify the customer type contributing the highest revenue. 
SELECT customer_type,SUM(total) AS t_revenue   FROM amazon
GROUP BY customer_type
ORDER BY t_revenue DESC;

-- 17.Determine the city with the highest VAT percentage. 
SELECT city, AVG(VAT) AS h_vat FROM amazon 
GROUP BY city
ORDER BY h_vat desc;

-- 18. Identify the customer type with the highest VAT payments.
SELECT customer_type, round(SUM(VAT),2) AS count_vat FROM amazon
GROUP BY customer_type
ORDER BY count_vat DESC;

-- 19.What is the count of distinct customer types in the dataset?
SELECT COUNT(DISTINCT customer_type) AS count_cstmr FROM amazon;

-- 20.What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT payment_method) AS paymt_types FROM amazon;

-- 21.Which customer type occurs most frequently?
SELECT customer_type, COUNT(customer_type)AS cnt_cstype FROM amazon
GROUP BY customer_type
ORDER BY cnt_cstype DESC;

-- 22.Identify the customer type with the highest purchase frequency 
SELECT customer_type, COUNT(total) AS purchase FROM amazon
GROUP BY customer_type
ORDER BY purchase DESC;

-- 23. Determine the predominant gender among customers.
SELECT gender,COUNT(Customer_type) AS CNT FROM amazon
GROUP BY gender
ORDER BY CNT DESC;

-- 24.Examine the distribution of genders within each branch. 
SELECT  branch,COUNT(gender) AS m_f FROM amazon
GROUP BY branch;

-- 25.Identify the time of day when customers provide the most ratings. 
SELECT timeofday,AVG(rating) AS most_rating FROM amazon
GROUP BY timeofday
ORDER BY most_rating DESC;

-- 26. Determine the time of day with the highest customer 
-- ratings for each branch.
SELECT branch, timeofday,AVG(rating) AS h_rating FROM amazon
GROUP BY branch, timeofday
ORDER BY h_rating DESC;

-- 27.Identify the day of the week with the highest average ratings.
SELECT dayname, AVG(rating) AS avg_rating FROM amazon
GROUP BY dayname
ORDER BY avg_rating DESC;

-- 28.Determine the day of the week with the highest average ratings for each branch.
SELECT branch,dayname, AVG(rating) AS avg_rating FROM amazon
GROUP BY branch,dayname
ORDER BY avg_rating DESC;
