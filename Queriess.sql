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