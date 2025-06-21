/*
===============================================================================
Product Report
===============================================================================
Objective:
    - To deliver a consolidated view of key product performance metrics and trends.

Key Features:
    1. Collects fundamental product details including name, category, subcategory, and cost.
    2. Classifies products based on revenue performance into High-Performers, Mid-Range, and Low-Performers.
    3. Compiles key product-level statistics:
       - Total number of orders
       - Total sales revenue
       - Total units sold
       - Number of unique purchasing customers
       - Product lifespan (in months)
    4. Derives important KPIs:
       - Recency (months since the last sale)
       - Average Order Revenue (AOR)
       - Average monthly revenue
===============================================================================
*/
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

create view gold.report_products as 
with base_query as(
select
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
from gold.fact_sales f
left join gold.dim_products p
on f.product_key = p.product_key
where order_date is not null 
),
product_aggregations as(
select 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	datediff(month, min(order_date),max(order_date)) as lifespan,
	max(order_date) as last_sale_date,
	count(distinct order_number) as total_orders,
	count(distinct customer_key) as total_customers,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	round(avg(cast(sales_amount as float)/ nullif(quantity,0)),1) as avg_selling_price
from base_query
group by 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)
select
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(month, last_sale_date, GETDATE()) as recency_in_months,
	case 
		when total_sales > 50000 then 'High Performer'
		when total_sales >= 10000 then 'Mid Range'
		else 'Low Performer'
	end as product_segment,
	lifespan,
	total_orders,
	total_customers,
	total_sales,
	total_quantity,
	avg_selling_price,
	case 
		 when total_orders = 0 then 0 
		 else total_sales / total_orders 
	end as avg_order_revenue,
	case 
		 when lifespan = 0 then total_sales
		 else total_sales / lifespan 
	end as avg_monthly_revenue
from product_aggregations
	
