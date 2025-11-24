select
    count(customer_id) as customers_count
from
    customers;

-- Подсчет общего количества покупателей в базе данных
-- Используется простая агрегатная функция count
-- для получения общего числа записей в таблице customers

select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(s.sales_id) as operations,
    floor(sum(p.price * s.quantity)) as income
from
    sales as s
inner join
    employees as e
    on s.sales_person_id = e.employee_id
inner join
    products as p
    on s.product_id = p.product_id
group by
    e.employee_id,
    e.first_name,
    e.last_name
order by
    income desc
limit 10;

-- Топ-10 продавцов по суммарной выручке
-- Объединяет данные из трех таблиц: sales, employees и products
-- Группирует по продавцам для расчета:
--   количества операций (уникальных продаж)
--   общей выручки (сумма произведений цены на количество)
-- Выручка округляется в меньшую сторону с помощью floor
-- Результат сортируется по убыванию выручки и ограничивается 10 записями

with seller_stats as (
    select
        e.employee_id,
        concat(e.first_name, ' ', e.last_name) as seller,
        count(s.sales_id) as total_operations,
        sum(p.price * s.quantity) as total_income,
        floor(sum(p.price * s.quantity) / count(s.sales_id)) as avg_income
    from
        sales as s
    inner join
        employees as e
        on s.sales_person_id = e.employee_id
    inner join
        products as p
        on s.product_id = p.product_id
    group by
        e.employee_id,
        e.first_name,
        e.last_name
),

overall_avg as (
    select
        floor(avg(p.price * s.quantity)) as overall_avg_income
    from
        sales as s
    inner join
        products as p
        on s.product_id = p.product_id
)

select
    ss.seller,
    ss.avg_income as average_income
from
    seller_stats as ss
cross join
    overall_avg as oa
where
    ss.avg_income < oa.overall_avg_income
order by
    ss.avg_income asc;

-- Анализ продавцов с низкой средней выручкой за сделку
-- Первое CTE (seller_stats) рассчитывает для каждого продавца:
--   общее количество операций
--   общую выручку
--   среднюю выручку за сделку (общая выручка / количество операций)
-- Второе CTE (overall_avg) вычисляет общую среднюю выручку по всем сделкам
-- Основной запрос выбирает продавцов, у которых средняя выручка
-- ниже общей средней по компании
-- Результат сортируется по возрастанию средней выручки

select
    concat(e.first_name, ' ', e.last_name) as seller,
    lower(to_char(s.sale_date, 'day')) as day_of_week,
    floor(sum(p.price * s.quantity)) as income
from
    sales as s
inner join
    employees as e
    on s.sales_person_id = e.employee_id
inner join
    products as p
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

-- Анализ выручки по дням недели для каждого продавца
-- Преобразует дату в название дня недели в нижнем регистре
-- Группирует данные по продавцу и дню недели
-- Использует двойную группировку: по текстовому и числовому представлению дня
-- для обеспечения корректной агрегации и сортировки
-- Сортировка сначала по порядковому номеру дня недели (понедельник=0),
-- затем по имени продавца в алфавитном порядке

select
    case
        when c.age between 16 and 25 then '16-25'
        when c.age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    count(*) as age_count
from
    customers as c
group by
    case
        when c.age between 16 and 25 then '16-25'
        when c.age between 26 and 40 then '26-40'
        else '40+'
    end
order by
    age_category;

-- Распределение покупателей по возрастным категориям
-- Использует выражение CASE для классификации возраста на три группы:
--   16-25 лет: молодежь
--   26-40 лет: взрослые
--   40+ лет: старшая возрастная группа
-- Подсчитывает количество покупателей в каждой категории
-- Группировка выполняется по тому же выражению CASE,
-- что и в SELECT, для корректной агрегации данных

select
    to_char(s.sale_date, 'YYYY-MM') as date,
    count(distinct s.customer_id) as total_customers,
    round(sum(s.quantity * p.price), 0) as income
from
    sales as s
inner join
    products as p
    on s.product_id = p.product_id
group by
    to_char(s.sale_date, 'YYYY-MM')
order by
    date asc;

-- Ежемесячная статистика по покупателям и выручке
-- Форматирует дату в формат 'ГГГГ-ММ' для группировки по месяцам
-- Считает количество уникальных покупателей за каждый месяц
-- с использованием count(distinct)
-- Рассчитывает общую выручку за месяц с округлением до целого числа
-- Группировка выполняется по отформатированной дате
-- Результат сортируется в хронологическом порядке

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
    from
        customers as c
    inner join
        sales as s
        on c.customer_id = s.customer_id
    inner join
        employees as e
        on s.sales_person_id = e.employee_id
    inner join
        products as p
        on s.product_id = p.product_id
)

select
    customer,
    sale_date,
    seller
from
    first_purchases
where
    purchase_rank = 1
    and price = 0
order by
    customer_id;

-- Идентификация покупателей, совершивших первую покупку по акции (цена = 0)
-- CTE first_purchases использует оконную функцию row_number()
-- для нумерации покупок каждого покупателя в хронологическом порядке
-- Основной запрос фильтрует:
--   только первые покупки (purchase_rank = 1)
--   только акционные товары (price = 0)
-- Возвращает информацию о покупателе, дате покупки и продавце
-- для последующего анализа акционных клиентов