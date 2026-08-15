## Project Overview

This project analyses Amazon marketplace data using SQL as the primary analytical tool, with Power BI used only to visualize the resulting findings. It is designed to demonstrate strong SQL fundamentals, from data validation through advanced query techniques, applied to a real-world business analyst use case.

The dataset spans **9 relational tables** (Category, Products, Sellers, Inventory, Customers, Orders, Order_items, Payments, Shipping) covering **approximately 21,630 orders from January 2020 to July 2024**, loaded into a MySQL database (`Amazon_DB`).

The project is structured in two parts:

### 1. Data Validation & Trust Checks

Before any business analysis, the dataset is systematically validated. This includes checking referential integrity across all table relationships, identifying duplicates, and confirming there are no nulls or zero-values in fields critical to revenue and margin calculations. This step surfaced several genuine, non-error findings (for example, **212 customers who never placed an order**, and **488 cancelled orders with no shipping record**) that later fed directly into the business analysis.

### 2. 18 Business Questions

Organized across five sections (Sales & Revenue Performance, Customer Behaviour, Seller & Marketplace Performance, Operations, and Advanced/Strategic Synthesis), each question is answered with a documented SQL query, a plain-language insight explaining the finding, and a corresponding Power BI visualization. Techniques used include multi-table joins, CTEs, subqueries, conditional aggregation, and window functions such as `RANK()`, `ROW_NUMBER()`, and running totals with `PARTITION BY`.

**Key findings include:** Electronics drives **approximately 90% of total profit** despite being one of six categories. Ohio and Texas together account for **about 88% of total revenue**. Repeat customers generate **roughly 27 times more revenue** than one-time buyers. One shipping provider (Bluedart) shows a **near-total delivery failure rate**, flagged as a critical operational risk.

**Tools used**: MySQL (database and analysis), Power BI (visualization layer only).

## Business Objective

Amazon operates a large, multi-category marketplace connecting thousands of sellers with customers across the country. As the business scales, leadership needs visibility into where revenue and profit actually come from, which customers and sellers drive sustainable growth, and where operational risks such as payment failures or delivery breakdowns might be quietly eroding performance.

This project takes on the role of a business analyst tasked with answering that need. Using SQL to extract, validate, and analyze marketplace data, **the goal is to uncover actionable insights across sales performance, customer retention, seller reliability, and fulfilment operations.** The focus is not just on reporting numbers, but on identifying patterns, risks, and opportunities that could directly inform business strategy, such as diversification away from over-concentrated revenue sources, retention-focused customer initiatives, and vendor and provider performance reviews.

## Dataset

The dataset represents an Amazon-style e-commerce marketplace, structured across **9 relational tables** in a MySQL database (`Amazon_DB`). It covers approximately **21,630 orders placed between January 2020 and July 2024**, along with the customers, sellers, products, and fulfilment records tied to those orders.

| Table | Description |
|---|---|
| **Category** | Product category names (6 categories: Electronics, Clothing, Home & Kitchen, Sports & Outdoors, Pet Supplies, Toys & Games) |
| **Products** | Product name, price, cost of goods sold (COGS), and category |
| **Sellers** | Seller name and country of origin |
| **Inventory** | Stock levels and last restock date per product |
| **Customers** | Customer name and state |
| **Orders** | Order date, linked customer and seller, and order status (Completed, Cancelled, Returned, In Progress) |
| **Order_items** | Line-item detail for each order, including quantity and price per unit |
| **Payments** | Payment date and status (Payment Succussed, Payment Failed, Refunded) |
| **Shipping** | Shipping date, return date, shipping provider, and delivery status |

### Entity Relationship Diagram

![Amazon Database ERD](Amazon%20ERD%20(Basic).png)

All table relationships shown above were fully validated in the Data Validation & Trust Checks section before any analysis was performed, confirming referential integrity across the schema with no orphaned records.

**Data quality note:** Revenue data becomes unreliable after January 2024, dropping by approximately 95% and never recovering through the end of the dataset. This is treated as a data completeness limitation rather than a genuine business trend, and is flagged accordingly wherever it affects a finding (see Q2 and Q7).

