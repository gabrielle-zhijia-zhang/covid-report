/*

Covid 19 Data Exploration in PostgreSQL

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/;


SELECT * FROM covid_deaths
ORDER BY 3,4; 

SELECT * FROM covid_vaccinations
ORDER BY 3,4;



-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contracte covid in a country

SELECT location, date, total_cases, total_deaths, (total_deaths/CAST(total_cases AS FLOAT))*100 AS death_percentage
FROM covid_deaths
WHERE LOWER(location) LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2;



-- Total Cases vs Population 
-- Shows what percentage of population infected with Covid

SELECT location, date, total_cases, population, (total_cases/CAST(population AS FLOAT))*100 AS percent_population_infected
FROM covid_deaths
WHERE lower(location) LIKE '%states%'
ORDER BY 1,2;



-- Countries with Highest Death Count per Populaiton

SELECT location, max(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;



-- Breaking things down by continent
-- Continents with the Highest Death Count per Population

SELECT continent, max(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;



-- Death Percentage Globally per Day

SELECT date, sum(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(CAST(new_cases AS FLOAT))*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL new_cases IS NOT NULL
GROUP BY date
ORDER BY date;



-- Total Population vs Vaccinations
-- Running Total of Vaccinations by Location and Date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;



-- Using CTE to perform calculation on Partition By in previous query

WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (rolling_people_vaccinated/CAST(population AS FLOAT))*100 
FROM popvsvac;



-- Using Temp Table to perform calculations on Partition By in previous query

DROP TABLE IF EXISTS percent_population_vaccinated;

CREATE TABLE percent_population_vaccinated
(
continent TEXT,
location TEXT,
date date,
population NUMERIC, 
new_vaccinations NUMERIC,
rolling_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

SELECT *, (rolling_people_vaccinated/CAST(population AS FLOAT))*100 AS percent_vac_population FROM percent_population_vaccinated;



-- Creating view to store data for later visualizaitons

DROP VIEW IF EXISTS PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location=vac.location
	AND dea.date=vac.date
;

SELECT * FROM PercentPopulationVaccinated;



