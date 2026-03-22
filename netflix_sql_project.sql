create database final_netflix_db ;

use final_netflix_db ;

-- Count total number of titles in the dataset.
select count(distinct show_id) as total_titles
from  final_netflix  ;

-- Find how many Movies vs TV Shows are available.
select type , count(*) as total_count
 from final_netflix 
 group by type ;

-- List the top 5 countries with the most content.
select country ,count(*) as total_content
 from  final_netflix
 where country  is not null
  group by country 
  order by count(*) desc
  limit 5 ;
        
-- Find the most common rating (e.g., TV-MA, PG).
select rating , count(*) as total_rating 
from final_netflix
 group by  rating 
 order by count(*) desc ;

-- Show all titles released after 2020
select distinct title ,  release_year
from final_netflix
 where release_year >= 2021 ;
 
 -- Which genres have the highest number of titles?
 select genres ,count(*) as total_genres
 from final_netflix 
 group by genres
  order by count(*) desc
   limit 1 ;
   
 -- Find the top 10 most recent content additions.
 select   distinct title ,  type ,date_format(date_added, '%Y -%m') as date_added
 from final_netflix
 where date_added is not null
   order by date_added desc
 limit 10 ;
 
-- Which country produces the most TV Shows only?
 select  distinct country  , count(*) as total_tv_shows
 from final_netflix
where type = 'TV Show'
group by country 
 order by count(*)  desc 
 limit 1 ;
 
 -- Find the average release year of content on the platform
 select round(ifnull(avg(release_year),0),2) as avg_release_year
 from final_netflix  ;
 
 -- Which directors have created the most content?
select distinct director ,count(*) as total_content
from final_netflix 
group by director 
order by count(*) desc 
limit 5 ;

-- Which genres are driving the majority of content (with % share)?
with cte as (
select  distinct genres ,round(count(distinct genres)*100.0/count(genres),2) as pr_share
from final_netflix 
group by genres
 
 )
 select genres, pr_share 
 from cte 
 order by pr_share desc 
 limit 10 ;
 
 -- Find the year-wise growth of content added to the platform.
WITH cte AS (
  SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    COUNT(*) AS total_titles
  FROM final_netflix
  WHERE date_added IS NOT NULL
  GROUP BY year_added
)
SELECT 
  year_added,
  total_titles,
  total_titles - LAG(total_titles) OVER (ORDER BY year_added) AS growth
FROM cte;

 -- Identify countries with increasing content trend over time.
 
 WITH yearly_data AS (
  SELECT 
    country,
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    COUNT(*) AS total_titles
  FROM final_netflix
  WHERE date_added IS NOT NULL
    AND country IS NOT NULL
  GROUP BY country, year_added
),
growth_data AS (
  SELECT 
    country,
    year_added,
    total_titles,
    total_titles - LAG(total_titles) OVER (PARTITION BY country ORDER BY year_added) AS growth
  FROM yearly_data
)
SELECT DISTINCT country
FROM growth_data
WHERE growth > 0;

-- Which genre is most popular in each country?
WITH RECURSIVE split_data AS (
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
    SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1)) + 2) AS rest_country,
    TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
    SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS rest_genre
  FROM final_netflix

  UNION ALL

  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(rest_country, ',', 1)),
    SUBSTRING(rest_country, LENGTH(SUBSTRING_INDEX(rest_country, ',', 1)) + 2),
    TRIM(SUBSTRING_INDEX(rest_genre, ',', 1)),
    SUBSTRING(rest_genre, LENGTH(SUBSTRING_INDEX(rest_genre, ',', 1)) + 2)
  FROM split_data
  WHERE rest_country <> '' OR rest_genre <> ''
),

counts AS (
  SELECT 
    country,
    genre,
    COUNT(*) AS total
  FROM split_data
  WHERE country <> '' AND genre <> ''
  GROUP BY country, genre
),

ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY country ORDER BY total DESC) AS rnk
  FROM counts
)

SELECT country, genre, total
FROM ranked
WHERE rnk = 1;

-- Find the top 3 genres contributing to 50% of total content
WITH genre_counts AS (
  SELECT 
    listed_in AS genre,
    COUNT(*) AS total
  FROM final_netflix
  GROUP BY listed_in
),
total_count AS (
  SELECT SUM(total) AS grand_total FROM genre_counts
),
ranked AS (
  SELECT 
    g.genre,
    g.total,
    SUM(g.total) OVER (ORDER BY g.total DESC) AS running_total,
    t.grand_total
  FROM genre_counts g
  CROSS JOIN total_count t
)
SELECT 
  genre,
  total,
  ROUND((running_total / grand_total) * 100, 2) AS cumulative_percentage
FROM ranked
WHERE (running_total / grand_total) <= 0.5
limit 3 ;
 


  






 