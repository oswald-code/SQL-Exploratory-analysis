-- Analyzing global malaria deaths from 1990-2015

-- An Entity is at a lower level is defined asa country, at a higher level countries are grouped as world,
  -- WHO groups, World Bank groups

use MalariaDeaths;

SELECT * FROM [global-deaths];
SELECT * FROM incidence;
SELECT * FROM [deaths.age];

--****************************************************

-- calculate total deaths for each entitTY(countries), sort deaths beginning with the highest
SELECT Entity,
       code, 
	   SUM(deaths) AS Total_deaths
FROM [global-deaths]
WHERE Code IS NOT NULL -- to remove high level entities
GROUP BY Entity,code
ORDER BY Total_deaths DESC;

--*************************************************

-- calculate the cumulative deaths for each entity
SELECT Entity,
	   YEAR,
	   deaths, 
	   (SUM(deaths) OVER(PARTITION BY entity ORDER BY year)) AS cumulative_deaths 
FROM [global-deaths];

--**********************************************************

-- Are deaths increasing or decreasing? Calculate yearly % change in total malaria deaths
WITH lag_deaths AS (SELECT Entity
						   ,Year
						   ,deaths
						   ,LAG(deaths) OVER(PARTITION BY entity ORDER BY year) AS previous_deaths
				FROM [global-deaths]), 
	 current_deaths AS (SELECT *, 
							round(((deaths-previous_deaths)/(nullif(previous_deaths,0))*100),4) AS percent_change
				 FROM lag_deaths)
SELECT * 
		,CASE WHEN percent_change = 0 THEN 'No change'
			 WHEN percent_change >0 THEN 'Increase'
			 WHEN percent_change< 0 THEN 'Decrease' 
			 END AS Yearly_trend
FROM current_deaths;
 
 --**************************************************************

-- calculate malaria deaths for entities at higher level for each age group
SELECT Entity,
		SUM([Under 5 years] )AS "Below 5 years",
		SUM([5-14 years ]) AS "Between 5- 14 years",
		SUM([15-49 years ]) AS "Between 15-49 years",
		SUM([50-69 years ]) AS "Between 50-69 years",
		SUM([70+ years])AS "Above 70 years"
FROM [deaths.age]
WHERE code is null
GROUP BY Entity
ORDER BY [Below 5 years] DESC,
		 [Between 15-49 years] DESC,
		 [Between 5- 14 years] DESC,
		 [Between 50-69 years]DESC,
		 [Above 70 years] DESC; 

--*******************************************************************

-- calculate total malaria deaths for each age group

 SELECT 
		FORMAT(SUM([Under 5 years ]),'#,#')  AS "Below 5 years",
		FORMAT(SUM([5-14 years]), '#,#') AS "Between 5- 14 years",
		FORMAT(SUM([15-49 years]),'#,#') AS "Between 15-49 years",
		FORMAT(SUM([50-69 years]),'#,#') AS "Between 50-69 years",
		FORMAT(SUM([70+ years] ),'#,#') AS "Above 70 years"
FROM [deaths.age];

--***********************************************************************

-- Is a country's income level related to it's malaria deaths.calculate total malaria deaths by world bank income ranking 

SELECT entity, 
	  FORMAT(sum([deaths]),'#,#') AS 'Income Level Deaths'
FROM [global-deaths]
WHERE Entity like '%Income%'
GROUP BY Entity
ORDER BY [Income Level Deaths] DESC;

--*************************************************************************

-- calculate % change for malaria deaths for Uganda entity
WITH deaths_lag AS(SELECT 
	   Year,
	   [deaths], 
	   LAG([deaths]) OVER(ORDER BY year) AS lag_deaths
FROM [global-deaths]
WHERE Entity='Uganda'),
Deaths_trend AS(
			SELECT *,
			round((([deaths]-lag_deaths)/lag_deaths)*100,2) AS Annaul_trend
FROM deaths_lag)
SELECT * FROM Deaths_trend;

--*********************************************************************

-- calculate cumulative malaria deaths for uganda
SELECT Year,
	   [deaths],
	   sum([deaths]) OVER(ORDER BY year) AS 'Cumulative deaths'
FROM [global-deaths]
WHERE Entity ='uganda';

--********************************************************************

-- find the top 20 countries with highest malaria deaths for the entire period
SELECT Entity AS Country
	  ,FORMAT(SUM([deaths]), '#,#') AS 'total deaths' 
FROM [global-deaths]
WHERE code is not null
GROUP BY Entity,Code
ORDER BY [total deaths] DESC
offset 1 ROW -- to remove overall world deaths
FETCH FIRST 20 ROWS only;

--****************************************************************

-- calculate overall malaria deaths for Uganda for each age group
SELECT Entity,
	   FORMAT(SUM([Under 5 years ]), '#,#') AS 'Below 5', 
	   FORMAT(sum([5-14 years ]), '#,#') AS 'Btn 5-14 years',
	   FORMAT(sum([15-49 years ]), '#,#') AS 'Btn 15-49 years',
	   FORMAT(sum([50-69 years ]), '#,#') AS 'Btn 50-69 years',
	   FORMAT(sum([70+ years ]), '#,#') AS 'Above 70 years' 
FROM [deaths.age]
WHERE Entity='Uganda'
GROUP BY Entity;

--*************************************************************

WITH Highest_deaths AS (
						SELECT Entity
							   ,Code
						       ,Year
							   ,deaths
							   ,RANK() OVER(PARTITION BY YEAR ORDER BY [deaths] DESC) AS ranked
						FROM [global-deaths]
						WHERE Code IS NOT NULL)
SELECT * FROM Highest_deaths
WHERE ranked IN (1 ,2,3,4,5);

--**************************************************************

--- compare malaria deaths for AFRICA and South East Entities for each year	 
select Entity,
	   year, 
	  sum(deaths)	
from [global-deaths]
where entity in ('Africa', 'South-East Asia')
group by Entity,Year;

--**************************************************************

--- find the top 20% of countries by malaria deaths for the overall period
WITH cumulative_dist AS
	(SELECT Entity,
	   SUM ([deaths]) AS Total_deaths,
	   CUME_DIST() OVER(ORDER BY SUM([deaths]) desc) deaths_distribution
FROM [global-deaths]
WHERE Code IS NOT NULL
GROUP BY Entity)
SELECT * FROM cumulative_dist
WHERE deaths_distribution <= 0.2 AND Entity NOT IN ('World');


