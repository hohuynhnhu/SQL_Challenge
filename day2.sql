create schema pizza_runner;
GO

create table runner (
	"runner_id" int,
	"registration_date" date

);
insert into runner ("runner_id", "registration_date")
values
(1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


create table customer_order (
	"order_id" int,
	"customer_id" int,
	"pizza_id" int,
	"exclusions" varchar(4),
	"extra" varchar(4),
	order_date VARCHAR(20)
);

drop table if exists customer_order
insert into customer_order ("order_id", "customer_id", "pizza_id", "exclusions", "extra", order_date)
values
 ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


  create table runner_order (
  "order_id" int,
  "runner_id" int,
  "pickup_time" varchar(20),
  "distance" varchar(10),
  "duration" varchar(10),
	"cancellation" varchar(23)
);
drop table if exists runner_order;
INSERT INTO runner_order
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

  

create table pizza_name(
	"pizza_id" int,
	"pizza_name" text
);
insert into pizza_name ("pizza_id", "pizza_name")
values
(1, 'Margherita'),
  (2, 'Vegetarian');

create table pizza_recipes(
	"pizza_id" int,
	"toppings" text
);
insert into pizza_recipes ("pizza_id", "toppings")
values
	(1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


create table pizza_toppings(
	"topping_id" int,
	"topping_name" text
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
 -- có bao nhiêu pizza đã được đặt hàng
select count(*) as total_pizzas
from customer_order

-- có bao nhiêu khách hàng đã đặt hàng
SELECT count (distinct customer_id) as total_customer from customer_order
-- có bao nhiêu đơn hàng đã được giao thành công
select count (distinct order_id) as success_order from runner_order
where cancellation is null

--- Có bao nhiêu loại pizza vận chuyển thành công
select count (distinct pizza_id) as total_pizza_delivered from customer_order
where order_id in (select order_id from runner_order where cancellation is null)

-- có bao nhiêu  pizza loại vegetarian và margherita đã được đặt hàng của mỗi khách hàng 
select customer_id,cast(pizza_name.pizza_name as varchar(50)) as pizza_name , count(*) as total_order
from customer_order
join pizza_name on customer_order.pizza_id = pizza_name.pizza_id
group by customer_id, cast( pizza_name.pizza_name as varchar(50) )
order by customer_id


-- có bao nhiêu đơn hàng đã được giao thành công có thay đổi so với đơn hàng gốc của khách hàng
select customer_order.customer_id,
sum(
case when (customer_order.exclusions is not null or customer_order.extra is not null)
then 1 else 0 end ) as total_with_change,
sum(
case when (customer_order.exclusions is null and customer_order.extra is null)
then 1 else 0 end ) as total_without_change
from customer_order
join runner_order
on customer_order.order_id = runner_order.order_id
where runner_order.cancellation is null
group by customer_order.customer_id
order by customer_order.customer_id


-- how many pizza orders were delivered that had both exclusions and extras
