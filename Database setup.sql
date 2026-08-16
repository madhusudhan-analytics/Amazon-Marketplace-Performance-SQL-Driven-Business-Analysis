
-- Database setup

create database Amazon_DB;
use Amazon_DB;

-- Table 1 Category
create table Category (
Category_id int primary key,
Category_name varchar(500)
);

-- Table 2 Products
create table Products (
Product_id int primary key,
Product_name varchar(600),
Price decimal(10,2),
COGS decimal(10,2),
Category_id int, -- FK
foreign key (Category_id) references  Category(Category_id)
);

-- Table 3 Sellers
create table Sellers (
Seller_id int primary key,
Seller_name varchar(700),
Origin varchar(50)
);

-- Table 4 Inventory
create table Inventory (
Inventory_id int primary key,
Product_id int, -- FK
Stock int,
Last_stock_date date,
foreign key (Product_id) references Products(Product_id)
);

-- Table 5 Customers
create table Customers (
Customer_id int primary key,
First_name varchar(600),
Last_name varchar(600),
State varchar(600)
);

-- Table 6 Orders 
create table Orders (
Order_id int primary key,
Order_date date,
Customer_id int, -- FK
Seller_id int, -- FK
Order_status varchar(600),
foreign key (Customer_id) references Customers(Customer_id),
foreign key (Seller_id) references Sellers(Seller_id)
);

-- Table 7 Order_items
create table Order_items (
Order_item_id int primary key,
Order_id int, -- FK
Product_id int, -- FK
Quantity int,
Price_per_unit decimal(10,2),
foreign key (Order_id) references Orders(Order_id),
foreign key (Product_id) references Products(Product_id)
);   

-- Table 8 Payments
create table Payments (
Payment_id int primary key,
Order_id int, -- FK
Payment_date date,
Payment_status varchar(600),
foreign key (Order_id) references Orders(Order_id)
);

-- Table 9 Shipping
create table Shipping (
Shipping_id int primary key,
Order_id int, -- FK
Shipping_date date,
Return_date varchar(100),
Shipping_providers varchar(600),
Delivery_status varchar(600),
foreign key (Order_id) references Orders(Order_id)
);

update Shipping
set Return_date = null
where Delivery_status <> 'Returned '; 

alter table Shipping
modify Return_date date;





















