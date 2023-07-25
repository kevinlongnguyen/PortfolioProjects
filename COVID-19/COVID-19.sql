/* ---------------------------------------------------
Queries to explore and analyze COVID-19 data
---------------------------------------------------*/

-- Select all data for initial review
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Select key fields for initial exploration and analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


/* --------------------------------------------------- 
Analyze COVID-19 data by location
---------------------------------------------------*/

-- Calculate chance of dying from COVID in the United States
SELECT location, date, total_cases, total_deaths, 
       (total_deaths/total_cases) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states' AND continent IS NOT NULL
ORDER BY 1, 2

-- Calculate percentage of population infected for each location
SELECT location, date, total_cases, population,
       (total_cases/population) * 100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Find infection counts and infection rates compared to population by location
SELECT location, population, 
       MAX(total_cases) AS highest_infection_count,  
       MAX((total_cases/population)) * 100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC

-- Find locations with highest COVID death counts 
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location  
ORDER BY 2 DESC


/* ---------------------------------------------------
Analyze COVID-19 data by continent 
---------------------------------------------------*/

-- Find continents with the highest death counts
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


/* ---------------------------------------------------
Analyze global COVID-19 data
---------------------------------------------------*/

-- Track global cases and death percentage over time
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
       (SUM(CAST(new_deaths AS INT))/SUM(new_cases)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1, 2


/* --------------------------------------------------- 
Analyze COVID-19 vaccination data
---------------------------------------------------*/

-- Join vaccination and death data
SELECT Death.continent, Death.location, Death.date, Death.population,
       Vaccination.new_vaccinations 
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
     ON Death.location = Vaccination.location
     AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL
ORDER BY 2, 3 

-- Calculate rolling count of total vaccinations 
SELECT Death.continent, Death.location, Death.date, Death.population,
       Vaccination.new_vaccinations, 
       SUM(CONVERT(INT, Vaccination.new_vaccinations)) 
           OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
     ON Death.location = Vaccination.location
     AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL
ORDER BY 2, 3

-- Use CTE to calculate percentage vaccinated
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations) AS
(
       SELECT Death.continent, Death.location, Death.date, Death.population,
              Vaccination.new_vaccinations, 
              SUM(CONVERT(INT, Vaccination.new_vaccinations))
                  OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations   
       FROM PortfolioProject..CovidDeaths AS Death
       JOIN PortfolioProject..CovidVaccinations AS Vaccination
            ON Death.location = Vaccination.location
            AND Death.date = Vaccination.date
       WHERE Death.continent IS NOT NULL
)
SELECT *, (rolling_vaccinations/population) * 100 AS percent_vaccinated
FROM PopvsVac

-- Use temp table to store data for calculating percentage vaccinated
DROP TABLE IF EXISTS #PercentVaccinated
CREATE TABLE #PercentVaccinated
(
       continent nvarchar(255),
       location nvarchar(255),
       date datetime,
       population numeric,
       new_vaccinations numeric,
       rolling_vaccinations numeric
)
INSERT INTO #PercentVaccinated
SELECT Death.continent, Death.location, Death.date, Death.population,
       Vaccination.new_vaccinations,
       SUM(CONVERT(INT, Vaccination.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations  
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
     ON Death.location = Vaccination.location
     AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL
        
SELECT *, (rolling_vaccinations/population) * 100 AS percent_vaccinated 
FROM #PercentVaccinated

-- Create view to store vaccination data for visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT Death.continent, Death.location, Death.date, Death.population, 
       Vaccination.new_vaccinations,
       SUM(CONVERT(INT, Vaccination.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
     ON Death.location = Vaccination.location
     AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL