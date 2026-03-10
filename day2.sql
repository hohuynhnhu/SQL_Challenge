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
select count (*) as total_pizza
from customer_order
join runner_order
on customer_order.order_id = runner_order.order_id
where runner_order.cancellation is null
and customer_order.exclusions is not null
and customer_order.extra is not null


-- what was the total volumne of pizzas ordered for earch hour of the day
select datepart(hour, order_date) as order_hour, count(*) as total_pizzas
from customer_order
group by datepart(hour, order_date)
order by order_hour;
 -- what was the volume of orders for each day of the week
 
select datename(weekday, order_date) as day_of_week, count(*) as total_orders
from customer_order
group by datename(weekday, order_date)

-- B runner and customer experience
--1 how many runners signed up each 1 week period
select datepart(week, registration_date) as week_number, count(*) as total_runners
from runner
group by datepart(week, registration_date)

-- 2 what was the arege time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order
select runner_order.runner_id, avg(DATEDIFF(minute, customer_order.order_date, runner_order.pickup_time)) as average_pickup_time
from customer_order
join runner_order
on customer_order.order_id = runner_order.order_id
where runner_order.cancellation is null
group by runner_order.runner_id

-- 3 is there any relationship between the number of pizza and how long the order takes to prepare
select customer_order.order_id, count(customer_order.pizza_id) as total_pizzas, DATEDIFF(minute, customer_order.order_date, runner_order.pickup_time) as preparation_time
from customer_order
join runner_order
on customer_order.order_id = runner_order.order_id
where runner_order.cancellation is null
group by customer_order.order_id, DATEDIFF(minute, customer_order.order_date, runner_order.pickup_time)

-- 4.what was the average distance traverlled for each customer
select customer_order.order_id, avg(cast(replace(runner_order.distance, 'km', '') as float)) as average_distance
from customer_order
join runner_order
on customer_order.order_id = runner_order.order_id
where runner_order.cancellation is null
group by customer_order.order_id


--5 what was the difference between the longest and shortest delivery times for all orders
select max(cast(replace(duration, ' mins', '') as int)) - min(cast(replace(duration, ' mins', '') as int)) as delivery_time_difference
from runner_order
where cancellation is null


-- 6 what was the average speed for each runner for each delivery and do you notice any trend for these values
select runner_id, order_id, cast(replace(distance, 'km', '') as float) / (cast(replace(duration, ' mins', '') as float) / 60) as average_speed_kmh
from runner_order
where cancellation is null

-- 7 what is the success delivery rate percentage for each runner
select runner_id, 
	   (count(case when cancellation is null then 1 end) * 100.0 / count(*)) as success_delivery_rate
	   from runner_order
	   group by runner_id

-- C ingredient Optimiation
-- 1 what are the standard ingredients for each pizza?
SELECT 
    CAST(pizza_name.pizza_name AS NVARCHAR(50)) AS pizza_name,
    STRING_AGG(CAST(pizza_toppings.topping_name AS NVARCHAR(50)), ', ') AS standard_ingredients
FROM pizza_recipes
JOIN pizza_name 
    ON pizza_recipes.pizza_id = pizza_name.pizza_id
JOIN pizza_toppings 
    ON CHARINDEX(
        ',' + CAST(pizza_toppings.topping_id AS NVARCHAR) + ',',
        ',' + CAST(pizza_recipes.toppings AS NVARCHAR(MAX)) + ','
    ) > 0
GROUP BY CAST(pizza_name.pizza_name AS NVARCHAR(50));

-- 2. what was the most commonly added extra
SELECT 
    CAST(pt.topping_name AS NVARCHAR(50)) AS topping_name,
    COUNT(*) AS total_extra
FROM customer_order co
CROSS APPLY STRING_SPLIT(co.extra, ',') s
JOIN pizza_toppings pt
    ON pt.topping_id = TRIM(s.value)
WHERE co.extra IS NOT NULL
AND co.extra <> 'null'
AND co.extra <> ''
GROUP BY CAST(pt.topping_name AS NVARCHAR(50))
ORDER BY total_extra DESC;

-- 3 what was the most common exclusion
select 
	CAST(pt.topping_name AS NVARCHAR(50)) AS topping_name,
	COUNT(*) AS total_exclusion
	from customer_order co
	cross apply string_split(co.exclusions, ',') s
	join pizza_toppings pt
	on pt.topping_id = TRIM(s.value)
	where co.exclusions is not null
	and co.exclusions <> 'null'
	and co.exclusions <> ''
	group by CAST(pt.topping_name AS NVARCHAR(50))
	order by total_exclusion desc

-- 4 generate an order item for each pizza record in the customer_order table in the format of one of the following 
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushrloom, Peppers
SELECT 
    co.order_id,
    co.customer_id,

    CAST(p.pizza_name AS NVARCHAR(50)) +

    CASE 
        WHEN co.exclusions IS NOT NULL 
        AND co.exclusions <> '' 
        AND co.exclusions <> 'null'
        THEN ' - Exclude ' + (
            SELECT STRING_AGG(CAST(pt.topping_name AS NVARCHAR(50)), ', ')
            FROM STRING_SPLIT(co.exclusions, ',') s
            JOIN pizza_toppings pt
                ON pt.topping_id = TRIM(s.value)
        )
        ELSE ''
    END +

    CASE 
        WHEN co.extra IS NOT NULL 
        AND co.extra <> '' 
        AND co.extra <> 'null'
        THEN ' - Extra ' + (
            SELECT STRING_AGG(CAST(pt.topping_name AS NVARCHAR(50)), ', ')
            FROM STRING_SPLIT(co.extra, ',') s
            JOIN pizza_toppings pt
                ON pt.topping_id = TRIM(s.value)
        )
        ELSE ''
    END AS order_item

FROM customer_order co
JOIN pizza_name p
    ON co.pizza_id = p.pizza_id;



-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH base_toppings AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        TRIM(s.value) AS topping_id
    FROM customer_order co
    JOIN pizza_recipes pr 
        ON co.pizza_id = pr.pizza_id
    CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS NVARCHAR(MAX)), ',') s
),

extra_toppings AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        TRIM(s.value) AS topping_id
    FROM customer_order co
    CROSS APPLY STRING_SPLIT(CAST(co.extra AS NVARCHAR(MAX)), ',') s
    WHERE co.extra IS NOT NULL
      AND co.extra <> ''
      AND co.extra <> 'null'
),

all_toppings AS (
    SELECT * FROM base_toppings
    UNION ALL
    SELECT * FROM extra_toppings
),

topping_count AS (
    SELECT
        at.order_id,
        at.pizza_id,
        CAST(pt.topping_name AS NVARCHAR(50)) AS topping_name,
        COUNT(*) AS topping_total
    FROM all_toppings at
    JOIN pizza_toppings pt
        ON pt.topping_id = at.topping_id
    GROUP BY
        at.order_id,
        at.pizza_id,
        CAST(pt.topping_name AS NVARCHAR(50))
)

SELECT
    CAST(p.pizza_name AS NVARCHAR(50)) + ': ' +
    STRING_AGG(
        CASE
            WHEN tc.topping_total > 1
                THEN '2x' + tc.topping_name
            ELSE tc.topping_name
        END
    , ', ')
    WITHIN GROUP (ORDER BY tc.topping_name)
FROM topping_count tc
JOIN pizza_name p
    ON p.pizza_id = tc.pizza_id
GROUP BY
    CAST(p.pizza_name AS NVARCHAR(50)),
    tc.order_id;

-- 6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


with delivered_orders as (
    select co.*
    from customer_order co
    join runner_order ro
        on co.order_id = ro.order_id
    where ro.cancellation is null or ro.cancellation = 'null' or ro.cancellation = ''

),
base_ingredients as (
    select do.order_id, do.pizza_id, TRIM(s.value) as ingredient_id
    from delivered_orders do
    join pizza_recipes pr
        on do.pizza_id = pr.pizza_id
    cross apply string_split(cast(pr.toppings as nvarchar(max)), ',') s
)
SELECT
    pt.topping_name,
    COUNT(*) AS total_used
FROM base_ingredients bt
JOIN pizza_toppings pt
    ON pt.topping_id = bt.ingredient_id
GROUP BY pt.topping_name
ORDER BY total_used DESC;


-- D pricing and ratings
--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select sum( case when pizza_id=1 then 12
when pizza_id = 2 then 10
end
) as total_revenue
from customer_order
join runner_order
on customer_order.order_id = runner_order.order_id
where runner_order.cancellation is null or runner_order.cancellation = 'null' or runner_order.cancellation = ''


-- 2 What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra
with delivered_orders as (
    select co.*
    from customer_order co
    join runner_order ro
        on co.order_id = ro.order_id
    where ro.cancellation is null
        or ro.cancellation = ''
        or ro.cancellation = 'null'
),
extras as (
    select 
        order_id,
        count(*) as extra_count,
        sum(case when trim(value) = '4' then 1 else 0 end) as extra_cheese
    from delivered_orders
    cross apply string_split(extra, ',')
    where extra is not null
        and extra <> ''
        and extra <> 'null'
    group by order_id
)

select 
sum(
    case 
        when pizza_id = 1 then 12
        when pizza_id = 2 then 10
    end
    + isnull(extra_count,0) 
    + isnull(extra_cheese,0)
) as total_revenue
from delivered_orders d
left join extras e
on d.order_id = e.order_id

-- 3 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
create table runner_ratings (
    rating_id int identity(1,1) primary key,
    order_id int,
    customer_id int,
    runner_id int,
    rating int check (rating between 1 and 5),
    rating_date datetime
);

insert into runner_ratings (order_id, customer_id, runner_id, rating, rating_date)
values
(1, 101, 1, 5, '2020-01-01 18:30:00'),
(2, 101, 1, 4, '2020-01-01 19:30:00'),
(3, 102, 1, 5, '2020-01-03 00:30:00'),
(4, 103, 2, 3, '2020-01-04 14:30:00'),
(5, 104, 3, 4, '2020-01-08 21:40:00'),
(7, 105, 2, 5, '2020-01-08 21:50:00'),
(8, 102, 2, 4, '2020-01-10 00:40:00'),
(10,104, 1, 5, '2020-01-11 19:10:00');

---4 Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas
WITH successful_orders AS (
    SELECT *
    FROM runner_order
    WHERE COALESCE(cancellation,'') IN ('','null')
),

pizza_count AS (
    SELECT 
        order_id,
        customer_id,
        MIN(order_date) AS order_time,
        COUNT(*) AS total_pizzas
    FROM customer_order
    GROUP BY order_id, customer_id
)

SELECT
pc.customer_id,
pc.order_id,
so.runner_id,
rr.rating,
pc.order_time,
so.pickup_time,

DATEDIFF(minute, pc.order_time, so.pickup_time) 
    AS time_between_order_pickup,

so.duration AS delivery_duration,

CAST(REPLACE(REPLACE(so.distance,'km',''),' ','') AS FLOAT) /
(CAST(REPLACE(REPLACE(REPLACE(so.duration,'minutes',''),'mins',''),'minute','') AS FLOAT)/60)
AS average_speed,

pc.total_pizzas

FROM pizza_count pc
JOIN successful_orders so
ON pc.order_id = so.order_id

LEFT JOIN runner_ratings rr
ON pc.order_id = rr.order_id

-- 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH successful_orders AS (
    SELECT *
    FROM runner_order
    WHERE COALESCE(cancellation,'') IN ('','null')
),

revenue AS (
    SELECT SUM(
        CASE 
            WHEN pizza_id = 1 THEN 12
            WHEN pizza_id = 2 THEN 10
        END
    ) AS total_revenue
    FROM customer_order co
    JOIN successful_orders so
    ON co.order_id = so.order_id
),

runner_cost AS (
    SELECT SUM(
        CAST(REPLACE(REPLACE(distance,'km',''),' ','') AS FLOAT) * 0.30
    ) AS total_runner_cost
    FROM successful_orders
)

SELECT 
total_revenue,
total_runner_cost,
total_revenue - total_runner_cost AS profit
FROM revenue, runner_cost;