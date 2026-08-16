--  Relationship Integrity Checks

-- Orders ↔ Customers

-- 1. Does every customer have at least one order?
select count(*) from Customers c
left join Orders o
on c.Customer_id = o.Customer_id
where o.Customer_id is null;
-- 212 customers — about 23.6% of the customer base — have never placed an order. This isn't a data issue, just people who signed up but never bought anything. Worth revisiting in the Customer Behavior section as a possible conversion gap.

-- 2. Does every order point to a real, existing customer?
select count(*) from Orders o
left join Customers c
on o.Customer_id = c.Customer_id
where c.Customer_id is null;
-- No results here, which is a good sign — it means every order is tied to a real, existing customer. No broken links between the two tables.


-- Orders ↔ Order_items

-- 1. Does every order have at least one order item?
select count(*) from Orders o
left join Order_items oi
on o.Order_id = oi.Order_id
where oi.Order_id is null;

-- 2. Does every order item point to a real order?
select count(*) from Order_items oi
left join Orders o
on oi.Order_id = o.Order_id
where o.Order_id is null;
-- Checked both directions between Orders and Order_items. Every order has at least one item (0 orders with no items), and every order item points to a valid order (0 orphaned records). Full referential integrity confirmed between these two tables.


-- Order_items ↔ Products

-- 1. Does every order item reference a real, existing product?
select count(*) from Order_items oi
left join Products p
on oi.Product_id = p.Product_id
where p.Product_id is null;

-- 2. Is there any product that has never been ordered?
select count(*) from Products p
left join Order_items oi
on p.Product_id = oi.Product_id
where oi.Product_id is null;
-- All order items reference valid products — no broken links. However, 15 products (out of 765) have never been ordered at all. Worth flagging for the Sales & Revenue section — these could be new listings, discontinued items, or genuinely underperforming products worth investigating further.


-- Products ↔ Category

-- 1. Does every product belong to a real, existing category?
select count(*) from Products p
left join Category c
on p.Category_id = c.Category_id
where c.Category_id is null;

-- 2. Is there any category with no products in it?
select count(*) from Category c
left join Products p
on c.Category_id = p.Category_id
where p.Product_id is null;
-- Every product is linked to a valid category, and every category has at least one product. No orphaned records, no unused categories.


-- Payments ↔ Orders

-- 1. Does every payment point to a real order?
select count(*) from Payments pay
left join Orders o
on pay.Order_id = o.Order_id
where o.Order_id is null;

-- 2. Does every order have a payment?
select count(*) from Orders o
left join Payments pay
on o.Order_id = pay.Order_id
where pay.Order_id is null;
-- Every payment is linked to a valid order, and every order has a payment on record. No broken links either direction.


-- Shipping ↔ Orders

-- 1. Does every shipping record point to a real order?
select count(*) from Shipping s
left join Orders o
on s.Order_id = o.Order_id
where o.Order_id is null;

-- 2. Does every order have a shipping record?
select count(*) from Orders o
left join Shipping s
on o.Order_id = s.Order_id
where s.Order_id is null;
-- Every shipping record is linked to a valid order — no broken links there. Howeve, 488 orders have no shipping record at all. Checking further, all 488 are "Cancelled" orders, which makes sense — cancelled orders were never shipped. This confirms our earlier finding from a different angle and rules out a data error.

-- Orders
select Order_id, count(Order_id)
from Orders
group by Order_id
having count(Order_id) > 1;

-- Customers
select Customer_id, count(Customer_id)
from Customers
group by Customer_id
having count(Customer_id) > 1;

-- Products
select Product_id, count(Product_id)
from Products
group by Product_id
having count(Product_id) > 1;
-- No duplicate primary keys found across Orders, Customers, or Products — confirms the primary key constraints held correctly on import.

-- Payments
select Order_id, count(Order_id)
from Payments
group by Order_id
having count(Order_id) > 1;

-- Shipping
select Order_id, count(Order_id)
from Shipping
group by Order_id
having count(Order_id) > 1;
-- No order has more than one payment record, and no order has more than one shipping record either. Confirms these are true one-to-one relationships as expected — no duplicate transactions or shipments per order.

-- Q3 Nulls / Zeros in fields that matter for analysis

-- Products: Price or COGS is null
select count(*) from Products
where Price is null or COGS is null;

-- Products: Price or COGS is 0
select count(*) from Products
where Price = 0 or COGS = 0;

-- Products: COGS greater than Price
select count(*) from Products
where COGS > Price;
-- No nulls or zero values in Price or COGS, and COGS never exceeds Price. Margin calculations in the Sales & Revenue section can be trusted — no risk of negative or broken profit numbers.


-- Order_items: Quantity or Price_per_unit is null
select count(*) from Order_items
where Quantity is null or Price_per_unit is null;

-- Order_items: Quantity or Price_per_unit is 0
select count(*) from Order_items
where Quantity = 0 or Price_per_unit = 0;
-- No nulls or zero values in Quantity or Price_per_unit — revenue calculations from Order_items can be trusted without risk of undercounting or division errors.


-- Orders: Order_date is null
select count(*) from Orders
where Order_date is null;

-- Payments: Payment_date is null
select count(*) from Payments
where Payment_date is null;

-- Shipping: Shipping_date is null
select count(*) from Shipping
where Shipping_date is null;
-- No missing dates across Orders, Payments, or Shipping — all time-series and trend queries in later sections can run without risk of gaps or broken date logic.