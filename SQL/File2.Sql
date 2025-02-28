--1 Coupons Redember by Customer or not for any Campaign id
select COUNT(distinct campaign_id) from campaign_data;
select distinct redemption_status from train;--1-Redemed,0-Not Redemed

with Coupon_not_Red as (
select distinct  
cd.campaign_id campaign_id
from campaign_data cd
where cd.campaign_id not in (select distinct campaign_id from train))
select 
cd.campaign_id
,count(distinct train.customer_id)
,'Yes' as 'Customer Redemded?'
from campaign_data cd
inner join train train on cd.campaign_id=train.campaign_id 
group by campaign_id
union 
select 
cd.campaign_id
,count(distinct train.customer_id)
,'No' as 'Customer Redemded?'
from campaign_data cd
inner join coupon_not_Red cnr on cd.campaign_id=cnr.campaign_id 
left join train train on cd.campaign_id=train.campaign_id 
group by campaign_id
order by campaign_id;

--1.Find the number of coupons redeemed per campaign and the percentage of Coupon Redeemed 
--Solution: Use GROUP BY with COUNT and GROUP_CONCAT on campaign_id and redemption_status.

SELECT 
    campaign_id 
    COUNT(DISTINCT coupon_id) AS distinct_coupon_count,
    COUNT(coupon_id)   CouponDistributed,
    COUNT(CASE WHEN redemption_status=1 THEN 1 END) Redeemed,
    COUNT(CASE WHEN redemption_status=0 THEN 1 END) NotRRedeemed,
    (COUNT(CASE WHEN redemption_status=1 THEN 1 END)/COUNT(coupon_id)) *100 '% of Coupon Redeemed'
 FROM train
GROUP BY campaign_id;


--2.	List customers who have never redeemed a coupon.
--o	Solution: Use LEFT JOIN between train.csv and customer_id, then filter out redemption_status = 1.

select * from 
    (select
    CD.customer_id,
    CASE 
                WHEN COUNT(DISTINCT tr.campaign_id) = 0 THEN 'NeverParticipated' 
                ELSE 'Participated' 
            END AS ParticipationStatus,
    count(DISTINCT tr.campaign_id) as campaignParticipated ,
    group_concat(distinct campaign_id),
    count(coupon_id)  CouponProvided,
    COUNT(CASE WHEN redemption_status=1 THEN coupon_id END) Redeemed,
    COUNT(CASE WHEN redemption_status=0 THEN coupon_id END) NotRedeemed,
    COUNT(CASE WHEN redemption_status=1 THEN coupon_id END)/COUNT(coupon_id)) *100 Per_of_Coupon_Redeemed
from  customer_demographics CD
left join train tr on tr.customer_id=CD.customer_id
group by CD.customer_id )  Subquery
order by Subquery.campaignParticipated asc , Per_of_Coupon_Redeemed desc;

-- found not all customer in train has information in customer demographics. So adding random data to the customer demographics
select distinct customer_id
from train t where not exists 
(select 1 from customer_demographics cd where cd.customer_id=t.customer_id);

select distinct no_of_children  from customer_demographics as cd;

update  customer_demographics
set no_of_children='3'
where no_of_children='3+';

ALTER TABLE customer_demographics  
ADD COLUMN from_Kaggle VARCHAR(10) NOT NULL DEFAULT 'Yes';

LOAD DATA INFILE '/usr/local/mysql-files/synthetic_customer_data_extended.csv'
INTO TABLE customer_demographics 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

--3.	Get the average number of family members per customer.
--o	Solution: Use AVG on family_size from customer_demographics.csv.

select 
marital_status
,count(customer_id) from customer_demographics
group by marital_status;

update  customer_demographics
set marital_status='Single'
where marital_status ='';
commit;

select 
no_of_children
length(no_of_children),
count(customer_id) ,
from customer_demographics
group by no_of_children;

update  customer_demographics
set no_of_children=0
where marital_status='Single';
commit;

ALTER TABLE customer_demographics  
MODIFY COLUMN family_size INT;

ALTER TABLE customer_demographics  
MODIFY COLUMN no_of_children INT;

update  customer_demographics
set family_size=2+no_of_children
where marital_status ='Married' 
and no_of_children>0;
commit;

update  customer_demographics
set family_size=1
where marital_status in ('Widowed','Divorced') 
and no_of_children=0;
commit;

update  customer_demographics
set family_size=1 + no_of_children
where marital_status in ('Widowed','Divorced') 
commit;


select 
    family_size,
    marital_status,
    no_of_children,
    count(customer_id) from customer_demographics,
group by 
    family_size,
    marital_status,
    no_of_children;

select ROUND (avG(family_size)) from customer_demographics;
--THE AVERAGE FAMILY SIZE IS 2

--4.	Retrieve the total sales value of items bought using a coupon.
--o	Solution: Join customer_transaction_data.csv with train.csv on customer_id and coupon_id and sum the selling_price.
SELECT 
CONCAT ('$',SUM(selling_price))
FROM customer_transactionS AS CT 
WHERE coupon_discount <>0;
--THE TOTAL SELLING PRICE USING COUPON IS  $3143536.87


--5.	Identify the top 3 most popular products by quantity sold under a campaign.
--o	Solution: Use JOIN between customer_transaction_data.csv and coupon_item_mapping.csv, then GROUP BY item_id with SUM(quantity) and ORDER BY.

select 
item_id 
from item_data 
where not exists 
(select 1 from customer_transactions where item_data.item_id=customer_transactions.item_id);


select 
item_id 
from customer_transactions 
where not exists 
(select 1 from item_data where item_data.item_id=customer_transactions.item_id);


with Ranksupport as(
SELECT
    id.item_id,
    id.brand,
    id.brand_type,
    id.Category,
    SUM(ct.QUANTITY) AS total_quantity,
    RANK() OVER (ORDER BY SUM(ct.QUANTITY) DESC) AS quantity_rank
FROM item_data id
INNER JOIN customer_transactions ct ON id.item_id = ct.item_id
where coupon_discount <>0 
GROUP BY 
    id.item_id,
    id.brand,
    id.brand_type,
    id.Category)
select * from Ranksupport where quantity_rank <11 ;

--THE MOST POPULAR CATEGORY IS GROCERY 

--6.	Find the total discount amount given to customers for each coupon.
--o	Solution: Use SUM(coupon_discount) grouped by coupon_id.
CREATE INDEX idx_customer_transactions_customer_id ON customer_transactions(customer_id);
CREATE INDEX idx_coupon_item_mapping_coupon_id ON coupon_item_mapping(coupon_id);
CREATE INDEX idx_coupon_item_mapping_item_id ON coupon_item_mapping(item_id);
CREATE INDEX idx_TRAIN ON TRAIN(customer_id);
CREATE INDEX idx_TRAIN ON TRAIN(coupon_id);


SHOW PROCESSLIST;


show index from customer_transactions;
show index from coupon_item_mapping;
SHOW INDEX FROM TRAIN;


SELECT distinct
    tr.customer_id,
    cim.coupon_id,
    cd.marital_status,
    cd.family_size,
    SUM(ct.coupon_discount) AS coupon_discount
FROM train TR
INNER JOIN customer_demographics cd ON tr.customer_id = cd.customer_id
INNER JOIN customer_transactions ct ON ct.customer_id = tr.customer_id and coupon_discount <>0
inner join coupon_item_mapping cim on  cim.item_id=ct.item_id and tr.coupon_id=cim.coupon_id
inner join campaign_data camp on tr.campaign_id=camp.campaign_id 
       and ct.transaction_date between camp.start_date and camp.end_date
GROUP BY 
        tr.customer_id,
        cim.coupon_id,
        cd.marital_status,
        cd.family_size
ORDER BY 
    tr.customer_id,
    coupon_discount ASC;

 show PROCESSLIST;   
kill 195



select * from customer_transactions where customer_id=1558;


--7.	Retrieve customers who have redeemed more than 5 coupons.
--o	Solution: Use GROUP BY on customer_id with HAVING COUNT(coupon_id) > 5.

WITH COUNTCOUPONSUPPORT AS (
select 
    customer_id
    ,count(distinct coupon_id) COUPONCOUNT
from train
where redemption_status='1'
group by customer_id)
SELECT * FROM COUNTCOUPONSUPPORT WHERE COUPONCOUNT >5;

--8.	List all the customers who have purchased a particular item.
--o	Solution: Use JOIN between customer_transaction_data.csv and item_data.csv on item_id, filtering by item category or item_id.

select 
id.category
,count(distinct ct.customer_id)
from item_data id 
inner join customer_transactions ct on ct.item_id=id.item_id and ct.coupon_discount <>0
group by id.category;





--9.	Find the average income bracket of customers who redeemed coupons.
--o	Solution: Join customer_demographics.csv with train.csv, then calculate the AVG(income_bracket) for customers where redemption_status = 1.

select 
     cd.marital_status
    ,round(avg(income_bracket))
from train tr
inner join customer_demographics cd on cd.customer_id=tr.customer_id and redemption_status='1'
group by cd.marital_status;


--10.	Determine the most frequently used coupon in a specific campaign.
--o	Solution: Use JOIN between train.csv and campaign_data.csv, then GROUP BY coupon_id and COUNT for a given campaign_id.
SELECT distinct
    camp.campaign_id,
    tr.coupon_id,
    count(tr.coupon_id)
FROM train TR
INNER JOIN customer_demographics cd ON tr.customer_id = cd.customer_id
INNER JOIN customer_transactions ct ON ct.customer_id = tr.customer_id and coupon_discount <>0
inner join coupon_item_mapping cim on  cim.item_id=ct.item_id and tr.coupon_id=cim.coupon_id
inner join campaign_data camp on tr.campaign_id=camp.campaign_id 
       and ct.transaction_date between camp.start_date and camp.end_date
GROUP BY 
    camp.campaign_id,
    tr.coupon_id
ORDER BY 
  count(tr.coupon_id) desc;
  
--- at campaing 13 coupon id 21 is used frequently


--Complex SQL Questions Using Window Functions (20)
--1.	Rank customers based on the number of coupons redeemed per campaign.
--o	Solution: Use ROW_NUMBER() or RANK() with PARTITION BY campaign_id ORDER BY COUNT(coupon_id).

with ranksupport as (
    select 
    campaign_id,
    count(distinct customer_id),
    rank() over (order by count(distinct customer_id ) DESC) rankCampaign
    from train 
    where redemption_status=1
    group by 
    campaign_id
    order by campaign_id)
select * from ranksupport order by rankCampaign;

--2.	Calculate the cumulative discount for each customer across all campaigns.
--o	Solution: Use SUM(coupon_discount) OVER (PARTITION BY customer_id ORDER BY campaign_id).
SELECT distinct
    camp.campaign_id,
    tr.coupon_id,
    sum(case when  ct.transaction_date between camp.start_date and camp.end_date then coupon_discount end) coupon_used_ontime,
    sum(case when  ct.transaction_date not between camp.start_date and camp.end_date then coupon_discount end) coupon_used_nottime,
    count(case when  ct.transaction_date between camp.start_date and camp.end_date then cd.customer_id end) countcoupon_used_ontime,
    count(case when  ct.transaction_date not between camp.start_date and camp.end_date then cd.customer_id end) countcoupon_used_nottime
FROM train TR
INNER JOIN customer_demographics cd ON tr.customer_id = cd.customer_id
INNER JOIN customer_transactions ct ON ct.customer_id = tr.customer_id and coupon_discount <>0
inner join coupon_item_mapping cim on  cim.item_id=ct.item_id and tr.coupon_id=cim.coupon_id 
    and ct.item_id =cim.item_id
inner join campaign_data camp on tr.campaign_id=camp.campaign_id 
GROUP BY 
    camp.campaign_id,
    tr.coupon_id
ORDER BY 
    camp.campaign_id desc; 

SELECT distinct
    camp.campaign_id,
    tr.coupon_id,
    count(ct.customer_id) over (PARTITION by tr.coupon_id) NO_OF_COUPON_USED,
    sum(ct.coupon_discount) over (PARTITION by tr.coupon_id) COUPONVALUE
FROM train TR
INNER JOIN customer_demographics cd ON tr.customer_id = cd.customer_id
INNER JOIN customer_transactions ct ON ct.customer_id = tr.customer_id and coupon_discount <>0
inner join coupon_item_mapping cim on  cim.item_id=ct.item_id and tr.coupon_id=cim.coupon_id 
    and ct.item_id =cim.item_id
inner join campaign_data camp on tr.campaign_id=camp.campaign_id 
    and ct.transaction_date between camp.start_date and camp.end_date 
ORDER BY 
    camp.campaign_id desc; 

--3.	Identify the top 5 customers by total spending on items with coupons.
--o	Solution: Use SUM(selling_price) OVER (PARTITION BY customer_id) and ORDER BY to limit to top 5.

with ranksupport as(
SELECT distinct
    camp.campaign_id,
    tr.coupon_id,
    tr.customer_id,
    ct.item_id,
    sum(ct.selling_price) over (PARTITION by  camp.campaign_id,tr.coupon_id,tr.customer_id) SELLINGVALUE,
    sum(ct.coupon_discount) over (PARTITION by camp.campaign_id,tr.coupon_id,tr.customer_id) COUPONVALUE
FROM train TR
INNER JOIN customer_demographics cd ON tr.customer_id = cd.customer_id
INNER JOIN customer_transactions ct ON ct.customer_id = tr.customer_id and coupon_discount <>0
inner join coupon_item_mapping cim on  cim.item_id=ct.item_id and tr.coupon_id=cim.coupon_id 
    and ct.item_id =cim.item_id
inner join campaign_data camp on tr.campaign_id=camp.campaign_id 
    and ct.transaction_date between camp.start_date and camp.end_date 
ORDER BY 
    camp.campaign_id , 
    tr.coupon_id,
    tr.customer_id desc)
select *,rank() over (order by SELLINGVALUE desc) from ranksupport; 


4.	Calculate the moving average of coupon redemption rate for each campaign over time.
o	Solution: Use AVG(redemption_status) OVER (PARTITION BY campaign_id ORDER BY start_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW).
5.	Rank products based on the quantity sold per coupon redemption.
o	Solution: Use RANK() with PARTITION BY coupon_id ORDER BY SUM(quantity).
6.	Find the first purchase date for each customer who redeemed a coupon.
o	Solution: Use MIN(date) OVER (PARTITION BY customer_id ORDER BY date).
7.	Calculate the average sales value per customer across campaigns.
o	Solution: Use AVG(selling_price) OVER (PARTITION BY customer_id).
8.	Identify the percentage change in sales for each product before and after a campaign.
o	Solution: Use LAG() to get previous sales and calculate the difference and percentage change.
9.	Find the rank of each coupon based on total discount value in a campaign.
o	Solution: Use RANK() with PARTITION BY campaign_id ORDER BY SUM(coupon_discount).
10.	Determine how many campaigns a customer participated in, with a limit to those who redeemed coupons.
o	Solution: Use COUNT(DISTINCT campaign_id) OVER (PARTITION BY customer_id) with WHERE redemption_status = 1.
11.	List the customers with the highest cumulative discount, ordered by campaign.
o	Solution: Use SUM(coupon_discount) OVER (PARTITION BY customer_id ORDER BY campaign_id).
12.	Find the median sales value of items purchased by customers who redeemed coupons.
o	Solution: Use PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY selling_price).
13.	Identify customers who have redeemed coupons in consecutive campaigns.
o	Solution: Use LAG(campaign_id) to check if the previous campaign is consecutive.
14.	Get the moving sum of coupon redemptions for each customer by campaign.
o	Solution: Use SUM(redemption_status) OVER (PARTITION BY customer_id ORDER BY campaign_id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW).
15.	Calculate the total discount and redemption rate per customer and campaign.
o	Solution: Use SUM(coupon_discount) OVER (PARTITION BY customer_id, campaign_id) and calculate redemption rate using COUNT.
16.	Find the customers who spent more than the average in a given campaign.
o	Solution: Use AVG(selling_price) OVER (PARTITION BY campaign_id) and filter customers spending more.
17.	Rank customers by total quantity purchased, considering only redeemed coupons.
o	Solution: Use RANK() with PARTITION BY customer_id ORDER BY SUM(quantity) where redemption_status = 1.
18.	Identify products with the highest total coupon discount value, ordered by campaign.
o	Solution: Use SUM(coupon_discount) OVER (PARTITION BY item_id ORDER BY campaign_id).
19.	Determine customers who have redeemed at least 3 coupons in the last 5 campaigns.
o	Solution: Use COUNT(coupon_id) OVER (PARTITION BY customer_id ORDER BY campaign_id ROWS BETWEEN 4 PRECEDING AND CURRENT ROW).
20.	Find the top 5 most redeemed coupons for each campaign.
o	Solution: Use RANK() with PARTITION BY campaign_id ORDER BY COUNT(coupon_id) and limit to top 5.


