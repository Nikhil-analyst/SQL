-- 1st Answer

select customer_id, sum(menu.price) from menu
join sales on menu.product_id = sales.product_id
group by sales.customer_id;





-- 2nd Answer
select customer_id, count(distinct(order_date)) from sales
group by customer_id;


-- 3rd Answer (try with removing first_rank line then you will get idea more clear)

WITH ordered_sales_cte AS
(
 SELECT customer_id, order_date, product_name,
  DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY s.order_date) AS rank_,
  row_number() over (partition by customer_id order by customer_id) as first_rank
 FROM sales AS s
 JOIN menu AS m
  ON s.product_id = m.product_id
)

SELECT customer_id, product_name, order_date
FROM ordered_sales_cte
WHERE rank_ = 1 and first_rank=1
GROUP BY customer_id, product_name;


-- 4 Answer 

with table_most_purchased as
(
	select product_name,(count(sales.product_id)) as most_purchased from sales
	join menu on sales.product_id = menu.product_id
	group by product_name
)
select product_name,most_purchased from table_most_purchased
order by most_purchased desc
limit 1;


-- 5 Answer
-- Which item was the most popular for each customer?

with count_of_product_ordered as 
(
	select customer_id,product_name, count(s.product_id) as count_product,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rankk 
    from sales as s 
	join menu as m on s.product_id = m.product_id
	group by s.customer_id, s.product_id
)
select customer_id,product_name, count_product from count_of_product_ordered
where rankk = 1
;



-- 6 
--  Which item was purchased first by the customer after they became a member?

with member_sales_cte as 
(
	select s.customer_id as customer_id, s.product_id as product_id, order_date, join_date, product_name
	,DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY (s.order_date) DESC) AS rankk 
	from sales as s 
	join members as m on s.customer_id = m.customer_id
    join menu on s.product_id = menu.product_id
	where s.order_date <= m.join_date
)
select customer_id, product_id, product_name, order_date, join_date from member_sales_cte
where rankk = 1;

-- 7
-- Which item was purchased just before the customer became a member?

with member_sales_cte as 
(
	select s.customer_id as customer_id, s.product_id as product_id, order_date, join_date, product_name
	,DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY (s.order_date) desc) AS rankk 
	from sales as s 
	join members as m on s.customer_id = m.customer_id
    join menu on s.product_id = menu.product_id
	where s.order_date < m.join_date
)
select customer_id, product_id, product_name, order_date, join_date from member_sales_cte
where rankk = 1;


-- 8 
-- What is the total items and amount spent for each member before they became a member?

select s.customer_id as ID, count(distinct s.product_id) as Unique_Items_Ordered, sum(m.price) as total_sales
from sales as s  
join menu as  m on s.product_id = m.product_id
join members as mem on s.customer_id = mem.customer_id 
where s.order_date < mem.join_date
group by s.customer_id;


-- 9
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?


WITH price_points AS
 (
 SELECT *, 
 CASE
  WHEN product_id = 1 THEN price * 20
  ELSE price * 10
  END AS points
 FROM menu
 )

SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points AS p
JOIN sales AS s
 ON p.product_id = s.product_id
GROUP BY s.customer_id;


-- 10
-- In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

WITH dates_cte AS 
(
 SELECT *, 
  DATE_ADD("2021-01-06", interval 6 day) AS valid_date, 
  LAST_DAY('2021-01-31') AS last_date
 FROM members AS m
)
SELECT d.customer_id, s.order_date, d.join_date, 
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM(CASE
  WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
  WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
  ELSE 10 * m.price
  END) AS points
FROM dates_cte AS d
JOIN sales AS s
 ON d.customer_id = s.customer_id
JOIN menu AS m
 ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price;



-- 															BONUS
-- 															BONUS
-- 															BONUS
-- 															BONUS
-- 															BONUS


with members_list as
(
SELECT s.customer_id as ID, s.order_date as order_date, m.product_name, m.price as price,
CASE
 WHEN mem.join_date > s.order_date THEN 'N'
 WHEN mem.join_date <= s.order_date THEN 'Y'
 ELSE 'N'
 END AS member
FROM sales AS s
LEFT JOIN menu AS m
 ON s.product_id = m.product_id
LEFT JOIN members AS mem
 ON s.customer_id = mem.customer_id
)
select *, 
CASE
when members_list.member = 'N' then NULL
when members_list.member = 'Y' then DENSE_RANK() OVER (PARTITION BY members_list.ID, members_list.member ORDER BY members_list.order_date)
ELSE Null
end as ranking
from members_list
order by members_list.ID, ranking;


-- Checkout these posts for more information
-- https://medium.com/analytics-vidhya/8-week-sql-challenge-case-study-week-1-dannys-diner-2ba026c897ab

