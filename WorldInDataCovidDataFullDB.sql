
SELECT * 
FROM World_in_data_FullDB..CovidDeaths

SELECT * 
FROM World_in_data_FullDB..CovidDeaths
ORDER BY 3,4

SELECT * 
FROM World_in_data_FullDB..CovidVaccinations
ORDER BY 3,4 /*order by location and date - ASC*/


--List all field attributes in both tables. Purpose- study attribute characteristic. decide and pick suitable ones for specific queries.

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths';

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidVaccinations';

SELECT location, date, total_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2; 

-- Daily Case Fatality Rate (CFR)  
SELECT location, date, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS CFR, population
FROM (
	SELECT location, date, CONVERT(FLOAT,total_cases) AS Total_Cases, CONVERT(FLOAT,total_deaths) AS Total_Deaths, population
	FROM CovidDeaths
	 ) AS CD
ORDER BY 1,2;

CREATE TABLE #countrywise_meancfr2
(COUNTRY varchar(100),
 RECORDED_DATE date,
 Total_Cases bigint,
 Total_Deaths bigint, 
 CFR float,
 TOTALPOPULATION bigint
 )

 INSERT INTO #countrywise_meancfr2
 SELECT location, date, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS CFR, population
FROM (
	SELECT location, date, CONVERT(FLOAT,total_cases) AS Total_Cases, CONVERT(FLOAT,total_deaths) AS Total_Deaths, population
	FROM CovidDeaths
	 ) AS CD
ORDER BY 1,2;

SELECT *
FROM #countrywise_meancfr2
ORDER BY COUNTRY, RECORDED_DATE;

--countrywise average cfr percentage
SELECT COUNTRY, AVG(CFR) AS mean_CFR, MAX(Total_Cases) AS total_cases, MAX(Total_Deaths) AS total_deaths
FROM #countrywise_meancfr2
WHERE COUNTRY NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income')
GROUP BY COUNTRY
ORDER BY total_deaths DESC;

--countrywise Prevalance (of Covid w.r.t Population) and Mortality Rate (caused by Covid, w.r.t overall population)
SELECT COUNTRY, mean_CFR, total_cases,(CONVERT(FLOAT,total_cases)/POP)*100 AS PREVALANCE, total_deaths, 
		(CONVERT(FLOAT,total_deaths)/POP)*100 AS MORTALITY_RATE, POP
FROM (
		SELECT COUNTRY, AVG(CFR) AS mean_CFR, MAX(Total_Cases) AS total_cases, MAX(Total_Deaths) AS total_deaths, AVG(TOTALPOPULATION) AS POP
		FROM #countrywise_meancfr2
		GROUP BY COUNTRY
	 ) AS CDS
WHERE COUNTRY NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income')
ORDER BY POP DESC;

--selecting data from a particular country (INDIA), analyze trends
SELECT location, date, total_cases, total_deaths, population
FROM CovidDeaths
WHERE location LIKE '%ndia%'
ORDER BY 1,2; 

--CFR trends in INDIA
SELECT date, total_cases, total_deaths, (CONVERT(FLOAT,total_deaths)/CONVERT(FLOAT,total_cases))*100 AS CFR_INDIA
FROM CovidDeaths
WHERE location LIKE '%ndia%'
ORDER BY 4 DESC;

--PREVALENCE trends in INDIA
SELECT date, total_cases, population, (CONVERT(FLOAT,total_cases)/CONVERT(FLOAT,population))*100 AS PREVALENCE
FROM CovidDeaths
WHERE location LIKE '%ndia%'
ORDER BY 1;

SELECT * 
FROM 
(
SELECT date, total_cases, population, (CONVERT(FLOAT,total_cases)/CONVERT(FLOAT,population))*100 AS PREVALENCE
FROM CovidDeaths
WHERE location LIKE '%ndia%'
) AS PREV
WHERE total_cases BETWEEN 0 AND 10  OR
	  PREVALENCE BETWEEN 0.50 AND 0.51 OR 
	  PREVALENCE BETWEEN 0.99 AND 1.0 OR 
	  PREVALENCE BETWEEN 1.00 AND 1.002 OR
	  PREVALENCE BETWEEN 2.00 AND 2.01 OR 
      PREVALENCE BETWEEN 2.5 AND 2.52 OR 
      PREVALENCE BETWEEN 3.0 AND 3.01 OR 
      PREVALENCE BETWEEN 3.5 AND 3.52
ORDER BY 1; /*total_cases include all cases ever recorded and there isn't any evidence to suggest it adjusts for the recovered population
			so prevalence becomes procedural and incremental. so instead, here we observe the time taken for significant prevalence 
			milestones to happen which inturn highlights phases of severity, phases of effective control and phase of 
			decline or stabilization. NOTE - can try binning for the same in a future commit*/

--MORTALITY RATE trends in INDIA
SELECT date, total_deaths, population, (CONVERT(FLOAT,total_deaths)/CONVERT(FLOAT,population))*100 AS MORTALILTY_RATE
FROM CovidDeaths
WHERE location LIKE '%ndia%'
ORDER BY 1,4;

 --CONTINENTWISE DATA SEVERLY BLOATED INCORRECT

SELECT location, SUM(cast(total_deaths as bigint)) AS OVERALL_DEATH_COUNT, SUM(cast(total_cases as bigint)) AS OVERALL_CASES_COUNT
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY OVERALL_DEATH_COUNT; --CONTINENT DATA IN LOCATION ALSO BLOATED INCORRECT

SELECT continent, location, COUNT(*)
FROM CovidDeaths
GROUP BY continent, location
ORDER BY continent;

/* THE CONTINENT AGGREGATE DATA WAS OFF-PUTTING, SO COUNTRYWISE FILTERED AND SORTED OUTPUT IS BEING USED TO 
   CALCULATE TOTAL GLOBAL DEATH BY AGGREGATING COUNTRYWISE CUMULATIVE NUMBERS */

--GLOBAL TOTAL DEATH COUNT AND TOTAL CASES COUNT
SELECT SUM(total_deaths) as totaldeath, SUM(total_cases) AS totalcases, SUM(POP) AS world_population
FROM (
SELECT COUNTRY, mean_CFR, total_cases,(CONVERT(FLOAT,total_cases)/POP)*100 AS PREVALANCE, total_deaths, 
		(CONVERT(FLOAT,total_deaths)/POP)*100 AS MORTALITY_RATE, POP
FROM (
		SELECT COUNTRY, AVG(CFR) AS mean_CFR, MAX(Total_Cases) AS total_cases, MAX(Total_Deaths) AS total_deaths, AVG(TOTALPOPULATION) AS POP
		FROM #countrywise_meancfr2
		GROUP BY COUNTRY
	 ) AS CDS
WHERE COUNTRY NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income')
	) AS TD

/* THE ABOVE QUERY GIVES A TOTAL OF 5364770 (5.3 MILLION) AND CONSIDERING I ONLY COPIED A PORTION OF THE DATA AND CURRENT
   ACTUALS STAND AT 6.8 MILLION, THIS RESULT SEEMS AGREEABLE. NEED TO CHECK WHY CONTINENT WISE DATA WAS SO BLOATED. OR SHOULD 
   PROCEED ONLY WITH COUNTRYWISE DATA */

--GLOBAL INFECTION RATE AND GLOBAL MORTALITY RATE
SELECT totaldeath, totalcases, world_population,((CAST(totalcases AS float))/(CAST(world_population AS float)))*100 AS global_infection_rate, 
		((CAST(totaldeath AS float))/(CAST(world_population AS float)))*100 AS global_mortality_rate
FROM (
SELECT SUM(total_deaths) as totaldeath, SUM(total_cases) AS totalcases, SUM(POP) AS world_population
FROM (
SELECT COUNTRY, mean_CFR, total_cases,(CONVERT(FLOAT,total_cases)/POP)*100 AS PREVALANCE, total_deaths, 
		(CONVERT(FLOAT,total_deaths)/POP)*100 AS MORTALITY_RATE, POP
FROM (
		SELECT COUNTRY, AVG(CFR) AS mean_CFR, MAX(Total_Cases) AS total_cases, MAX(Total_Deaths) AS total_deaths, AVG(TOTALPOPULATION) AS POP
		FROM #countrywise_meancfr2
		GROUP BY COUNTRY
	 ) AS CDS
WHERE COUNTRY NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income')
	) AS TD
	) AS GLOBALDATA







SELECT *
FROM World_in_data_FullDB..CovidVaccinations
ORDER BY location, date;

SELECT continent, location, COUNT(*)
FROM CovidVaccinations
GROUP BY continent, location
ORDER BY continent; 

--COUNTRYWISE DATA ON CASES, DEATHS, POPULATION

SELECT location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY country_population DESC;

--COUNTRYWISE CFR, PREVALENCE, MORTALITY RATE

SELECT location, totalcases, totaldeaths, country_population, (totaldeaths/totalcases) AS CFR, (totalcases/country_population) AS PREVALENCE, (totaldeaths/country_population) AS MORTALITY_RATE
FROM (
SELECT location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income', 'North Korea') 
GROUP BY location
	  ) AS COUNTRYWISE_RATE
WHERE totalcases != 0 
ORDER BY PREVALENCE DESC; /* 'Falkland Islands' have 0 deaths, so 0 CFR and MORTALITY_RATE, 'England' has NULL cases 
								and deaths (incomplete record) so all aggregates are NULL */

--EXPLORING THE POSSIBILITIES ON JOINING CovidDeaths and CovidVaccinations

SELECT * 
FROM CovidVaccinations cvac
JOIN CovidDeaths cded
ON cvac.location = cded.location AND cvac.date = cded.date
ORDER BY cvac.location; /* All significant Covid-death data like new cases, new deaths, demographic distribution etc., are available
							in the Covid-vaccinations table and so the joining of two tables don't add significant attributes*/

-- CREATING A CTE TO USE COUNTRYWISE DATA TO AGGREGATE CONTINENT WISE DATA AND GLOBAL DATA 
WITH COVIDDATACOUNTRYWISE 
AS 
(
SELECT continent, location, country_population, (totaldeaths/totalcases)*100 AS CFR, (totalcases/country_population) AS PREVALENCE, 
		(totaldeaths/country_population) AS MORTALITY_RATE
FROM (
SELECT continent, location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income', 'North Korea') 
GROUP BY location, continent
	  ) AS COUNTRYWISE_RATE
WHERE totalcases != 0 
)
SELECT continent, SUM(country_population) AS continent_population, AVG(CFR) AS mean_CFR, AVG(PREVALENCE) AS mean_PREVALENCE,
		AVG(MORTALITY_RATE) AS mean_MORTALITY_RATE
FROM COVIDDATACOUNTRYWISE
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY continent_population DESC
;






-- VACCINATION ANALYSIS 
SELECT location, date,total_tests, new_tests, positive_rate, tests_per_case, tests_units, people_vaccinated, people_fully_vaccinated, total_boosters, 
		new_vaccinations, new_vaccinations_smoothed, total_tests1, total_cases, new_cases
FROM CovidVaccinations
ORDER BY location, date;

SELECT location, MAX(CAST(total_tests AS bigint)) AS TOTAL_TESTS
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income') 
GROUP BY location
ORDER BY TOTAL_TESTS;

----SELECT *
----FROM CovidVaccinations
----WHERE location IN ('Falkland Islands',
----						'Kyrgyzstan',
----						'Greenland',
----						'Guadeloupe',
----						'England',
----						'Guernsey',
----						'American Samoa',
----						'Honduras',
----						'Kiribati',
----						'Libya',
--						'Jersey',
--						'Isle of Man',
--						'French Guiana',
--						'Cape Verde',
--						'Cook Islands',
--						'Bonaire Sint Eustatius and Saba',
--						'French Polynesia' )
--;

SELECT location, date, positive_rate, total_tests, (CAST(total_tests AS bigint)*CAST(positive_rate AS float))/100 AS positive_cases, new_cases, population, total_cases
FROM CovidVaccinations
WHERE location = 'Cuba'
ORDER BY date;

SELECT *
FROM CovidVaccinations
WHERE location = 'Cuba'
ORDER BY date;

-- max(total_vacc), max(people vacc), max(people fully vaccinated), max(boosters)


SELECT *
FROM CovidVaccinations
WHERE location = 'India'
ORDER BY date;

--VACCINATION COVERAGE
SELECT location, MAX(date) as record_date, population, MAX(CAST(people_vaccinated as bigint)) AS total_vaccinated_people,
		MAX(CAST(people_fully_vaccinated as bigint)) AS total_fullyvaccinated_people, MAX(CAST(total_boosters as bigint)) AS total_boosters
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income') 
GROUP BY location, population
ORDER BY total_vaccinated_people; /*COUNTRY-WISE distribution of vaccination - population covered with atleast one vaccination dose,
								population that is fully vaccinated, and total booseters distributed amongst the fully vaccinated*/

WITH VACCINATION_COVERAGE 
AS
(
SELECT location, MAX(date) as record_date, population, MAX(CAST(people_vaccinated as bigint)) AS total_vaccinated_people,
		MAX(CAST(people_fully_vaccinated as bigint)) AS total_fullyvaccinated_people, MAX(CAST(total_boosters as bigint)) AS total_boosters
FROM CovidVaccinations
WHERE continent IS NOT NULL 
GROUP BY location, population
)
SELECT *, (total_vaccinated_people/population)*100 AS vaccination_coverage_vc, 
			(total_fullyvaccinated_people/population)*100 AS vc_fullyvaccinated
FROM VACCINATION_COVERAGE
ORDER BY population DESC; /*vaccination coverage rate as a measure to total population of every country. */

/*A FEW COUNTRIES LACK ANY DATA ON VACCINATION IN THIS DATABASE. THE BELOW TEMP TABLE CAN BE USED IN 'WHERE' CLAUSE OF QUERIES TO 
  AVOID THESE COUNTRIES WHILE AGGREGATING DATA*/

DROP TABLE IF EXISTS #COUNTRIES_NODATA
CREATE TABLE #COUNTRIES_NODATA 
( Location nvarchar(100) )

INSERT INTO #COUNTRIES_NODATA
SELECT location
FROM CovidVaccinations
GROUP BY location
HAVING MAX(people_vaccinated) IS NULL

SELECT * FROM #COUNTRIES_NODATA;


--TESTING COVERAGE
SELECT location, AVG(CAST(population as bigint)) AS population, MAX(CAST(total_cases as bigint)) AS Total_cases,
		MAX(CAST(total_tests as bigint)) AS Total_tests, MAX(CAST(positive_rate as float)) AS Positive_rate, 
		AVG(CAST(tests_per_case AS float)) AS meanof_tests_per_case
FROM CovidVaccinations
WHERE total_tests IS NOT NULL OR positive_rate IS NOT NULL
GROUP BY location
ORDER BY Total_cases DESC;



-- VIEWS 

CREATE VIEW COUNTRYWISE_PANDEMIC_IMPACT AS
(
SELECT location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income')
GROUP BY location
)
;

CREATE VIEW COUNTRYWISE_INFECTION_IMPACT_RATE AS
(
SELECT location, totalcases, totaldeaths, country_population, (totaldeaths/totalcases) AS CFR, (totalcases/country_population) AS PREVALENCE, (totaldeaths/country_population) AS MORTALITY_RATE
FROM (
SELECT location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
FROM CovidVaccinations
WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
						'South America', 'Lower middle income', 'Low income', 'North Korea') 
GROUP BY location
	  ) AS COUNTRYWISE_RATE
WHERE totalcases != 0 
)
;

/*TRIED IMPLEMENTING A CTE WITH 'CREATE VIEW' BUT WAS DETTERED WITH ERRORS, SO INSTEAD DECIDED TO ADAPT SUBQUERYING WHICH IS SIMPLE AND 
 EFFECTIVE IN THIS CASE AS THERE IS NO NEED FOR REPRPODUCING THE QUERY HERE */

--WITH COVIDDATACOUNTRYWISE 
--AS 
--(
--SELECT continent, location, country_population, (totaldeaths/totalcases)*100 AS CFR, (totalcases/country_population) AS PREVALENCE, 
--		(totaldeaths/country_population) AS MORTALITY_RATE
--FROM (
--SELECT continent, location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
--FROM CovidVaccinations
--WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 
--						'South America', 'Lower middle income', 'Low income', 'North Korea') 
--GROUP BY location, continent
--	  ) AS COUNTRYWISE_RATE
--WHERE totalcases != 0 
--);

--GO

--CREATE VIEW CONTINENTWISE_INFECTION_IMPACT_RATE AS
--(
--SELECT continent, SUM(country_population) AS continent_population, AVG(CFR) AS mean_CFR, AVG(PREVALENCE) AS mean_PREVALENCE,
--		AVG(MORTALITY_RATE) AS mean_MORTALITY_RATE
--FROM COVIDDATACOUNTRYWISE
--WHERE continent IS NOT NULL 
--GROUP BY continent
--);



CREATE VIEW CONTINENTWISE_INFECTION_IMPACT_RATE AS
(
SELECT continent, SUM(country_population) AS continent_population, AVG(CFR) AS mean_CFR, AVG(PREVALENCE) AS mean_PREVALENCE,
       AVG(MORTALITY_RATE) AS mean_MORTALITY_RATE
FROM 
(
    SELECT continent, location, country_population, (totaldeaths/totalcases)*100 AS CFR, (totalcases/country_population) AS PREVALENCE, 
        (totaldeaths/country_population) AS MORTALITY_RATE
    FROM (
        SELECT continent, location, SUM(new_cases) AS totalcases, SUM(new_deaths) AS totaldeaths, AVG(population) AS country_population
        FROM CovidVaccinations
        WHERE location NOT IN ('Asia', 'Africa', 'High Income', 'European Union', 'World', 'Upper middle income', 'Europe', 'North America', 'South America', 'Lower middle income', 'Low income', 'North Korea') 
        GROUP BY location, continent
         ) AS COUNTRYWISE_RATE
    WHERE totalcases != 0 
 ) AS COVIDDATACOUNTRYWISE
WHERE continent IS NOT NULL 
GROUP BY continent
)



CREATE VIEW VACCINATION_COVERAGE AS
(
SELECT *, (total_vaccinated_people/population)*100 AS vaccination_coverage_vc, 
			(total_fullyvaccinated_people/population)*100 AS vc_fullyvaccinated
FROM 
(
SELECT location, MAX(date) as record_date, population, MAX(CAST(people_vaccinated as bigint)) AS total_vaccinated_people,
		MAX(CAST(people_fully_vaccinated as bigint)) AS total_fullyvaccinated_people, MAX(CAST(total_boosters as bigint)) AS total_boosters
FROM CovidVaccinations
WHERE continent IS NOT NULL 
GROUP BY location, population
) AS VACCINATION_COVERAGE
)

CREATE VIEW TESTING_COVERAGE AS 
(
SELECT location, AVG(CAST(population as bigint)) AS population, MAX(CAST(total_cases as bigint)) AS Total_cases,
		MAX(CAST(total_tests as bigint)) AS Total_tests, MAX(CAST(positive_rate as float)) AS Positive_rate, 
		AVG(CAST(tests_per_case AS float)) AS meanof_tests_per_case
FROM CovidVaccinations
WHERE total_tests IS NOT NULL OR positive_rate IS NOT NULL
GROUP BY location
)
