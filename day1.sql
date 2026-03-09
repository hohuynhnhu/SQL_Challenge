create schema dannys_diner;
GO

create table sales(
"customer_id" varchar(1),
"order_date" date,
"product_id" integer
);
insert into sales values
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

  create table menu(
  "product_id" integer,
  "product_name" varchar(5),
  "price" integer

  );
 insert into menu values
	(1, 'BA', 5),
	(2, 'Fr', 3),
	(3, 'So', 2);

create table members (
  "customer_id" varchar(1),
  "join_date" date
);

insert into members 
("customer_id","join_date")
values
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. tinhs tong so tien moi khach da chi tieu
select 
s.customer_id,
SUM(m.price) as total_spent
from sales s
join menu m
on s.product_id = m.product_id
group by s.customer_id


--2. Tính tổng ngày mà mỗi khách hàng đến cửa hàng

select customer_id,
count(DISTINCT order_date) as visit_days
from sales 
group by customer_id
-- 3. tính sản phẩm đầu tiên mà mỗi khách hàng đã mua

select sales.customer_id,menu.product_name
from sales
join menu 
on sales.product_id = menu.product_id
where sales.order_date = (select min(order_date) from sales s where s.customer_id = sales.customer_id
)
--4. Tính sản phẩm bán chạy và có bao nhiêu lượt bán của sản phẩm đó
select TOP 1 menu.product_name , COUNT(*) as total_sold
from sales
join menu
on sales.product_id = menu.product_id
group by menu.product_name
order by total_sold desc

-- 5. tính sản phẩm được bán chạy nhất
select menu.product_name, COUNt(*) as total_sold
from sales
join menu
on sales.product_id = menu.product_id
group by menu.product_name
order by total_sold desc

--6. Mặt hàng đầu tiên sau khi khách hàng tham gia cửa hàng	

select sales.customer_id, menu.product_name, members.join_date
from sales
join members
on sales.customer_id = members.customer_id
join menu
on sales.product_id = menu.product_id
where sales.order_date >= members.join_date
;
--7 các mặt hàng mà khách hàng đã mua trước khi tham gia cửa hàng
select sales.customer_id, menu.product_name, members.join_date
from sales
join members
on sales.customer_id = members.customer_id
join menu
on sales.product_id = menu.product_id
where sales.order_date < members.join_date

-- 8 tính tổng số tiền mà khách hàng đã chi tiêu trước khi tham gia cửa hàng theo từng mặt hàng 
select sales.customer_id, menu.product_name,  SUM(menu.price) as total_spent
from sales
join members
on sales.customer_id = members.customer_id
join menu
on sales.product_id = menu.product_id
where sales.order_date < members.join_date 
group by sales.customer_id, menu.product_name, menu.price

-- 9 nếu tính 1$ tương đương 10d thì mỗi khách hàng có bao nhiêu điểm
select sales.customer_id, SUM(menu.price) * 10 as points
from sales
join menu
on sales.product_id = menu.product_id
group by sales.customer_id, menu.price


select sales.customer_id, SUM(menu.price) * 10 as points, members.join_date
from sales
join menu
on sales.product_id = menu.product_id
join members
on sales.customer_id = members.customer_id
where sales.order_date < '2021-01-31' and sales.order_date >= members.join_date
group by sales.customer_id, menu.price, members.join_date 
order by points desc





