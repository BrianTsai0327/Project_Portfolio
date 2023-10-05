/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

/* -- check data
select count(*)
from coviddeaths;

select *
from coviddeaths;

select count(*)
from covidvaccinations;

select *
from covidvaccinations;
*/

Select *
From coviddeaths
Where continent is not null 
order by 3,4;

-- Choose the data we will begin with.

Select Location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
Where continent is not null 
order by 1,2;

-- Total Cases vs Total Deaths
-- Indicates the probability of mortality if you contract COVID-19 in the US.

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From coviddeaths
Where location like '%states%'
and continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Displays the percentage of the population infected with COVID-19.

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From coviddeaths
-- Where location like '%states%'
order by 1,2;


-- Countries with the Highest Infection Rate Relative to Population.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeaths
-- Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc;

-- Countries with Highest Death Count per Population.

Select Location, MAX(cast(Total_deaths as UNSIGNED)) as TotalDeathCount
From coviddeaths
-- Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;


-- Analyzing Data by Continent

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as UNSIGNED)) as TotalDeathCount
From coviddeaths
-- Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as UNSIGNED)) as total_deaths, SUM(cast(new_deaths as UNSIGNED))/SUM(New_Cases)*100 as DeathPercentage
From coviddeaths
-- Where location like '%states%'
where continent is not null 
-- Group By date
order by 1,2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%m/%d/%y') as formatted_date, -- Convert date to the correct format
    dea.population,
    vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as UNSIGNED)) OVER (Partition by dea.Location Order by dea.location,  STR_TO_DATE(dea.date, '%m/%d/%y')) as RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3; -- Order by location and formatted_date

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, formatted_date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, STR_TO_DATE(dea.date, '%m/%d/%y') as formatted_date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as UNSIGNED)) OVER (Partition by dea.Location Order by dea.location, STR_TO_DATE(dea.date, '%m/%d/%y')) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated;

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null 
-- order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


