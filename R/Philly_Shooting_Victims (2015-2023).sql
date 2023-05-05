-- Specify correct database
USE Philly_Shootings;


-- DATA CLEANING ---------------------------------------------------

-- Disable safe update mode to clean the data 
SET SQL_SAFE_UPDATES=0;

-- Clean date_ field by removing trailing zeros
UPDATE shootings
SET date_ = LEFT(date_, 10);

-- Change date_ and time fields to correct data types
ALTER TABLE shootings
MODIFY COLUMN date_ date,
MODIFY COLUMN time time;

-- Create date_time field
ALTER TABLE shootings
ADD COLUMN date_time datetime;

UPDATE shootings
SET date_time = CONCAT(date_, ' ',time);

-- Modify officer_involved, offender_injured, & offender_deceased fields from Y/N to 1/0 for aggregations
UPDATE shootings 
SET officer_involved = IF(officer_involved = 'Y', 1,0),
	offender_injured = IF(offender_injured = 'Y', 1,0),
	offender_deceased = IF(offender_deceased = 'Y', 1,0);


-- Data Analysis ---------------------------------------------------

-- Date Range of Data: 1/1/2015 - 5/2/2023
SELECT MIN(date_), MAX(date_)
FROM shootings;


-- Total Shootings per Year with YoY % Difference
SELECT year, TotalShootings,((TotalShootings - LAG(TotalShootings) OVER(ORDER BY year))/LAG(TotalShootings) OVER(ORDER BY year))*100 AS YoYPercentDiff
FROM (SELECT year, COUNT(*) AS TotalShootings 
	  FROM shootings 
	  GROUP BY year) t1;
/* From 2016 to 2021, total shootings increased YoY. 2020 had the largest YoY % increase at 53%, and since then, 
total shootings has remained relatively high compared to pre-2020 levels. It's important to note that 2023
only includeds data up to 5/2. */ 


-- Analysis of Running Total up to 5/2 (date of analysis) for all years
WITH x AS (
	SELECT date_, COUNT(*) Count
    FROM shootings 
    GROUP BY date_
    ORDER BY date_),

y AS (SELECT date_, Count, SUM(COUNT) OVER(PARTITION BY DATE_FORMAT(date_, '%y') ORDER BY date_) RunningTotal
FROM x
ORDER BY date_),

z AS (SELECT DATE_FORMAT(date_, '%Y') Year, date_, RunningTotal
FROM y 
WHERE DATE_FORMAT(date_, '%m') <=5 AND DATE_FORMAT(date_, '%d') <= 02)

SELECT Year, MAX(RunningTotal) CountUpToMay02
FROM z
GROUP BY Year;  
/* 2023 is reporting an improving trend with less total shootings victims so far (up to May 2) compared to 2022 and 2021.
However, the total is higher than pre-2021 levels.  */


-- Total Shootings by Month (2015 - 2022)
SET @TotalCount = (SELECT COUNT(*) 
				   FROM shootings
                   WHERE DATE_FORMAT(date_, '%Y') < 2023);

SELECT DATE_FORMAT(date_, '%M') Month, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings 
WHERE DATE_FORMAT(date_, '%Y') < 2023
GROUP BY Month
ORDER BY Count DESC;
/* The summer months reported the most cases of shooting victims. 
August had the most number of shooting victims at 1,347, which was about 10.4% of total cases.
Jan - Apr had the least cases of shooting victims. */ 


-- Total Shootings by Season (2015 - 2022) 
SELECT CASE WHEN DATE_FORMAT(date_, '%M') IN ('December','January','February') THEN 'Winter'
			WHEN DATE_FORMAT(date_, '%M') IN ('March', 'April', 'May') THEN 'Spring'
            WHEN DATE_FORMAT(date_, '%M') IN ('June', 'July', 'August') THEN 'Summer'
            ELSE 'Fall' END Season,
	    COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings
WHERE DATE_FORMAT(date_, '%Y') < 2023
GROUP BY Season
ORDER BY Count DESC;
/* Seasonal counts show a positive correlation between outside temperature and total cases of shooting victims. */


-- Total Shootings by Day of Week 
SET @TotalCount = (SELECT COUNT(*) 
				   FROM shootings);

SELECT DATE_FORMAT(date_, '%a') DayOfWeek, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings
GROUP BY DayOfWeek
ORDER BY Count DESC; 
/* The share of cases by day of the week shows a relatively even distribution. Sunday had the most number of shooting victims at 2,108,
which was about 15.6% of total cases, followed by Monday at 2,095, which was about 15.5% of total cases. */


-- Total Shootings by Hour of Day 
SELECT DATE_FORMAT(time, '%H') HourOfDay, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings
GROUP BY HourOfDay
ORDER BY Count DESC; 
/* 9pm-12am had the most number of shooting victims at 3,108, which was about 23% of total cases. */


-- Percent of Fatal Shootings by Hour of Day
SELECT DATE_FORMAT(time, '%H') HourOfDay, SUM(fatal)/COUNT(*)*100 PercentFatal
FROM shootings
GROUP BY HourOfDay
ORDER BY PercentFatal DESC;
/* 7-9am had the highest percent of fatal shootings at about 27% of total cases. */


-- Total Shootings by Race
SELECT race, COUNT(*) Count, COUNT(*)*100/@TotalCount AS PercentOfTotal
FROM shootings
WHERE race <> ''
GROUP BY race
ORDER BY PercentOfTotal DESC;
/* The overwhelming majority of shooting victims are Black at 82.5% of total cases. 
White victims rank second at 16.7%. */


-- Percent of Fatal Shootings by Race 
SELECT race, SUM(fatal)*100/COUNT(*) PercentFatal
FROM shootings
WHERE race <> ''
GROUP BY race
ORDER BY PercentFatal DESC;
-- Across race groups, the percent of fatal shootings is similar at around 20% of total cases. 


-- Total Shootings by Age Group
SELECT AgeGroup, COUNT(*) Count, COUNT(*)/@TotalCount*100 AS PercentOfTotal, SUM(fatal)*100/COUNT(*) PercentFatal
FROM (SELECT fatal,
	CASE WHEN age>= 0 AND age<= 10 THEN '0-10'
		 WHEN age>= 11 AND age<= 20 THEN '11-20'
         WHEN age>= 21 AND age<= 30 THEN '21-30'
         WHEN age>= 31 AND age<= 40 THEN '31-40'
         WHEN age>= 41 AND age<= 50 THEN '41-50'
         WHEN age>= 51 AND age<= 60 THEN '51-60'
         WHEN age>= 61 AND age<= 70 THEN '61-70'
         WHEN age>= 71 AND age<= 80 THEN '71-80'
         WHEN age>= 81 AND age<= 90 THEN '81-90'
         WHEN age>= 91 AND age<= 100 THEN '91-100'
         ELSE '>100'
	END AS AgeGroup
    FROM shootings) t2
GROUP BY AgeGroup
ORDER BY PercentOfTotal DESC;
/* Most shooting victims are in the 21-30 age group at about 43% of total cases. */ 


-- Total Number of Shooting Victims under 18
SELECT COUNT(*) victims_under_18, COUNT(*)/@TotalCount*100 percent_of_total, SUM(fatal) fatal_count
FROM shootings
WHERE age < 18;
/* Minors made up about 8.6% of total cases. 14.7% of minor cases were fatal shootings. */


-- Most dangerous hour of the day to be outside for each age group
WITH x AS (
SELECT AgeGroup, HourOfDay, COUNT(*) TotalCount, SUM(outside) TotalOutside
FROM (SELECT DATE_FORMAT(time,'%H') AS HourOfDay, fatal, outside,
	CASE WHEN age>= 0 AND age<= 10 THEN '0-10'
		 WHEN age>= 11 AND age<= 20 THEN '11-20'
         WHEN age>= 21 AND age<= 30 THEN '21-30'
         WHEN age>= 31 AND age<= 40 THEN '31-40'
         WHEN age>= 41 AND age<= 50 THEN '41-50'
         WHEN age>= 51 AND age<= 60 THEN '51-60'
         WHEN age>= 61 AND age<= 70 THEN '61-70'
         WHEN age>= 71 AND age<= 80 THEN '71-80'
         WHEN age>= 81 AND age<= 90 THEN '81-90'
         WHEN age>= 91 AND age<= 100 THEN '91-100'
         ELSE '>100'
	END AS AgeGroup
FROM shootings) t4
GROUP BY AgeGroup, HourOfDay
ORDER BY AgeGroup, TotalCount DESC),

y AS (SELECT MAX(TotalCount) TotalCount, AgeGroup
FROM x
GROUP BY AgeGroup)

SELECT x.AgeGroup, x.HourOfDay, x.TotalCount, x.TotalOutside
FROM x INNER JOIN y ON x.TotalCount = y.TotalCount AND x.AgeGroup = y.AgeGroup;
/* The most dangerours hours of the day to be outside for people aged 20 and under are 8-10pm. 
To combat this, the city can institute an 8pm curfew for minors who are not out with an adult 
or who do not have written permission from their guardian to be outside. */


-- Total Shootings by Sex
SELECT sex, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentofTotal, SUM(fatal)/COUNT(*)*100 PercentFatal
FROM shootings
GROUP BY sex;
/* 90% of total cases were male. Male shootings victims were more likely to receive a fatal injury at
about 5 percentage points higher than females. */ 


-- Total Shootings w/ Officer Involved 
SELECT COUNT(*) CasesWithOfficer, COUNT(*)/@TotalCount PercentofTotal
FROM shootings 
WHERE officer_involved = 1;
## No shooting victim cases with officer involved. Potential data quality issue.


-- Total Shootings within different distance intervals from my previous apartment at 4103 Walnut St. 
DELIMITER //
CREATE FUNCTION fnDistance (latdegree1 float, longdegree1 float, latdegree2 float, longdegree2 float)
RETURNS float
DETERMINISTIC
BEGIN
DECLARE lat1 float; 
DECLARE lat2 float;
DECLARE long1 float;
DECLARE long2 float; 
DECLARE distance float;
SET lat1=RADIANS(latdegree1);
SET long1=RADIANS(longdegree1);
SET lat2=RADIANS(latdegree2);
SET long2=RADIANS(longdegree2);
SET distance = ATAN2(SQRT(POWER(COS(lat1)*SIN(long2-long1),2)+POWER(COS(lat2)*SIN(lat1)-
SIN(lat2)*COS(lat1)*COS(long2-long1),2)),(SIN(lat2)*SIN(lat1)+
COS(lat2)*COS(lat1)*COS(long2-long1)))*6372.795;
RETURN distance;
END //
DELIMITER ;

SET @lat = 39.95484025097715;
SET @lon = -75.20485957551308;

WITH t1 AS (
SELECT ROUND(fnDistance(@lat, @lon, lat, lng),0) Distance
FROM shootings)

SELECT CASE WHEN Distance <= 1 THEN ' within 1km'
			WHEN Distance > 1 AND DISTANCE <= 5 THEN 'Between 1-5km'
			WHEN Distance > 5 AND Distance <= 10 THEN 'Between 5-10km'
            ELSE 'Greater than 10km' 
            END Distance_, COUNT(*) Count
FROM t1
GROUP BY Distance_
ORDER BY Distance_ ;
-- There were 324 shooting victims within a 1km radius of my old apartment at 4103 Walnut St. 


