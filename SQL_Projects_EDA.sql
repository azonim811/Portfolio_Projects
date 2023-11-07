/*
Covid 19 Data Exploration
Skills used: JOINs, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
USE projects;

# See the table
SELECT *
FROM covid_deaths;	-- 10081 row(s) returned

SELECT *
FROM covid_vaccination;	-- 10081 row(s) returned

# Converting date from '13/02/21' to '2021-02-13'
ALTER TABLE covid_deaths 
ADD COLUMN corrected_date DATE AFTER location;	-- add a new column with the corrected date format

UPDATE covid_deaths
SET corrected_date = STR_TO_DATE(date, '%d/%m/%y');	-- set the new column with the converted date values

ALTER TABLE covid_deaths 
DROP COLUMN date;	-- drop the original date column

ALTER TABLE covid_deaths 
RENAME COLUMN corrected_date TO date;	-- change the name back to its original

# Set up for most observation
SELECT location, date, population, total_cases, total_deaths
FROM covid_deaths
ORDER BY 1, 2;

# Looking at total cases against total deaths
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths / total_cases) * 100, 2) AS death_percentage	-- percentage likelihood of dying if contracted, in your country 
FROM covid_deaths
WHERE location = 'United States'	-- or WHERE location LIKE ('%states%')
ORDER BY 1, 2;

# Looking at total cases against the population
SELECT location, date, population, total_cases, (total_cases / population) * 100 AS population_percentage	-- population percentage who got contracted
FROM covid_deaths
WHERE location = 'United States'	
ORDER BY 1, 2;

# List the countries with the highest contraction rate of its population 
SELECT location, population, MAX(total_cases) AS highest_casecount, MAX((total_cases / population)) * 100 AS population_percentage 
FROM covid_deaths
GROUP BY location, population
ORDER BY population_percentage DESC;	

# List the countries with the highest death count encountered
SELECT location, MAX(total_deaths) AS highest_deathcount
FROM covid_deaths					-- results has group of continents in the location
WHERE continent IS NOT NULL			-- to resolve this, add WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_deathcount DESC;	
									 	
# Breaking it down by continent
SELECT continent, MAX(total_deaths) AS highest_deathcount
FROM covid_deaths
GROUP BY continent
ORDER BY highest_deathcount DESC;	-- the result under North America seems other countries' count is not included

# Looking at global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_percentage	
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;	-- results will be per day if just the global total then take out column date and GROUP BY date
			-- just the global total then take out column date and GROUP BY date
			SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_percentage	
			FROM covid_deaths
			WHERE continent IS NOT NULL;	

# Joining the two tables and looking at global population that has been vaccinated 
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM covid_deaths d
JOIN covid_vaccination v
	ON d.location = v.location AND d.date =  v.date
WHERE d.continent IS NOT NULL    
ORDER BY 2, 3;
	
    -- we are going to add a rolling count on the new vaccinations using Window Functions
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		SUM(v.new_vaccinations)	OVER (PARTITION BY d. location ORDER BY d.location, d.date) AS rolling_vaccinations
	FROM covid_deaths d
	JOIN covid_vaccination v
		ON d.location = v.location AND d.date =  v.date
	WHERE d.continent IS NOT NULL    
	ORDER BY 2, 3;
    
    -- using CTE
    WITH pop_vacs (continent, location, date, population, new_vaccinations, rolling_vaccinations)
    AS (
		SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		SUM(v.new_vaccinations)	OVER (PARTITION BY d. location ORDER BY d.location, d.date) AS rolling_vaccinations
		FROM covid_deaths d
		JOIN covid_vaccination v
			ON d.location = v.location AND d.date =  v.date
		WHERE d.continent IS NOT NULL    
		ORDER BY 2, 3	)
	SELECT *, ROUND((rolling_vaccinations / population) * 100, 2) AS rolling_percentage
    FROM pop_vacs;

# Temporay Tables
DROP TABLE IF EXISTS population_vaccinated;
CREATE TABLE population_vaccinated (
	continent VARCHAR (255), 
    location VARCHAR (255), 
    date DATE,
    population FLOAT,
    new_vaccinations FLOAT,
    rolling_vaccinations FLOAT	);
    
INSERT INTO population_vaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
		SUM(v.new_vaccinations)	OVER (PARTITION BY d. location ORDER BY d.location, d.date) AS rolling_vaccinations
		FROM covid_deaths d
		JOIN covid_vaccination v
			ON d.location = v.location AND d.date =  v.date
		WHERE d.continent IS NOT NULL    
		ORDER BY 2, 3;
        
SELECT *, ROUND((rolling_vaccinations / population) * 100, 2) AS rolling_percentage
FROM population_vaccinated;	



	
	


# List the countries with the most deaths
SELECT location, SUM(total_deaths) AS highest_casecount, MAX((total_cases / population)) * 100 AS highest_poprate 
FROM covid_deaths
GROUP BY location, population
ORDER BY 4 DESC;	-- or ORDER BY highest_poprate DESC



select *
from covid_deaths
limit 3;

