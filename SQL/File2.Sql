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
  ,COUNT(DISTINCT coupon_id) AS distinct_coupon_count
  ,COUNT(coupon_id)   CouponDistributed
  ,COUNT(CASE WHEN redemption_status=1 THEN 1 END) Redeemed
  ,COUNT(CASE WHEN redemption_status=0 THEN 1 END) NotRRedeemed
  ,(COUNT(CASE WHEN redemption_status=1 THEN 1 END)/COUNT(coupon_id)) *100 '% of Coupon Redeemed'
 FROM train
GROUP BY campaign_id;


--2.	List customers who have never redeemed a coupon.
--o	Solution: Use LEFT JOIN between train.csv and customer_id, then filter out redemption_status = 1.

select * from 
(select
 CD.customer_id
,CASE 
            WHEN COUNT(DISTINCT tr.campaign_id) = 0 THEN 'NeverParticipated' 
            ELSE 'Participated' 
        END AS ParticipationStatus
,count(DISTINCT tr.campaign_id) as campaignParticipated        
,group_concat(distinct campaign_id)
,count(coupon_id)  CouponProvided
,COUNT(CASE WHEN redemption_status=1 THEN coupon_id END) Redeemed
,COUNT(CASE WHEN redemption_status=0 THEN coupon_id END) NotRedeemed
,(COUNT(CASE WHEN redemption_status=1 THEN coupon_id END)/COUNT(coupon_id)) *100 Per_of_Coupon_Redeemed
from  customer_demographics CD
left join train tr on tr.customer_id=CD.customer_id
group by CD.customer_id )  Subquery
order by Subquery.campaignParticipated asc , Per_of_Coupon_Redeemed desc;


select distinct customer_id
from train t where not exists 
(select 1 from customer_demographics cd where cd.customer_id=t.customer_id);




3.	Get the average number of family members per customer.
o	Solution: Use AVG on family_size from customer_demographics.csv.
4.	Retrieve the total sales value of items bought using a coupon.
o	Solution: Join customer_transaction_data.csv with train.csv on customer_id and coupon_id and sum the selling_price.
5.	Identify the top 3 most popular products by quantity sold under a campaign.
o	Solution: Use JOIN between customer_transaction_data.csv and coupon_item_mapping.csv, then GROUP BY item_id with SUM(quantity) and ORDER BY.
6.	Find the total discount amount given to customers for each coupon.
o	Solution: Use SUM(coupon_discount) grouped by coupon_id.
7.	Retrieve customers who have redeemed more than 5 coupons.
o	Solution: Use GROUP BY on customer_id with HAVING COUNT(coupon_id) > 5.
8.	List all the customers who have purchased a particular item.
o	Solution: Use JOIN between customer_transaction_data.csv and item_data.csv on item_id, filtering by item category or item_id.
9.	Find the average income bracket of customers who redeemed coupons.
o	Solution: Join customer_demographics.csv with train.csv, then calculate the AVG(income_bracket) for customers where redemption_status = 1.
10.	Determine the most frequently used coupon in a specific campaign.
o	Solution: Use JOIN between train.csv and campaign_data.csv, then GROUP BY coupon_id and COUNT for a given campaign_id.
Complex SQL Questions Using Window Functions (20)
1.	Rank customers based on the number of coupons redeemed per campaign.
o	Solution: Use ROW_NUMBER() or RANK() with PARTITION BY campaign_id ORDER BY COUNT(coupon_id).
2.	Calculate the cumulative discount for each customer across all campaigns.
o	Solution: Use SUM(coupon_discount) OVER (PARTITION BY customer_id ORDER BY campaign_id).
3.	Identify the top 5 customers by total spending on items with coupons.
o	Solution: Use SUM(selling_price) OVER (PARTITION BY customer_id) and ORDER BY to limit to top 5.
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

