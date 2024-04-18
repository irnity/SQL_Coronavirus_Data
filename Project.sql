
--SELECT *
--FROM CovidDeaths$
--ORDER BY 3, 4

--SELECT *
--FROM CovidVaccinations$
--ORDER BY 3, 4

------------------------------------------------------------------------------
-- data that are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1, 2

------------------------------------------------------------------------------
-- total cases vs total deaths
-- % of death 
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
FROM CovidDeaths$
WHERE location like '%%'
ORDER BY 1, 2

------------------------------------------------------------------------------
-- total cases vs population
SELECT 
	location, 
	population, 
	MAX(total_cases) as HighestInfectionCount,  
	MAX((total_cases / population)) * 100 as PercentageCovid
FROM CovidDeaths$
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentageCovid DESC

------------------------------------------------------------------------------
-- country with highest death count 
SELECT 
	location, 
	population, 
	MAX(cast(total_deaths as int)) as HighestDeathCount,  
	MAX((total_cases / population)) * 100 as PercentageCovid
FROM CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not NULL
GROUP BY location, population
ORDER BY HighestDeathCount DESC

------------------------------------------------------------------------------
--break down by continent
SELECT 
	continent, 
	MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC

------------------------------------------------------------------------------
-- continents with the highest death count per population
SELECT 
	continent, 
	MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC
 
------------------------------------------------------------------------------
-- global numbers
SELECT 
	date,
	SUM(new_cases) as TotalCases,
	SUM(CAST(new_deaths as int)) as TotalDeaths,
	SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPersantage
FROM CovidDeaths$
	WHERE continent is not NULL
	GROUP BY date
	ORDER BY 1,2

------------------------------------------------------------------------------
-- total population vs vaccinations 
-- use CTE
WITH PopVsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(

SELECT 
	Deaths.continent, 
	Deaths.location, 
	Deaths.date, 
	Deaths.population,
	Vaccina.new_vaccinations,
	SUM(Cast(Vaccina.new_vaccinations as INT)) 
		OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) as RollingPeopleVaccinated
FROM CovidDeaths$ as Deaths
JOIN CovidVaccinations$ as Vaccina
	ON Deaths.location = Vaccina.location
	AND Deaths.date = Vaccina.date
WHERE Deaths.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM PopVsVac

------------------------------------------------------------------------------
-- total population vs vaccinations 
-- Same but with Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	Deaths.continent, 
	Deaths.location, 
	Deaths.date, 
	Deaths.population,
	Vaccina.new_vaccinations,
	SUM(Cast(Vaccina.new_vaccinations as INT)) 
		OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) as RollingPeopleVaccinated
FROM CovidDeaths$ as Deaths
JOIN CovidVaccinations$ as Vaccina
	ON Deaths.location = Vaccina.location
	AND Deaths.date = Vaccina.date
WHERE Deaths.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinated

------------------------------------------------------------------------------
-- creating view to store date for visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT 
	Deaths.continent, 
	Deaths.location, 
	Deaths.date, 
	Deaths.population,
	Vaccina.new_vaccinations,
	SUM(Cast(Vaccina.new_vaccinations as INT)) 
		OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) as RollingPeopleVaccinated
FROM CovidDeaths$ as Deaths
JOIN CovidVaccinations$ as Vaccina
	ON Deaths.location = Vaccina.location
	AND Deaths.date = Vaccina.date
WHERE Deaths.continent IS NOT NULL
--ORDER BY 2, 3