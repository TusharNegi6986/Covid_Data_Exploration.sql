-- ==========================================
-- COVID DATA EXPLORATION PROJECT
-- Dataset Exploration using SQL Server
-- ==========================================

-- 1. Preview Dataset

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, TRY_CONVERT(DATE, date, 105);

-- 2. Select Important Columns

SELECT location,
date,
total_cases,
new_cases,
total_deaths,
population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, TRY_CONVERT(DATE, date, 105);

-- 3. Total Cases vs Total Deaths
-- Shows likelihood of dying if infected

SELECT location,
date,
total_cases,
total_deaths,
(total_deaths * 100.0 / NULLIF(total_cases,0)) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY location, TRY_CONVERT(DATE, date, 105);

-- 4. Total Cases vs Population
-- Shows percentage of population infected

SELECT location,
date,
population,
total_cases,
(total_cases * 100.0 / NULLIF(population,0)) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY location, TRY_CONVERT(DATE, date, 105);

-- 5. Countries with Highest Infection Rate

SELECT location,
population,
MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases * 100.0 / NULLIF(population,0))) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- 6. Countries with Highest Death Count

SELECT location,
MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 7. Continents with Highest Death Count

SELECT continent,
MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 8. Global Numbers by Date

SELECT date,
SUM(new_cases) AS TotalCases,
SUM(new_deaths) AS TotalDeaths,
SUM(new_deaths) * 100.0 / NULLIF(SUM(new_cases),0) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY TRY_CONVERT(DATE, date, 105);

-- 9. Population vs Vaccinations (Rolling Count)

SELECT dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations))
OVER (
PARTITION BY dea.location
ORDER BY TRY_CONVERT(DATE, dea.date, 105)
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, TRY_CONVERT(DATE, dea.date, 105);

-- 10. Using CTE for Percentage Calculation

WITH PopvsVac AS
(
SELECT dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations))
OVER (
PARTITION BY dea.location
ORDER BY TRY_CONVERT(DATE, dea.date, 105)
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *,
(RollingPeopleVaccinated * 100.0 / NULLIF(population,0)) AS PercentVaccinated
FROM PopvsVac;

-- 11. Using Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATE,
Population BIGINT,
New_Vaccinations BIGINT,
RollingPeopleVaccinated BIGINT
);

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent,
dea.location,
TRY_CONVERT(DATE, dea.date, 105),
dea.population,
vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations))
OVER (
PARTITION BY dea.location
ORDER BY TRY_CONVERT(DATE, dea.date, 105)
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND TRY_CONVERT(DATE, dea.date, 105) IS NOT NULL;

SELECT *,
(RollingPeopleVaccinated * 100.0 / NULLIF(population,0)) AS PercentVaccinated
FROM #PercentPopulationVaccinated;

-- 12. Creating View for Visualization

CREATE OR ALTER VIEW PercentPopulationVaccinated AS

SELECT dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(CONVERT(BIGINT, vac.new_vaccinations))
OVER (
PARTITION BY dea.location
ORDER BY TRY_CONVERT(DATE, dea.date, 105)
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- 13. Query View

SELECT *
FROM PercentPopulationVaccinated;
