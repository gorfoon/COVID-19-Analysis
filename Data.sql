--------------------------
--COVID-19 DATA ANALYSIS--
--------------------------

--Shows all COVID related metrics, such as new cases and deaths
select * 
from coviddeaths
order by 3,4

--Shows vaccination related metrics 
select * 
from covidvaccinations 
order by 3,4 

-------------
--US ANALYSIS
-------------

--Total Cases vs Total Deaths 
--Death percentage shows the likelihood of contracting COVID-19 in the United States 
select location, date, total_cases, total_deaths, population, round(((total_deaths/total_cases)*100), 2) as DeathPercentage
from coviddeaths
where location like '%States%'
order by 1,2

--Total Cases vs. Total Population
select location, date, total_cases, population, round(((total_cases/population)*100), 2) as ContractionPercentage
from coviddeaths
where location like '%States%'
order by 1,2

---------------------------
--COUNTRY GROUPING ANALYSIS
---------------------------

--Top 10 countries with highest infection rate compared to total population (where population is greater than 1 million)
drop view if exists highestinfectionrate
create view highestinfectionrate as 
select location, population, max(total_cases) as HighestInfectionCount, round(max(((total_cases/population)*100)), 5) as ContractionPercentage
from coviddeaths
where population >= 1000000
group by location, population
having max(total_cases) is NOT NULL and round(max(((total_cases/population)*100)), 5) is not null
order by contractionpercentage desc
limit 10

select * from highestinfectionrate

--Top 10 countries with the highest death count per population (where population is greater than 1 million)
drop view if exists highestdeathpercentage
create view highestdeathpercentage as 
select location, max(total_deaths) as TotalDeathCount, round(max(((total_deaths/population)*100)), 5) as DeathPercentage
from coviddeaths
where population >= 1000000
--AND location like '%States%'
group by location, population
having max(total_deaths) is NOT NULL and round(max(((total_deaths/population)*100)), 5) is not null
order by DeathPercentage desc
limit 10

select * from highestdeathpercentage

--Top 10 Countries with the most vaccinations per population (where population is greater than 1 million)
drop table if exists VaccinationPercentage --Temp Table
create table VaccinationPercentage(  --Temp Table
	location varchar(250),
	population numeric,
	totalvaccinations numeric
)

insert into VaccinationPercentage 
select vac.location, dea.population, max(people_vaccinated) as totalvaccinations
from covidvaccinations vac
join coviddeaths dea on
vac.location = dea.location AND
vac.date = dea.date 
group by vac.location, dea.population
having sum(new_vaccinations) is not null
order by totalvaccinations desc

drop view if exists HighestVaccinationRates 
create view HighestVaccinationRates as 
select *, round((totalvaccinations/population)*100, 2) as VaccinationPercentage
from VaccinationPercentage 
where population >=1000000
--and location like 'United States'
order by VaccinationPercentage desc
limit 10

select * from HighestVaccinationRates

--------------
--BY CONTINENT
--------------

--Shows Total Deaths 
drop view if exists TotalDeathsbyContinent 
create view TotalDeathsbyContinent as
select continent, max(total_deaths) as TotalDeathCount
from coviddeaths
where continent is not null
group by continent 
order by TotalDeathCount desc

select * from TotalDeathsbyContinent

--Continents with the highest death count per population
drop view if exists TotalDeathsperPopbyContinent 
create view TotalDeathsperPopbyContinent as
select continent, max(population), round(max((total_deaths/population)*100), 5) as TotalDeathCountPerPop
from coviddeaths
where continent is not null
group by continent
order by TotalDeathCountPerPop desc

select * from TotalDeathsperPopbyContinent

--Shows amount of vaccinations per day for different locations and dates 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from coviddeaths dea
join covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
--and dea.location like 'United States'
order by 1,2,3

--Temp Table: rolling vaccination count by location and date
drop table if exists PercentPopulationVaccinated 
create table PercentPopulationVaccinated(
	continent varchar(250),
	location varchar(250),
	date date, 
	population numeric, 
	new_vaccinations numeric, 
	RollingPeopleVaccinated numeric
)

insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths dea
join covidvaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 2,3

drop view if exists RollingPercentPopulationVaccinated 
create view RollingPercentPopulationVaccinated as
select *, round((RollingPeopleVaccinated/population)*100, 5) as PercentPopulationVaccinated from PercentPopulationVaccinated 
--and location like 'United States'

select * from RollingPercentPopulationVaccinated




