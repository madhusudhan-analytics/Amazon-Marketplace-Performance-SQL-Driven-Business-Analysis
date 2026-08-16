-- 2 Sales & Revenue Performance

-- Q1: Revenue and Profit by Category

select c.Category_name, 
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue,
       sum(oi.Quantity * (oi.Price_per_unit - p.COGS)) as Total_Profit,
       round(sum(oi.Quantity * (oi.Price_per_unit - p.COGS)) * 100.0 / 
             (select sum(oi2.Quantity * (oi2.Price_per_unit - p2.COGS))
              from Order_items oi2
              join Products p2 on oi2.Product_id = p2.Product_id
              join Orders o2 on oi2.Order_id = o2.Order_id
              join Payments pay2 on o2.Order_id = pay2.Order_id
              where pay2.Payment_status = 'Payment Successed'), 2) as Profit_Contribution_Pct
from Order_items oi
join Products p on oi.Product_id = p.Product_id
join Category c on p.Category_id = c.Category_id
join Orders o on oi.Order_id = o.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by c.Category_name;
-- Electronics contributes nearly 90% of total profit (89.96%) — an extreme concentration. Every other category combined accounts for roughly 10% of profit. This signals a significant business risk: any disruption to Electronics (supply issues, demand shift, increased competition) would have an outsized impact on overall profitability. Diversification could be a strategic recommendation worth raising.

-- Q2: Monthly Revenue Trends

select date_format(o.Order_date, '%Y-%m') as Order_Month,
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue
from Order_items oi
join Orders o on oi.Order_id = o.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by date_format(o.Order_date, '%Y-%m')
order by Order_Month;
-- Revenue holds steady between $2.0M–$2.8M per year from 2020–2023, with mild seasonal dips in Jan–Feb and a modest peak in late summer. However, revenue collapses by roughly 95% starting February 2024 and never recovers through July 2024, the end of the dataset. This is almost certainly a data completeness artifact — the dataset appears to stop being reliably populated after January 2024 — rather than a genuine business decline. Worth excluding or flagging 2024 as partial-year data in any trend visualization to avoid a misleading picture.

-- Q3: Top 10 Products by Revenue vs. Quantity Sold

-- Top 10 by revenue
select p.Product_name, 
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue
from Order_items oi
join Products p on oi.Product_id = p.Product_id
join Orders o on oi.Order_id = o.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by p.Product_name
order by Total_Revenue desc
limit 10;

-- Top 10 by quantity sold
select p.Product_name, 
       sum(oi.Quantity) as Total_Quantity_Sold
from Order_items oi
join Products p on oi.Product_id = p.Product_id
join Orders o on oi.Order_id = o.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by p.Product_name
order by Total_Quantity_Sold desc
limit 10;
-- The top 10 products by revenue and top 10 by quantity sold have zero overlap. Revenue leaders are premium, low-volume electronics (Apple iMacs, MacBook Pros, high-end cameras) — consistent with the earlier finding that Electronics drives ~90% of total profit. Quantity leaders are inexpensive, high-volume items from Sports & Outdoors and Pet Supplies (resistance bands, soccer nets, dog beds). This confirms two distinct business dynamics: a small number of expensive electronics driving most of the revenue and profit, while cheaper accessory-type products drive order volume and frequency.

-- Q4: Pareto Analysis — Revenue Contribution from Top 20% of Products

with Product_Revenue_Ranked as (
    select p.Product_name,
           sum(oi.Quantity * oi.Price_per_unit) as Product_Revenue,
           row_number() over (order by sum(oi.Quantity * oi.Price_per_unit) desc) as Revenue_Rank
    from Order_items oi
    join Products p on oi.Product_id = p.Product_id
    join Orders o on oi.Order_id = o.Order_id
    join Payments pay on o.Order_id = pay.Order_id
    where pay.Payment_status = 'Payment Successed'
    group by p.Product_name
)
select 
    sum(case when Revenue_Rank <= 149 then Product_Revenue else 0 end) as Top20pct_Revenue,
    sum(Product_Revenue) as Total_Revenue,
    round(sum(case when Revenue_Rank <= 149 then Product_Revenue else 0 end) * 100.0 / sum(Product_Revenue), 2) as Top20pct_Contribution_Pct
from Product_Revenue_Ranked;
-- The top 20% of products (149 of 745) generate 79.71% of total revenue — closely matching the classic 80/20 Pareto pattern. This reinforces the earlier finding that revenue is highly concentrated: a relatively small set of high-value products (mostly premium electronics) drives the vast majority of the business. From a strategy standpoint, protecting and growing this core product set matters far more than trying to boost the long tail of lower-revenue products.

-- Q5: Average Order Value (AOV) Trend, Month over Month

select date_format(o.Order_date, '%Y-%m') as Order_Month,
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue,
       count(distinct o.Order_id) as Total_Orders,
       round(sum(oi.Quantity * oi.Price_per_unit) / count(distinct o.Order_id), 2) as AOV
from Order_items oi
join Orders o on oi.Order_id = o.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by date_format(o.Order_date, '%Y-%m')
order by Order_Month;
-- AOV averaged $600–780 in 2020–early 2021, then structurally dropped to $450–630 starting March 2021 as order volume roughly doubled. This suggests revenue growth in 2021–2023 was driven by acquiring more orders rather than customers spending more per transaction. AOV never returned to early-2020 levels for the rest of the dataset. The sharp AOV drop in 2024 aligns with the previously identified data completeness issue and shouldn't be read as a genuine trend.

-- Section 3 — Customer Behavior

-- Q6: Repeat vs. One-Time Customers — Count and Revenue Contribution

-- Customer count and % split
with Customer_Order_Counts as (
    select o.Customer_id, count(distinct o.Order_id) as Order_Count
    from Orders o
    group by o.Customer_id
)
select 
    case when Order_Count > 1 then 'Repeat' else 'One-time' end as Customer_Type,
    count(*) as Num_Customers,
    round(count(*) * 100.0 / sum(count(*)) over (), 2) as Pct_of_Customers
from Customer_Order_Counts
group by case when Order_Count > 1 then 'Repeat' else 'One-time' end;
-- 94.46% of customers who have ordered at all are repeat buyers, and only 5.54% (38 customers) are one-time buyers.

-- Revenue by customer type
with Customer_Order_Counts as (
    select o.Customer_id, count(distinct o.Order_id) as Order_Count
    from Orders o
    group by o.Customer_id
),
Customer_Type_Labels as (
    select Customer_id,
           case when Order_Count > 1 then 'Repeat' else 'One-time' end as Customer_Type
    from Customer_Order_Counts
)
select ctl.Customer_Type,
       count(distinct ctl.Customer_id) as Num_Customers,
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue,
       round(sum(oi.Quantity * oi.Price_per_unit) / count(distinct ctl.Customer_id), 2) as Revenue_Per_Customer
from Customer_Type_Labels ctl
join Orders o on ctl.Customer_id = o.Customer_id
join Order_items oi on o.Order_id = oi.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by ctl.Customer_Type;
-- Repeat customers (616, ~90% of paying customers) generate an average of $17,266 in lifetime revenue per customer — about 27x more than one-time buyers (~$647 average). This reinforces that customer retention drives the vast majority of revenue, and highlights that improving new-customer conversion into repeat buyers is likely the clearest growth lever for this business.

-- Q7: Top 10 Customers by Lifetime Spend

select c.Customer_id, c.First_name, c.Last_name,
       sum(oi.Quantity * oi.Price_per_unit) as Lifetime_Spend
from Customers c
join Orders o on c.Customer_id = o.Customer_id
join Order_items oi on o.Order_id = oi.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by c.Customer_id, c.First_name, c.Last_name
order by Lifetime_Spend desc
limit 10;
-- Top 10 customers by lifetime spend range from $74,629 to $89,029 — a relatively tight cluster rather than one dominant outlier, suggesting a genuine "top tier" segment rather than a single anomaly. These customers spend 4-5x the average repeat customer ($17,266), making them a clear candidate for a VIP/loyalty program or personalized retention outreach.

-- Q8: Revenue and Orders by State

select c.State,
       count(distinct o.Order_id) as Total_Orders,
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue
from Customers c
join Orders o on c.Customer_id = o.Customer_id
join Order_items oi on o.Order_id = oi.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by c.State
order by Total_Revenue desc;
-- Revenue is extremely concentrated geographically — Ohio alone accounts for 61.57% of total revenue, and Texas adds another 26.25%, meaning just two states generate 87.82% of all revenue. Every other state combined contributes roughly 12%. This represents a significant geographic risk: the business is heavily dependent on conditions in just two states. Worth investigating further — it may reflect the business's operational/shipping footprint rather than organic demand distribution.

-- Q9: Customer Order Frequency Distribution

with Customer_Order_Counts as (
    select o.Customer_id, count(distinct o.Order_id) as Order_Count
    from Orders o
    group by o.Customer_id
)
select 
    case 
        when Order_Count = 1 then '1 order'
        when Order_Count between 2 and 3 then '2-3 orders'
        when Order_Count between 4 and 6 then '4-6 orders'
        when Order_Count between 7 and 10 then '7-10 orders'
        else '10+ orders'
    end as Order_Frequency_Band,
    count(*) as Num_Customers,
    round(count(*) * 100.0 / sum(count(*)) over (), 2) as Pct_of_Customers
from Customer_Order_Counts
group by 
    case 
        when Order_Count = 1 then '1 order'
        when Order_Count between 2 and 3 then '2-3 orders'
        when Order_Count between 4 and 6 then '4-6 orders'
        when Order_Count between 7 and 10 then '7-10 orders'
        else '10+ orders'
    end
order by min(Order_Count);
-- Customer order frequency is broadly spread rather than concentrated at either extreme. Only 5.54% of customers are one-time buyers, while nearly a third (30.90%) have placed 10+ orders — the single largest band, representing a genuinely loyal core. Frequency dips notably in the 7-10 order range, suggesting a possible drop-off point before customers either churn early or become true regulars. Combined with the earlier finding that repeat customers drive ~27x more revenue than one-time buyers, this indicates the business has a healthy retention engine — the real opportunity is converting light repeat buyers (2-6 orders) into the loyal 10+ order segment.

-- Section 4 — Seller & Marketplace Performance

-- Q10: Seller Revenue and Marketplace Concentration

select s.Seller_name,
       count(distinct o.Order_id) as Total_Orders,
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue
from Sellers s
join Orders o on s.Seller_id = o.Seller_id
join Order_items oi on o.Order_id = oi.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by s.Seller_id, s.Seller_name
order by Total_Revenue desc;
-- The top 5 sellers (AnkerDirect, Tech Armor, iSaddle, AmazonBasics, Ailun) generate 65.72% of total revenue, and the top 10 generate 75.3% — meaningful concentration, but more gradual than the extreme dominance seen in category or state analysis. These top sellers are tightly clustered ($1.34M-$1.44M each) rather than one outlier dominating, suggesting a competitive top tier. A long tail of ~25 sellers, mostly household/personal care brands, each generate under $10K, likely reflecting lower-demand product categories rather than seller underperformance.

-- Q11: Seller Performance by Origin

select s.Origin,
       count(distinct s.Seller_id) as Num_Sellers,
       count(distinct o.Order_id) as Total_Orders,
       sum(oi.Quantity * oi.Price_per_unit) as Total_Revenue,
       round(sum(oi.Quantity * oi.Price_per_unit) / count(distinct s.Seller_id), 2) as Revenue_Per_Seller
from Sellers s
join Orders o on s.Seller_id = o.Seller_id
join Order_items oi on o.Order_id = oi.Order_id
join Payments pay on o.Order_id = pay.Order_id
where pay.Payment_status = 'Payment Successed'
group by s.Origin
order by Total_Revenue desc;
-- USA-based sellers dominate the marketplace, generating $372,909 per seller on average — 2.5x UK sellers, 3.2x China sellers, and over 100x Canadian sellers. Canada stands out as a striking outlier: 9 sellers generated only $31,747 combined revenue (about 22 orders per seller across the entire multi-year dataset), suggesting these may be newly onboarded sellers, a niche product category, or a distinct market segment rather than simple underperformance. Worth investigating further before drawing firm conclusions.

-- Q12: Seller Cancellation and Return Rates

select s.Seller_name,
       count(distinct o.Order_id) as Total_Orders,
       sum(case when o.Order_status = 'Cancelled' then 1 else 0 end) as Cancelled_Orders,
       sum(case when o.Order_status = 'Returned' then 1 else 0 end) as Returned_Orders,
       round(sum(case when o.Order_status in ('Cancelled','Returned') then 1 else 0 end) * 100.0 
             / count(distinct o.Order_id), 2) as Cancel_Return_Rate_Pct
from Sellers s
join Orders o on s.Seller_id = o.Seller_id
group by s.Seller_id, s.Seller_name
order by Cancel_Return_Rate_Pct desc;
-- The highest cancel/return rates cluster among small-volume sellers (Charmin, Bounty, Luvs, BONA — all under 35 total orders), where a handful of returns swings the percentage sharply; these are statistically less reliable as a "problem seller" signal. The more meaningful finding is Cuisinart, with 411 orders and a 20.19% cancel/return rate — a large enough sample to represent a genuine pattern worth investigating. Separately, the top-5 revenue sellers all sit in a tight 14.5-16.5% band despite very high order volumes, suggesting a fairly consistent baseline cancel/return rate across the marketplace's biggest players rather than a fulfillment issue specific to any one of them.

-- Q13: Seller Order Volume vs. Cancel/Return Rate

with Seller_Stats as (
    select s.Seller_id, s.Seller_name,
           count(distinct o.Order_id) as Total_Orders,
           sum(case when o.Order_status in ('Cancelled','Returned') then 1 else 0 end) as Cancel_Return_Orders
    from Sellers s
    join Orders o on s.Seller_id = o.Seller_id
    group by s.Seller_id, s.Seller_name
)
select 
    case 
        when Total_Orders < 100 then 'Low volume (<100)'
        when Total_Orders between 100 and 500 then 'Medium volume (100-500)'
        else 'High volume (500+)'
    end as Volume_Tier,
    count(*) as Num_Sellers,
    sum(Total_Orders) as Total_Orders_Sum,
    sum(Cancel_Return_Orders) as Total_Cancel_Return,
    round(sum(Cancel_Return_Orders) * 100.0 / sum(Total_Orders), 2) as Avg_Cancel_Return_Rate_Pct
from Seller_Stats
group by 
    case 
        when Total_Orders < 100 then 'Low volume (<100)'
        when Total_Orders between 100 and 500 then 'Medium volume (100-500)'
        else 'High volume (500+)'
    end
order by min(Total_Orders);
-- Cancel/return rate is essentially flat across seller volume tiers — low volume (15.73%), medium volume (14.93%), and high volume sellers (15.60%) all cluster within about 1 percentage point of each other. Seller size has no meaningful relationship with quality/fulfillment performance. This reframes the earlier Q14 finding: standout sellers like Cuisinart are seller-specific outliers rather than evidence of a broader tier-wide pattern.

-- Q14: Payment Failure Rate — Overall and by Seller

-- Overall payment status breakdown
select Payment_status,
       count(*) as Num_Payments,
       round(count(*) * 100.0 / sum(count(*)) over (), 2) as Pct_of_Payments
from Payments
group by Payment_status;
-- Overall payment success rate is 84.61%, with 2.26% failed payments and 13.13% refunded. The failure rate itself is quite low — refunds represent a larger share of non-successful payments.

-- Failure rate by seller (sellers with 100+ payments only)
select s.Seller_name,
       count(*) as Total_Payments,
       sum(case when pay.Payment_status = 'Payment Failed' then 1 else 0 end) as Failed_Payments,
       round(sum(case when pay.Payment_status = 'Payment Failed' then 1 else 0 end) * 100.0 
             / count(*), 2) as Failure_Rate_Pct
from Payments pay
join Orders o on pay.Order_id = o.Order_id
join Sellers s on o.Seller_id = s.Seller_id
group by s.Seller_id, s.Seller_name
having Total_Payments >= 100
order by Failure_Rate_Pct desc
limit 10;
-- Payment failure rate holds steady around 2-4% across all sellers with meaningful volume — even the highest sellers (Shark at 3.75%, Hamilton Beach at 3.72%) are barely above the marketplace average of 2.26%. No evidence of failures concentrating around specific sellers; this looks like normal transactional noise rather than a seller-specific issue.

-- Q15: Delivery Success Rate by Shipping Provider

select Shipping_providers,
       count(*) as Total_Shipments,
       sum(case when trim(Delivery_status) = 'Delivered' then 1 else 0 end) as Delivered,
       sum(case when trim(Delivery_status) = 'Returned' then 1 else 0 end) as Returned,
       sum(case when trim(Delivery_status) = 'Shipped' then 1 else 0 end) as Still_Shipped,
       round(sum(case when trim(Delivery_status) = 'Delivered' then 1 else 0 end) * 100.0 
             / count(*), 2) as Delivery_Success_Rate_Pct
from Shipping
group by Shipping_providers
order by Delivery_Success_Rate_Pct desc;
-- Delivery performance varies enormously by provider. FedEx has a perfect 100% delivery success rate across all 14,346 shipments. DHL performs reasonably at 78.47%, with 948 shipments returned. Bluedart is a severe outlier — only 1 of 2,392 shipments (0.04%) shows as successfully delivered, with 79% returned and another 499 stuck in "Shipped" status unresolved. This is either a critical fulfillment failure specific to Bluedart or a data/tracking integration issue with that provider, and warrants immediate investigation given the risk to customer experience.

-- Q16: Return Rate by Product Category

select c.Category_name,
       count(distinct oi.Order_item_id) as Total_Items,
       sum(case when trim(s.Delivery_status) = 'Returned' then 1 else 0 end) as Returned_Items,
       round(sum(case when trim(s.Delivery_status) = 'Returned' then 1 else 0 end) * 100.0 
             / count(distinct oi.Order_item_id), 2) as Return_Rate_Pct
from Order_items oi
join Products p on oi.Product_id = p.Product_id
join Category c on p.Category_id = c.Category_id
join Orders o on oi.Order_id = o.Order_id
join Shipping s on o.Order_id = s.Order_id
group by c.Category_name
order by Return_Rate_Pct desc;
-- Return rates are fairly consistent across categories, ranging from 11.86% (Clothing) to 14.46% (Home & Kitchen) — no category shows a dramatic outlier. Notably, Electronics sits mid-pack at 13.87% despite driving ~90% of total profit, meaning the business's heavy reliance on Electronics isn't compounded by elevated return risk in that category. Home & Kitchen has the highest return rate, which could point to sizing, fit, or product-description accuracy issues worth investigating, though the gap from the average is modest. Note: return status is tracked at the order level, so orders with multiple items may overstate per-item return counts slightly.

-- Q17: Top Product by Revenue Within Each Category

with Product_Revenue_By_Category as (
    select c.Category_name, p.Product_name,
           sum(oi.Quantity * oi.Price_per_unit) as Product_Revenue,
           rank() over (partition by c.Category_name order by sum(oi.Quantity * oi.Price_per_unit) desc) as Rank_In_Category
    from Order_items oi
    join Products p on oi.Product_id = p.Product_id
    join Category c on p.Category_id = c.Category_id
    join Orders o on oi.Order_id = o.Order_id
    join Payments pay on o.Order_id = pay.Order_id
    where pay.Payment_status = 'Payment Successed'
    group by c.Category_name, p.Product_name
)
select Category_name, Product_name, Product_Revenue
from Product_Revenue_By_Category
where Rank_In_Category = 1
order by Product_Revenue desc;
-- The revenue leader within each category varies dramatically in scale — the Apple iMac Pro (Electronics) generates $509,998.98, more than 100x the top product in Home & Kitchen ($3,894.79, Espresso Machine). This illustrates the Electronics concentration finding from earlier: a single flagship product effectively anchors the business's overall revenue and profit performance.

-- Q18: Cumulative Revenue Trend and 50% Revenue Tipping Point by Year

with Monthly_Revenue as (
    select year(o.Order_date) as Order_Year,
           date_format(o.Order_date, '%Y-%m') as Order_Month,
           sum(oi.Quantity * oi.Price_per_unit) as Monthly_Revenue
    from Order_items oi
    join Orders o on oi.Order_id = o.Order_id
    join Payments pay on o.Order_id = pay.Order_id
    where pay.Payment_status = 'Payment Successed'
    group by year(o.Order_date), date_format(o.Order_date, '%Y-%m')
),
Cumulative_Revenue as (
    select Order_Year, Order_Month, Monthly_Revenue,
           sum(Monthly_Revenue) over (partition by Order_Year order by Order_Month) as Running_Total,
           sum(Monthly_Revenue) over (partition by Order_Year) as Year_Total
    from Monthly_Revenue
)
select Order_Year, Order_Month, Monthly_Revenue, Running_Total, Year_Total,
       round(Running_Total * 100.0 / Year_Total, 2) as Pct_Of_Year_Revenue
from Cumulative_Revenue
order by Order_Year, Order_Month;

-- From 2020–2023, cumulative revenue consistently crosses the 50% mark in June or July each year — a remarkably stable pattern suggesting steady, mildly seasonal revenue growth rather than a single dominant sales spike. 2024 appears to cross 50% in January, but this is a data artifact: the 2024 total is only $391,428 due to the data completeness issue identified earlier (revenue collapses after January 2024), so this figure should not be interpreted as a genuine early-year sales surge.
