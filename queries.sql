select count(customer_id) as customers_count 
from customers
--запрос, который считает общее количество покупателей из таблицы customers


--ОТЧЕТ 1: Десятка лучших продавцов по суммарной выручке
SELECT 
    -- Объединяем имя и фамилию продавца в одну строку
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    -- Считаем общее количество уникальных сделок для каждого продавца
    COUNT(s.sales_id) as operations,
    -- Вычисляем общую выручку (цена товара × количество) и округляем в меньшую сторону
    FLOOR(SUM(p.price * s.quantity)) as income
FROM sales s
-- Соединяем таблицу продаж с таблицей сотрудников для получения информации о продавцах
JOIN employees e ON s.sales_person_id = e.employee_id
-- Соединяем таблицу продаж с таблицей продуктов для получения цен товаров
JOIN products p ON s.product_id = p.product_id
-- Группируем данные по каждому продавцу для агрегации показателей
GROUP BY e.employee_id, e.first_name, e.last_name
-- Сортируем результат по выручке от большей к меньшей
ORDER BY income DESC
-- Ограничиваем результат 10 записями - топ-10 продавцов
LIMIT 10;


-- ОТЧЕТ 2: Продавцы со средней выручкой за сделку ниже общей средней
WITH seller_stats AS (
    -- CTE (Common Table Expression) для расчета статистики по каждому продавцу
    SELECT 
        e.employee_id,
        -- Полное имя продавца
        CONCAT(e.first_name, ' ', e.last_name) as seller,
        -- Общее количество сделок продавца
        COUNT(s.sales_id) as total_operations,
        -- Общая выручка продавца
        SUM(p.price * s.quantity) as total_income,
        -- Средняя выручка за сделку (общая выручка / количество сделок), округленная вниз
        FLOOR(SUM(p.price * s.quantity) / COUNT(s.sales_id)) as avg_income
    FROM sales s
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
    -- Группируем по продавцам для расчета индивидуальных показателей
    GROUP BY e.employee_id, e.first_name, e.last_name
),
overall_avg AS (
    -- CTE для расчета общей средней выручки за сделку по всей компании
    SELECT 
        -- Средняя выручка за одну сделку по всем продажам компании, округленная вниз
        FLOOR(AVG(p.price * s.quantity)) as overall_avg_income
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
)
-- Основной запрос, который сравнивает показатели продавцов с общей средней
SELECT 
    ss.seller,
    ss.avg_income as average_income
FROM seller_stats ss, overall_avg oa
-- Фильтруем только тех продавцов, чья средняя выручка ниже общей средней по компании
WHERE ss.avg_income < oa.overall_avg_income
-- Сортируем по возрастанию средней выручки - от наименьшей к наибольшей
ORDER BY ss.avg_income ASC;

-- ОТЧЕТ 3: Выручка по дням недели для каждого продавца
SELECT 
    -- Полное имя продавца
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    -- Название дня недели в нижнем регистре (например, 'monday', 'tuesday')
    LOWER(TO_CHAR(s.sale_date, 'day')) as day_of_week,
    -- Суммарная выручка продавца в конкретный день недели, округленная вниз
    FLOOR(SUM(p.price * s.quantity)) as income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
-- Группируем данные по продавцу и дню недели для получения дневной статистики
GROUP BY 
    e.employee_id, 
    e.first_name, 
    e.last_name, 
    -- Группируем по текстовому представлению дня недели
    TO_CHAR(s.sale_date, 'day'),
    -- Группируем по числовому представлению дня недели (для правильной сортировки)
    EXTRACT(dow FROM s.sale_date)
-- Сортируем результаты:
ORDER BY 
    -- Сначала по порядковому номеру дня недели (понедельник=1, воскресенье=7)
    EXTRACT(dow FROM s.sale_date),
    -- Затем по имени продавца в алфавитном порядке
    seller;







-- ОТЧЕТ 1: Возрастные группы покупателей
SELECT 
    -- Определяем возрастную категорию на основе возраста покупателя
    CASE 
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    -- Считаем количество покупателей в каждой категории
    COUNT(*) AS age_count
FROM customers c
-- Группируем по возрастным категориям для агрегации
GROUP BY 
    CASE 
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END
-- Сортируем по возрастным категориям для упорядоченного вывода
ORDER BY age_category;


-- ОТЧЕТ 2: Покупатели и выручка по месяцам
SELECT 
    -- Форматируем дату продажи в формат ГОД-МЕСЯЦ
    TO_CHAR(s.sale_date, 'YYYY-MM') AS date,
    -- Считаем количество уникальных покупателей за месяц
    COUNT(DISTINCT s.customer_id) AS total_customers,
    -- Рассчитываем общую выручку (количество товаров * цена) и округляем до целого
    ROUND(SUM(s.quantity * p.price), 0) AS income
FROM sales s
-- Соединяем с таблицей продуктов для получения цен
JOIN products p ON s.product_id = p.product_id
-- Группируем по месяцам для агрегации данных
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
-- Сортируем по дате в возрастающем порядке
ORDER BY date ASC;


-- ОТЧЕТ 3: Покупатели с первой акционной покупкой
WITH first_purchases AS (
    SELECT 
        c.customer_id,
        -- Объединяем имя и фамилию покупателя
        CONCAT(c.first_name, ' ', c.last_name) AS customer,
        s.sale_date,
        -- Объединяем имя и фамилию продавца
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        p.price,
        -- Нумеруем покупки каждого покупателя по дате (1 - первая покупка)
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY s.sale_date) as purchase_rank
    FROM customers c
    -- Соединяем таблицу покупателей с продажами
    JOIN sales s ON c.customer_id = s.customer_id
    -- Соединяем с таблицей сотрудников для данных о продавце
    JOIN employees e ON s.sales_person_id = e.employee_id
    -- Соединяем с таблицей продуктов для проверки цены
    JOIN products p ON s.product_id = p.product_id
)
-- Основной запрос для выборки данных из CTE
SELECT 
    customer,
    sale_date,
    seller
FROM first_purchases
-- Фильтруем: берем только первые покупки (purchase_rank = 1)
-- и только акционные товары (price = 0)
WHERE purchase_rank = 1 AND price = 0
-- Сортируем по ID покупателя для упорядоченного вывода
ORDER BY customer_id;