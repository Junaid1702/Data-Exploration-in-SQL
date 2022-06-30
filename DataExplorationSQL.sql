/*
 	Data Exploration in SQL for COVID-19
 	It contains two csv files:
 	a) Covid Deaths
 	b) Covid Vaccinations
*/


-- Exploring Covid Deaths data

SELECT *
FROM CovidDeaths_csv_csv
WHERE continent != ''
ORDER BY location , date 


-- Exploring Covid Vaccinations data

SELECT *
FROM CovidVaccinations_csv_csv cvcc 
WHERE continent != ''
ORDER BY location , date 


-- Selecting the Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths_csv_csv
WHERE continent != '' 
ORDER BY location , date


-- Total Cases vs Total Deaths
-- Shows percentage of dying if you contract COVID-19

SELECT Location, date, total_cases, total_deaths, (CAST (total_deaths AS float) / CAST (total_cases AS float))*100 AS Death_Percentage
FROM CovidDeaths_csv_csv
WHERE location LIKE '%India%' 
OR location LIKE '%United Kingdom%'
AND continent != ''
ORDER BY Death_Percentage DESC


-- Total Cases vs Population
-- Shows the percentage of population infected FROM COVID-19

SELECT Location, date, Population, total_cases,  (CAST(total_cases AS float)/CAST(Population AS float))*100 AS Population_Infected_Percentage
FROM CovidDeaths_csv_csv
WHERE location LIKE '%India%' 
OR location LIKE '%United Kingdom%' 
AND continent != ''
ORDER BY Population_Infected_Percentage DESC


-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS Highest_Infection_Count,  Max(CAST(total_cases AS float)/CAST(Population AS float))*100 AS Population_Infected_Percentage
FROM CovidDeaths_csv_csv
--WHERE location LIKE '%India%'
--OR location LIKE '%United Kingdom%' 
WHERE continent != ''
GROUP BY Location, Population
ORDER BY Population_Infected_Percentage DESC


-- Countries with Highest Death Count

SELECT Location, MAX(total_deaths) AS Total_Death_Count
FROM CovidDeaths_csv_csv
--WHERE location LIKE '%India%'
--OR location LIKE '%United Kingdom%'
WHERE continent = ''
GROUP BY Location 
ORDER BY Total_Death_Count DESC


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

SELECT continent, MAX(Total_deaths) AS Total_Death_Count
FROM CovidDeaths_csv_csv
WHERE continent != '' 
GROUP BY continent 
ORDER BY Total_Death_Count DESC


-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(cast(new_deaths AS float))/SUM(new_Cases)*100 AS Death_Percentage
FROM CovidDeaths_csv_csv
--WHERE location LIKE '%India%'
WHERE  continent != '' 


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT dea.continent ,dea.location ,dea.date, dea .population , vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated 
--	, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths_csv_csv dea
JOIN CovidVaccinations_csv_csv vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date 
WHERE dea.continent  != '' 
--and vac.new_vaccinations > 0s
ORDER BY dea.location , dea.date


/*  Can't use the column that is just created to use in the next one, so here the column name is "Rolling_People_Vaccinated"
	So there are two methods two solve this
	a) Using CTE
	b) Using Temp Table
*/

-- a) Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
	(SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS Rolling_People_Vaccinated
	FROM CovidDeaths_csv_csv dea
	JOIN CovidVaccinations_csv_csv vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent != '' 
--	ORDER BY dea.location , dea.date
	)
SELECT *, (CAST(Rolling_People_Vaccinated AS float)/Population)*100 AS Population_Vaccinated_Percentage
FROM PopvsVac


-- b) Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date nvarchar(255),
population bigint,
new_vaccinations nvarchar(255),
Rolling_People_Vaccinated nvarchar(255))

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS Rolling_People_Vaccinated
	FROM CovidDeaths_csv_csv dea
	JOIN CovidVaccinations_csv_csv vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent != ''
	
SELECT *, (CAST(Rolling_People_Vaccinated AS float)/population)*100 AS Population_Vaccinated_Percentage
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated1 AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM CovidDeaths_csv_csv dea
	JOIN CovidVaccinations_csv_csv vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent != '' 
	
	