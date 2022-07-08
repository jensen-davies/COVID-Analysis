SELECT * FROM covidDeaths  ORDER BY 3,4

SELECT * FROM covidVaccinations ORDER BY 3,4

--Select data that we're going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covidDeaths ORDER BY 1,2;

--Calculate the death rate of contracting covid in the USA
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 
as DeathRate
FROM covidDeaths
WHERE location like '%state%'
ORDER BY 1,2;

-- Calculate what percentage of the population has contracted the virus so far
SELECT location, date, population, total_cases, (total_cases/population)*100
as total_infected_percentage
FROM covidDeaths
ORDER BY 1,2;


-- Countries with the highest infection rate against population
SELECT location, population, MAX(total_cases), MAX((total_cases/population)*100)
as total_infected_percentage
FROM covidDeaths
GROUP BY location, population
ORDER BY total_infected_percentage DESC;

-- Countries with the highest death rate against population
SELECT location, MAX(cast(total_deaths as int)) as total_deaths, MAX((total_deaths/population)*100) as death_rate
FROM covidDeaths
WHERE continent is null
GROUP BY location
ORDER BY death_rate DESC;


-- Shows global new cases, new deaths, and death rate per day

SELECT date, SUM(new_cases) as global_new_cases, SUM(cast(new_deaths as int)) as global_new_deaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as global_death_rate
from covidDeaths
WHERE continent is not null
and new_cases is not null
GROUP BY date
ORDER BY 1,2

-- Total cumulative deaths, cases, and death rate up to 7/6/2022
SELECT SUM(new_cases) as global_new_cases, SUM(cast(new_deaths as int)) as global_new_deaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as global_death_rate
from covidDeaths
WHERE continent is not null
and new_cases is not null
ORDER BY 1,2

-- Total population against vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as  cumulative_vaxxed,

From covidDeaths dea
JOIN covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
order by 2,3

-- USING A CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, cumulative_vaxxed) as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as  cumulative_vaxxed
From covidDeaths dea
JOIN covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
)

Select *, (cumulative_vaxxed/population)*100 as vaxxed_percentage From PopVsVac


-- USING A TEMP TABLE
DROP TABLE if exists #Temp
CREATE TABLE #Temp
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaxxed numeric
)

INSERT INTO #Temp
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as  cumulative_vaxxed
From covidDeaths dea
JOIN covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null

Select *, (cumulative_vaxxed/population)*100 as vaxxed_percentage From #Temp
ORDER BY date;

-- View for Tableau viz

Create View PopulationVaxxed as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as  cumulative_vaxxed
From covidDeaths dea
JOIN covidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null