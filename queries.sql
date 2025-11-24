select count(customer_id) as customers_count
from customers;
--запрос, который считает общее количество покупателей из таблицы customers
select
    concat(e.first_name, ' ', e.last_name) as seller,
    count(s.sales_id) as operations,
    floor(sum(p.price * s.quantity)) as income
from sales s
join employees e on s.sales_person_id = e.employee_id
join products p on s.product_id = p.product_id
group by e.employee_id, e.first_name, e.last_name
order by income desc
limit 10;
-- Отчет: Десятка лучших продавцов по суммарной выручке.
-- Объединяем имя и фамилию продавца в одну строку,
-- Считаем общее количество уникальных сделок для каждого продавца,
-- Вычисляем общую выручку (цена товара × количество) и округляем в меньшую сторону,
-- Соединяем таблицу продаж с таблицей сотрудников для получения информации о продавцах,
-- Соединяем таблицу продаж с таблицей продуктов для получения цен товаров,
-- Группируем данные по каждому продавцу для агрегации показателей,
-- Сортируем результат по выручке от большей к меньшей,
-- Ограничиваем результат 10 записями (топ-10 продавцов).
with seller_stats as (
    select
        e.employee_id,
        concat(e.first_name, ' ', e.last_name) as seller,
        count(s.sales_id) as total_operations,
        sum(p.price * s.quantity) as total_income,
        floor(sum(p.price * s.quantity) / count(s.sales_id)) as avg_income
    from sales s
    join employees e on s.sales_person_id = e.employee_id
    join products p on s.product_id = p.product_id
    group by e.employee_id, e.first_name, e.last_name),
overall_avg as (
    select
    floor(avg(p.price * s.quantity)) as overall_avg_income
    from sales s
    join products p on s.product_id = p.product_id)
select 
    ss.seller,
    ss.avg_income as average_income
from seller_stats ss, overall_avg oa
where ss.avg_income < oa.overall_avg_income
order by ss.avg_income asc;
-- Отчет: Продавцы со средней выручкой за сделку ниже общей средней.
-- CTE (Common Table Expression) для расчета статистики по каждому продавцу,
-- Полное имя продавца,
-- Общее количество сделок продавца,
-- Общая выручка продавца,
-- Средняя выручка за сделку (общая выручка / количество сделок),
-- Группировка по продавцам для расчета индивидуальных показателей,
-- CTE для расчета общей средней выручки за сделку по всей компании.
-- Средняя выручка за одну сделку по всем продажам компании,
-- Основной запрос, который сравнивает показатели продавцов с общей средней.
-- Фильтруем только тех продавцов, чья средняя выручка ниже общей средней по компании,
-- Сортируем по возрастанию средней выручки - от наименьшей к наибольшей.
select
    concat(e.first_name, ' ', e.last_name) as seller,
    lower(to_char(s.sale_date, 'day')) as day_of_week,
    floor(sum(p.price * s.quantity)) as income
from sales s
join employees e on s.sales_person_id = e.employee_id
join products p on s.product_id = p.product_id
group by 
    e.employee_id,
    e.first_name,
    e.last_name,
    to_char(s.sale_date, 'day'),
    extract(dow from s.sale_date)
order by 
    extract(dow from s.sale_date),
    seller;
-- Отчет: Выручка по дням недели для каждого продавца,
-- Полное имя продавца,
-- Название дня недели в нижнем регистре (например, 'monday', 'tuesday'),
-- Суммарная выручка продавца в конкретный день недели, округленная вниз,
-- Группировка данных по продавцу и дню недели для получения дневной статистики,
-- Группировка по текстовому представлению дня недели,
-- Группируем по числовому представлению дня недели (для правильной сортировки),
-- Сортируем результаты:
-- Сначала по порядковому номеру дня недели (понедельник=1, воскресенье=7),
-- Затем по имени продавца в алфавитном порядке.
select
    case
        when c.age between 16 and 25 then '16-25'
        when c.age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    count(*) as age_count
from customers c
group by
    case
        when c.age between 16 and 25 then '16-25'
        when c.age between 26 and 40 then '26-40'
        else '40+'
    end
order by age_category;
-- Отчет: Возрастные группы покупателей.
-- Определяем возрастную категорию на основе возраста покупателя,
-- Считаем количество покупателей в каждой категории,
-- Группируем по возрастным категориям для агрегации
-- Сортируем по возрастным категориям для упорядоченного вывода.
select
    to_char(s.sale_date, 'YYYY-MM') as date,
    count(distinct s.customer_id) as total_customers,
    round(sum(s.quantity * p.price), 0) as income
from sales s
join products p on s.product_id = p.product_id
group by to_char(s.sale_date, 'YYYY-MM')
order by date asc;
-- Отчет: Покупатели и выручка по месяцам
-- Форматируем дату продажи в формат ГОД-МЕСЯЦ
-- Считаем количество уникальных покупателей за месяц
-- Рассчитываем общую выручку (количество товаров * цена) и округляем до целого
-- Соединяем с таблицей продуктов для получения цен
-- Группируем по месяцам для агрегации данных
-- Сортируем по дате в возрастающем порядке
with first_purchases as (
    select
        c.customer_id,
        concat(c.first_name, ' ', c.last_name) as customer,
        s.sale_date,
        concat(e.first_name, ' ', e.last_name) as seller,
        p.price,
        row_number() over (partition by c.customer_id order by s.sale_date) as purchase_rank
    from customers c
    join sales s on c.customer_id = s.customer_id
    join employees e on s.sales_person_id = e.employee_id
    join products p on s.product_id = p.product_id
)
select
    customer,
    sale_date,
    seller
from first_purchases
where purchase_rank = 1 and price = 0
order by customer_id;
-- Отчет: Покупатели с первой акционной покупкой,
-- Объединяем имя и фамилию покупателя,
-- Объединяем имя и фамилию продавца,
-- Нумеруем покупки каждого покупателя по дате (1 - первая покупка),
-- Соединяем таблицу покупателей с продажами,
-- Соединяем с таблицей сотрудников для данных о продавце,
-- Соединяем с таблицей продуктов для проверки цены.
-- Основной запрос для выборки данных из CTE
-- Фильтруем: берем только первые покупки (purchase_rank = 1)
-- и только акционные товары (price = 0),
-- Сортируем по ID покупателя для упорядоченного вывода.
