## CREATE DATABASE covid_portfolio

DESCRIBE  covid_deaths ; 

ALTER TABLE covid_deaths
MODIFY COLUMN continent VARCHAR(255),
MODIFY COLUMN date DATE,
MODIFY COLUMN location VARCHAR(255);

# Update total deaths column to int

UPDATE covid_deaths
SET total_deaths = 0
WHERE total_deaths = '';
ALTER TABLE covid_deaths MODIFY COLUMN total_deaths FLOAT;

UPDATE covid_deaths
SET new_deaths = 0
WHERE new_deaths = '';
ALTER TABLE covid_deaths MODIFY COLUMN new_deaths FLOAT;

UPDATE covid_deaths
SET continent = NULLIF(continent, '');

UPDATE covid_deaths
SET date = str_to_date(date, '%d/%m/%Y');

UPDATE covid_vaccinations
SET date = str_to_date(date, '%d/%m/%Y');

# View the covid death table

SELECT * 
FROM covid_portfolio.covid_deaths;

# View the covid vaccination table
SELECT *
FROM covid_portfolio.covid_vaccinations;


# Update date format for both tables

UPDATE covid_deaths
SET date = str_to_date(date, '%d/%m/%Y');

UPDATE covid_vaccinations
SET date = str_to_date(date, '%d/%m/%Y');

SELECT *
FROM covid_portfolio.covid_deaths
ORDER BY 3, 4;

SELECT *
FROM covid_portfolio.covid_vaccinations
ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1 , 2;

# Looking at total cases vs total deaths
# Likelyhood of dying if you contract covid in your country.

SELECT location, date, total_cases, total_deaths , round((total_deaths/total_cases)*100 ,2) AS death_percentage
FROM covid_deaths
WHERE location LIKE '%Australia%'
ORDER BY 1 , 2;

# Look at total cases vs population
# Shows how much of the population has contracted COVID-19
SELECT location, date, population, total_cases, round((total_cases/population)*100 ,2) AS infected_percentage
FROM covid_deaths
WHERE location LIKE '%Australia%'
ORDER BY 1 , 2;

# Looking at countries with highest infection rates vs population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, round(MAX((total_cases/population))*100 ,2) AS Max_covid_percentage
FROM covid_deaths
GROUP BY location, population
ORDER BY 4 DESC;

# Countries with highest death count per population

SELECT Location, continent,  MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC ;

# Breakdown by location
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC ;

# Breakdown by continent

SELECT continent,  MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC ;

# Showing continents with highest death counts
SELECT continent,  MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC ;

# Global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, round((SUM(new_deaths)/SUM(new_cases))*100,2) AS DeathPercent
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1 , 2;

-- Covid Vaccinations

UPDATE covid_vaccinations
SET new_vaccinations = NULLIF(new_vaccinations, '');


# Total population vs total vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER( PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

#USE CTE
WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER( PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL
ORDER BY 2,3
)
SELECT * , ROUND((RollingPeopleVaccinated/population) *100,2) AS Vac_Percent
FROM PopvsVac;

-- ---------------------------------------------------------------------------------------------------------------------------------------------


# Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
 Continent nvarchar(255),
 location nvarchar(255),
 date date,
 population nvarchar(255),
 new_vaccinations float,
 RollingPeopleVaccinated float
 );

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER( PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL;

SELECT * , ROUND((RollingPeopleVaccinated/population) *100,2) AS Vac_Percent
FROM PercentPopulationVaccinated;

-- ---------------------------------------------------------------------------------------------------------------------------------------------

# Create view to store data and to create visualizations 
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER( PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths AS dea
LEFT JOIN covid_vaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND new_vaccinations IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated