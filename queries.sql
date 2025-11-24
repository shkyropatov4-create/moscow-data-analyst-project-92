-- Запрос 1: Общее количество покупателей
select count(customer_id) as customers_count
from customers;

-- Запрос 2: Топ-10 продавцов по суммарной выручке
select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(s.sales_id) as operations,
    floor(sum(p.price * s.quantity)) as income
from sales as s
inner join employees as e
    on s.sales_person_id = e.employee_id
inner join products as p
    on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name
order by income desc
limit 10;

-- Запрос 3: Продавцы со средней выручкой ниже общей средней
with seller_stats as (
    select
        e.employee_id,
        concat(e.first_name, ' ', e.last_name) as seller,
        count(s.sales_id) as total_operations,
        sum(p.price * s.quantity) as total_income,
        floor(sum(p.price * s.quantity) / count(s.sales_id)) as avg_income
    from sales as s
    inner join employees as e
        on s.sales_person_id = e.employee_id
    inner join products as p
        on s.product_id = p.product_id
    group by
        e.employee_id,
        e.first_name,
        e.last_name
),

overall_avg as (
    select floor(avg(p.price * s.quantity)) as overall_avg_income
    from sales as s
    inner join products as p
        on s.product_id = p.product_id
)

select ss.seller, ss.avg_income as average_income
from seller_stats as ss
cross join overall_avg as oa
where
    ss.avg_income < oa.overall_avg_income
order by ss.avg_income asc;

-- Запрос 4: Выручка по дням недели для каждого продавца
select
    concat(e.first_name, ' ', e.last_name) as seller,
    lower(to_char(s.sale_date, 'day')) as day_of_week,
    floor(sum(p.price * s.quantity)) as income
from sales as s
inner join employees as e
    on s.sales_person_id = e.employee_id
inner join products as p
    on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name,
    to_char(s.sale_date, 'day'),
    extract(dow from s.sale_date)
order by
    extract(dow from s.sale_date),
    seller;

-- Запрос 5: Возрастные группы покупателей
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    count(customer_id) as age_count
from customers
group by age_category
order by age_category;

-- Запрос 6: Покупатели и выручка по месяцам
select
    to_char(s.sale_date, 'YYYY-MM') as sale_month,
    count(distinct s.customer_id) as total_customers,
    round(sum(s.quantity * p.price), 0) as income
from sales as s
inner join products as p
    on s.product_id = p.product_id
group by to_char(s.sale_date, 'YYYY-MM')
order by sale_month asc;

-- Запрос 7: Покупатели с первой акционной покупкой
with first_purchases as (
    select
        c.customer_id,
        concat(c.first_name, ' ', c.last_name) as customer,
        s.sale_date,
        concat(e.first_name, ' ', e.last_name) as seller,
        p.price,
        row_number() over (
            partition by c.customer_id
            order by s.sale_date
        ) as purchase_rank
    from customers as c
    inner join sales as s
        on c.customer_id = s.customer_id
    inner join employees as e
        on s.sales_person_id = e.employee_id
    inner join products as p
        on s.product_id = p.product_id
)

select customer, sale_date, seller
from first_purchases
where
    purchase_rank = 1
    and price = 0
order by customer_id;
