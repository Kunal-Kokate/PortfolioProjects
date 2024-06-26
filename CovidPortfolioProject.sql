DROP DATABASE IF EXISTS PortfolioProject;
CREATE DATABASE PortfolioProject;
USE PortfolioProject;


# Just checking the location and dates
SELECT * FROM coviddeaths WHERE continent is not null ORDER BY 3, 4;
SELECT * FROM covidvaccinations ORDER BY 3, 4;


SELECT Location, date, total_cases, new_cases, total_deaths, population FROM coviddeaths
WHERE continent is not null
ORDER BY Location, date;


# Looking at total cases vs total deaths. Shows likelihood of dying if you get the virus
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases * 100) AS DeathPercentage FROM coviddeaths
WHERE location LIKE '%states%' and continent is not null
ORDER BY Location, date;


# Total cases vs Population
SELECT Location, date, total_cases, population, (total_cases/population) * 100 AS PercentOfPopulationCovid FROM coviddeaths
WHERE location LIKE '%states%' and continent is not null
ORDER BY Location, date;


# Checking what cases have the highest infection rate compared to population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population * 100)) AS Percentage FROM coviddeaths
WHERE continent is not null
GROUP BY  Location, population
ORDER BY Percentage DESC;


# Showing countries with the highest death count per population
SELECT Location, MAX(CAST(Total_deaths AS float)) AS TotalDeathCount
FROM coviddeaths
WHERE continent is not null
GROUP BY  Location
ORDER BY TotalDeathCount DESC;


# Now doing it by continent
SELECT continent, MAX(CAST(Total_deaths AS float)) AS TotalDeathCount
FROM coviddeaths
WHERE continent is not null
GROUP BY  Location
ORDER BY continent DESC;


# Showing continents with the highest death count per population
Select continent, MAX(cast(Total_deaths as float)) as TotalDeathCount
From CovidDeaths
-- Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;


# Global Numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as float)) as total_deaths, SUM(cast(new_deaths as float))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
-- Where location like '%states%'
where continent is not null 
order by 1,2;


# Total Population vs Vaccinations. Showing Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date


# Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists PercentPopulationVaccinated
Create TEMPORARY Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population int,
New_vaccinations int,
RollingPeopleVaccinated int
)


Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null 
-- order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated


# Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
