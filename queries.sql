-- Запрос 1: Общее количество покупателей
select count(customer_id) as customers_count
from customers;

-- Запрос 2: Топ-10 продавцов по суммарной выручке
-- Объединяем имя и фамилию продавца в одну строку
-- Считаем общее количество уникальных сделок для каждого продавца
-- Вычисляем общую выручку (цена товара × количество)
-- Соединяем таблицу продаж с таблицей сотрудников
-- Соединяем таблицу продаж с таблицей продуктов
-- Группируем данные по каждому продавцу
-- Сортируем результат по выручке от большей к меньшей
-- Ограничиваем результат 10 записями (топ-10 продавцов)
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
-- Расчет статистики по каждому продавцу
-- Полное имя продавца
-- Общее количество сделок продавца
-- Общая выручка продавца
-- Средняя выручка за сделку
-- Группировка по продавцам 
-- Расчет общей средней выручки за сделку по всей компании
-- Средняя выручка за одну сделку по всем продажам компании
-- Фильтруем продавцов
-- Сортируем по возрастанию средней выручки 
with seller_stats as (
    select
        e.employee_id,
        concat(e.first_name, ' ', e.last_name) as seller,
        count(s.sales_id) as total_operations,
        sum(p.price * s.quantity) as total_income,
        avg(p.price * s.quantity) / count(s.sales_id) as avg_income
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

select
    ss.seller,
    ss.avg_income as average_income
from seller_stats as ss
cross join overall_avg as oa
where
    ss.avg_income < oa.overall_avg_income
order by ss.avg_income asc;

-- Запрос 4: Выручка по дням недели для каждого продавца
-- Полное имя продавца
-- Название дня недели в нижнем регистре
-- Суммарная выручка продавца в конкретный день недели
-- Группировка данных по продавцу и дню недели
-- Группировка по текстовому представлению дня недели
-- Группируем по числовому представлению дня недели
-- Сортируем результаты:
-- Сначала по порядковому номеру дня недели
-- Затем по имени продавца в алфавитном порядке
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
    extract(isodow from s.sale_date)
order by
    extract(isodow from s.sale_date),
    seller;

-- Запрос 5: Возрастные группы покупателей
-- Определяем возрастную категорию на основе возраста покупателя,
-- Считаем количество покупателей в каждой категории,
-- Группируем по возрастным категориям для агрегации
-- Сортируем по возрастным категориям для упорядоченного вывода
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    count(*) as age_count
from customers
group by age_category
order by age_category;

-- Запрос 6: Покупатели и выручка по месяцам
-- Форматируем дату продажи в формат ГОД-МЕСЯЦ
-- Считаем количество уникальных покупателей за месяц
-- Рассчитываем общую выручку (количество товаров * цена) 
-- Соединяем с таблицей продуктов для получения цен
-- Группируем по месяцам для агрегации данных
-- Сортируем по дате в возрастающем порядке
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
-- Объединяем имя и фамилию покупателя
-- Объединяем имя и фамилию продавца
-- Нумеруем покупки каждого покупателя по дате 
-- Соединяем таблицу покупателей с продажами
-- Соединяем с таблицей сотрудников для данных о продавце
-- Соединяем с таблицей продуктов для проверки цены
-- Основной запрос для выборки данных из CTE
-- Фильтруем: берем только первые покупки 
-- и только акционные товары (price = 0)
-- Сортируем по ID покупателя 
with first_purchases as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        s.sale_date,
        e.first_name as seller_first_name,
        e.last_name as seller_last_name,
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
    where p.price = 0  -- фильтр перемещен в CTE
)

select
    first_name,
    last_name,
    sale_date,
    seller_first_name,
    seller_last_name,
    concat(first_name, ' ', last_name) as customer,
    concat(seller_first_name, ' ', seller_last_name) as seller
from first_purchases
where purchase_rank = 1
order by customer_id;

