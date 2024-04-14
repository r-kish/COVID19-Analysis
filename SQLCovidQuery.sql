-- COVID19 Deaths and Vaccinations SQL Data Exploration Project
-- By: Richard Kish
-- Finished Jan 2024
------------------------------------------------------------------------------------------------------------

-- SELECTING DATA
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQLCovid..CovidDeaths$
ORDER BY 1,2

------------------------------------------------------------------------------------------------------------

-- ALTER DATATYPES FOR COLUMNS USED IN THIS QUERY FOR INTENDED ANALYSIS/EXPLORATION
ALTER TABLE SQLCovid.dbo.CovidDeaths$ ALTER COLUMN total_deaths float
ALTER TABLE SQLCovid.dbo.CovidDeaths$ ALTER COLUMN total_cases float
ALTER TABLE SQLCovid.dbo.CovidDeaths$ ALTER COLUMN population float
ALTER TABLE SQLCovid.dbo.CovidDeaths$ ALTER COLUMN total_cases bigint
ALTER TABLE SQLCovid.dbo.CovidDeaths$ ALTER COLUMN new_cases float
ALTER TABLE SQLCovid.dbo.CovidDeaths$ ALTER COLUMN new_deaths float
ALTER TABLE SQLCovid.dbo.CovidVaccinations$ ALTER COLUMN new_vaccinations float

------------------------------------------------------------------------------------------------------------

-- TOTAL CASES vs TOTAL DEATHS
-- COVID case to death likelihood by country (USA + Virgin Islands default) (Used in Tableau Dashboard as Table 6)
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as death_percent
FROM SQLCovid..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

-- TOTAL CASES VS POPULATION
-- Percent of population with COVID (option for search by country/region; USA + VI default)
SELECT location, date, total_cases, population, (total_cases / population)*100 AS COVID_percent
FROM SQLCovid..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

-- COUNTRIES WITH THE HIGHEST INFECTION RATE COMPARED TO POPULATION (Used in Tableau Dashboard as Table 3)
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases / population))*100 AS infected_percent
FROM SQLCovid..CovidDeaths$
GROUP BY location, population
ORDER BY infected_percent desc

-- COUNTRIES WITH THE HIGHEST INFECTION RATE COMPARED TO POPULATION BY DATE (Used in Tableau Dashboard as Table 4)
SELECT location, population, date, MAX(total_cases) as highest_infection_count, MAX((total_cases / population))*100 AS infected_percent
FROM SQLCovid..CovidDeaths$
GROUP BY location, population, date
ORDER BY infected_percent desc

------------------------------------------------------------------------------------------------------------

-- HIGHTEST DEATH COUNT BY LOCATION
-- By Continent (Used in Tableau Dashboard as Table 2)
SELECT continent, SUM(CAST(new_deaths AS int)) AS total_deathcount
FROM SQLCovid..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deathcount desc

-- By Country (Used in Tableau Dashboard as Table 2a)
SELECT location, SUM(CAST(new_deaths as int)) AS total_deathcount
FROM SQLCovid..CovidDeaths$
WHERE continent IS NOT NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_deathcount desc

-- CUMULATIVE GLOBAL STATISTICS (Used in Tableau Dashboard as Table 1)
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percent
FROM SQLCovid..CovidDeaths$
--WHERE location like '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2

------------------------------------------------------------------------------------------------------------

-- TOTAL POPULATION VS VACCINATIONS (Used in Tableau Dashboard as Table 5)
-- Using CTE
WITH pop_vs_vacc (continent, location, date, population, new_vaccinations, rolling_people_vacc)
AS 
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
AS rolling_people_vacc
FROM SQLCovid..CovidDeaths$ death
JOIN SQLCovid..CovidVaccinations$ vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL
)
SELECT *, (rolling_people_vacc/population)*100 AS percent_people_vacc
FROM pop_vs_vacc
ORDER BY location, date

-- Using TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_people_vacc numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
AS rolling_people_vacc
FROM SQLCovid..CovidDeaths$ death
JOIN SQLCovid..CovidVaccinations$ vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3

SELECT *, (rolling_people_vacc/population)*100 AS percent_people_vacc
FROM #PercentPopulationVaccinated
ORDER BY location, date

------------------------------------------------------------------------------------------------------------

-- CREATING VIEW to STORE DATA FOR LATER VISUALIZATION
GO CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(vacc.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
AS rolling_people_vacc
FROM SQLCovid..CovidDeaths$ death
JOIN SQLCovid..CovidVaccinations$ vacc
ON death.location = vacc.location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL