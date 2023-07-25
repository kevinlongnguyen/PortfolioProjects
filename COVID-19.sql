SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4


-- Query to select initial data fields for analysis

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Total Cases vs Total Deaths
-- Chance of dying from Covid in the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states' AND continent IS NOT NULL
ORDER BY 1, 2


-- Total Cases vs Population
-- Percentage of population infected with Covid

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2


-- Countries with the highest Covid infection rates compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)) * 100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC


-- Countries with highest total Covid death counts

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC


-- Continents with highest total Covid death counts

SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


-- Global numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Total Population vs Vaccinations

SELECT Death.continent, Death.location, Death.date, Death.population, Vaccination.new_vaccinations,
	SUM(CONVERT(INT, Vaccination.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
	ON Death.location = Vaccination.location
	AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL
ORDER BY 2, 3

-- CTE
WITH PopVac (continent, location, date, population, new_vaccinations, rolling_vaccinations) AS
(
SELECT Death.continent, Death.location, Death.date, Death.population, Vaccination.new_vaccinations,
	SUM(CONVERT(INT, Vaccination.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
	ON Death.location = Vaccination.location
	AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL
)
SELECT *, (rolling_vaccinations/population) * 100
FROM PopVac


-- Temp Table

DROP TABLE IF EXISTS #PercPopVac
CREATE TABLE #PercPopVac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #PercPopVac
SELECT Death.continent, Death.location, Death.date, Death.population, Vaccination.new_vaccinations,
	SUM(CONVERT(INT, Vaccination.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
	ON Death.location = Vaccination.location
	AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL

SELECT *, (rolling_vaccinations/population) * 100
FROM #PercPopVac


-- Creating view to store date for future visualizations

CREATE VIEW PercPopVac AS
SELECT Death.continent, Death.location, Death.date, Death.population, Vaccination.new_vaccinations,
	SUM(CONVERT(INT, Vaccination.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS Death
JOIN PortfolioProject..CovidVaccinations AS Vaccination
	ON Death.location = Vaccination.location
	AND Death.date = Vaccination.date
WHERE Death.continent IS NOT NULL