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