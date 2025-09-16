/* Query 1 */
SELECT c.name AS category_name, 
COUNT(fc.film_id) AS film_count 
FROM category as c 
JOIN film_category fc ON fc.category_id=c.category_id 
GROUP BY c.name 
ORDER BY film_count DESC;

/* Query 2 */
SELECT a.actor_id,
       a.first_name || ' ' || a.last_name AS actor_name,
       COUNT(r.rental_id) AS rental_count 
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id 
JOIN film f ON fa.film_id = f.film_id 
JOIN inventory i ON f.film_id = i.film_id 
JOIN rental r ON i.inventory_id = r.inventory_id 
GROUP BY a.actor_id, a.first_name, a.last_name 
ORDER BY rental_count DESC
LIMIT 10;

/* Query 3 */
SELECT c.name AS category,
       SUM(p.amount) AS total_revenue
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY total_revenue DESC
LIMIT 1;

/* Query 4. Option 1 */
SELECT f.film_id, f.title
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.film_id IS NULL
ORDER BY f.film_id;

/* Query 4. Option 2*/
SELECT f.film_id, f.title
FROM film f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.film_id = f.film_id
)
ORDER BY f.film_id;

/* Query 4. Option 3*/
SELECT f.film_id, f.title
FROM film f
EXCEPT
SELECT f.film_id, f.title
FROM film f
JOIN inventory i ON f.film_id = i.film_id
ORDER BY film_id;

/* Query 5 */
WITH actor_film_count AS (
    SELECT 
        a.actor_id,
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
        COUNT(fa.film_id) AS film_count
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film_category fc ON fa.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Children'
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT actor_id, actor_name, film_count
FROM (
    SELECT *,
           RANK() OVER (ORDER BY film_count DESC) AS ranked
    FROM actor_film_count
) AS ranked_actors
WHERE ranked <= 3
ORDER BY film_count DESC;

/* Query 6 */
SELECT
    ci.city,
    COUNT(*) FILTER (WHERE cu.active = 1) AS active_count,
    COUNT(*) FILTER (WHERE cu.active = 0) AS inactive_count
FROM city ci
LEFT JOIN address a ON ci.city_id = a.city_id
LEFT JOIN customer cu ON a.address_id = cu.address_id
GROUP BY ci.city
ORDER BY inactive_count DESC;

/* Query 7 */
WITH rental_hours AS (
    SELECT
        c.city,
        cat.name AS category_name,
        EXTRACT(EPOCH FROM (r.return_date - r.rental_date))/3600 AS hours
    FROM rental r
    JOIN customer cu ON r.customer_id = cu.customer_id
    JOIN address a ON cu.address_id = a.address_id
    JOIN city c ON a.city_id = c.city_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category cat ON fc.category_id = cat.category_id
    WHERE c.city ILIKE 'a%' OR c.city LIKE '%-%'
),
category_totals AS (
    SELECT
        city,
        category_name,
        SUM(hours) AS total_hours,
        RANK() OVER (PARTITION BY city ORDER BY SUM(hours) DESC) AS rnk
    FROM rental_hours
    GROUP BY city, category_name
)
SELECT city, category_name, total_hours
FROM category_totals
WHERE rnk = 1
ORDER BY city;