--select location, date, total_cases, new_cases, total_deaths, population from death

-- Looking at Totoal Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percantage
from death;


--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
select location, date, population, total_cases, (total_cases/population)*100 as percantage_affected
from death;

-- Looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfection, max((total_cases/population)*100) as Pop_Inf
from death
group by location, population
order by Pop_Inf desc;

--showing countries with highest death count per population
SELECT * FROM death
WHERE continent IS NOT NULL;

--BY COUNTRY
SELECT location, 
		MAX(CAST(Total_deaths as int)) as TotalDeathCount
FROM death
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc;


--BY CONTINENT
SELECT continent, 
		MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS
SELECT TO_DATE(date, 'DD.MM.YY'),
		SUM(new_cases) AS total_cases,
		SUM(CAST(new_deaths AS INT)) AS total_deaths,
		SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percentage
FROM death
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;
--
WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Vacc)
AS
(
SELECT death.continent, death.location, TO_DATE(death.date, 'DD.MM.YY'), 
		death.population, 
		vaccination.new_vaccinations,
		SUM(CAST(vaccination.new_vaccinations AS INT)) OVER (PARTITION BY death.Location
		ORDER BY death.location, TO_DATE(death.date, 'DD.MM.YY')) AS Rolling_Vacc
FROM death
JOIN vaccination ON 
		death.location = vaccination.location AND
		death.date = vaccination.date
WHERE death.continent IS NOT NULL AND new_vaccinations IS NOT NULL
--ORDER BY 2,3
)

--TEMP TABLE
DROP TABLE IF exists perc_pop_vacc
CREATE TABLE perc_pop_vacc (
continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population NUMERIC,
New_vaccinations NUMERIC,
rolling_vac NUMERIC
);

INSERT INTO perc_pop_vacc
SELECT death.continent, death.location, TO_DATE(death.date, 'DD.MM.YY'), 
		death.population, 
		vaccination.new_vaccinations,
		SUM(CAST(vaccination.new_vaccinations AS INT)) OVER (PARTITION BY death.Location
		ORDER BY death.location, TO_DATE(death.date, 'DD.MM.YY')) AS Rolling_Vac
FROM death
JOIN vaccination ON 
		death.location = vaccination.location AND
		death.date = vaccination.date
WHERE death.continent IS NOT NULL AND new_vaccinations IS NOT NULL;

SELECT *, (rolling_vac/Population)*100 AS percent_vacc
FROM perc_pop_vacc;

--CREATING VIEW TO STORE FOR DATA VIS
CREATE VIEW perc_pop_vaccinated AS
SELECT death.continent, death.location, TO_DATE(death.date, 'DD.MM.YY'), 
		death.population, 
		vaccination.new_vaccinations,
		SUM(CAST(vaccination.new_vaccinations AS INT)) OVER (PARTITION BY death.Location
		ORDER BY death.location, TO_DATE(death.date, 'DD.MM.YY')) AS Rolling_Vacc
FROM death
JOIN vaccination ON 
		death.location = vaccination.location AND
		death.date = vaccination.date
WHERE death.continent IS NOT NULL AND new_vaccinations IS NOT NULL
