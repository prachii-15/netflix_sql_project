drop table if exists netflix;
create table netflix(
	show_id varchar(10),
	type varchar(10),
	title varchar(150),
	director varchar(215),
	casts varchar(1000),
	country varchar(150),
	date_added varchar(50),
	release_year integer,
	rating varchar(10),
	duration varchar(15),
	listed_in varchar(100),
	description varchar(250)
);

select * from netflix;

select count(*) as total_count
from netflix;

select distinct type
from netflix

-- Business Problems
-- 1. count the number of movies and tv shows.
select type, count(*) 
from netflix
group by type

-- 2. find the most common rating for movies and tv shows.
with RatingCounts as (
	select type, rating, count(*) as rating_count
	from netflix
	group by type, rating
),
RankedRatings as (
	select type, rating, rating_count, 
	rank() over (partition by type order by rating_count desc) as rank
	from RatingCounts
)
select type, rating as most_frequent_rating
from RankedRatings
where rank = 1;

-- 3. list all movies released in a specific year (e.g. 2020)
select * 
from netflix
where release_year=2020

-- 4. find the top 5 countries with the most content on netlix
select *
from 
(
	select unnest(string_to_array(country, ',')) as country,
	count(*) as total_content
	from netflix
	group by 1
) as t1
where country is not null
order by total_content desc
limit 5

-- 5. identify the longest movie
select * 
from netflix
where type = 'Movie'
order by split_part(duration, ' ',1)::int desc

-- 6. find content added in the last 5 years
select * 
from netflix
where to_date(date_added, 'Month DD, YYYY') >= current_date - interval '5 years'

--7. find all the movies/tv shows by director 'Rajiv Chilaka'
SELECT *
FROM (
    SELECT *,
           UNNEST(string_to_array(director, ',')) AS director_name
    FROM netflix
    WHERE director IS NOT NULL
) AS subquery
WHERE TRIM(director_name) = 'Rajiv Chilaka'

--8. list all tv shows with more than 5 season
select *
from netflix
where type = 'TV Show' and split_part(duration,' ',1)::int > 5

--9. count the number of content items in each genre
select unnest(string_to_array(listed_in,',')) as genre,
count(*) as total_content
from netflix
group by 1

--10. find each year and the average numbers of content release by india on netflix.
-- return top 5 year with the highest avg content release.
select country, release_year, count(show_id) as total_release,
round(
	count(show_id)::numeric/
	(select count(show_id) from netflix where country = 'India')::numeric*100, 2	
) as avg_release
from netflix
where country='India'
group by country,2
order by avg_release desc
limit 5

--11. list all movies that are documentaries
select * from netflix
where listed_in like '%Documentaries'

--12. find all content without a director
select * from netflix
where director is null

--13. find how many movies actor 'salman khan' appeared in last 10 years
select * from netflix
where casts like '%Salman Khan%' and release_year > extract(year from current_date) - 10

--14. find the top 10 actors who have appearend in the highest number of movies produced in india.
select unnest(string_to_array(casts,',')) as actor, count(*)
from netflix
where country = 'India'
group by 1
order by 2 desc
limit 10

--15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
--the description field. Label content containing these keywords as 'Bad' and all other 
--content as 'Good'. Count how many items fall into each category.

select category, type, count(*) as content_count
from(
	select *,
	case 
		when description ilike '%kill%' or description ilike '%violence%' then 'Bad'
		else 'Good'
	end as category
	from netflix
) as categorized_content
group by 1,2
order by 2