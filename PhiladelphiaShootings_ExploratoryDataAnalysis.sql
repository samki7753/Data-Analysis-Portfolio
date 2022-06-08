/* Exploratory Data Analysis of Shooting Victims in Philadelphia from 1/1/2015 - 5/30/2022 
Data sourced from Open Data Philly */ 

USE TEST;
SET @TotalCount = (SELECT COUNT(*) FROM shootings);


-- Change date_ and time fields to correct data type 
ALTER TABLE shootings
MODIFY COLUMN date_ datetime,
MODIFY COLUMN time time;

-- Combine date_ and time fields to one DateTime_ field 
UPDATE shootings
SET date_ = CONCAT(LEFT(date_,10), ' ',time);

-- Change date_ field name to datetime_ --
ALTER TABLE shootings
CHANGE date_ DateTime_ datetime;

-- Change officer_involved, offender_injured, & offender_deceased fields to binary 
UPDATE shootings 
SET officer_involved = IF(officer_involved = 'Y', 1,0),
	offender_injured = IF(offender_injured = 'Y', 1,0),
	offender_deceased = IF(offender_deceased = 'Y', 1,0);


-- Total Shootings per Year with YoY % Difference

SELECT year, TotalShootings,((TotalShootings - LAG(TotalShootings) OVER(ORDER BY year))/LAG(TotalShootings) OVER(ORDER BY year))*100 AS YoYPercentDiff
FROM (SELECT year, COUNT(*) AS TotalShootings 
FROM shootings 
GROUP BY year) t1;
/* In the last 6 years, 2017 was the only year that experienced a YoY decrease in total shootings.
2020 experienced the largest YoY % increase in total shootings at 53%. It's important to note that 2022 
only goes up to 5/30. */ 


-- Analysis of Running Total up to 5/30 for all years

WITH x AS (
	SELECT DATE_FORMAT(DateTime_, '%Y-%m-%d') Date, COUNT(*) Count
    FROM shootings 
    GROUP BY Date
    ORDER BY Date),

y AS (SELECT Date, Count, SUM(COUNT) OVER(PARTITION BY DATE_FORMAT(Date, '%y') ORDER BY Date) RunningTotal
FROM x
ORDER BY Date),

z AS (SELECT DATE_FORMAT(Date, '%Y') Year, Date, RunningTotal
FROM y 
WHERE DATE_FORMAT(Date, '%m') <=5 AND DATE_FORMAT(Date, '%d') <= 30)

SELECT Year, MAX(RunningTotal) CountUpToMay30
FROM z
GROUP BY Year;  
/* Since 2017, total shooting victims from Jan 1 - May 30 have increased YoY. 2022 recorded about 1.9 times the 
number of cases in 2017. */


-- Total Shootings by Month

SELECT DATE_FORMAT(DateTime_, '%M') Month, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings 
GROUP BY Month
ORDER BY Count DESC;
/* August had the most number of shooting victims at 1195, which was about 9.7% of the total cases. 
May was a close second with 1193 shooting victims. */ 


-- Total Shootings by Season (Winter, Spring, Summer, Fall) 

SELECT CASE WHEN DATE_FORMAT(DateTime_, '%M') IN ('December','January','February') THEN 'Winter'
			WHEN DATE_FORMAT(DateTime_, '%M') IN ('March', 'April', 'May') THEN 'Spring'
            WHEN DATE_FORMAT(DateTime_, '%M') IN ('June', 'July', 'August') THEN 'Summer'
            ELSE 'Fall' END Season,
	    COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings
GROUP BY Season
ORDER BY Count DESC;
/* Of the 4 seasons, summer had the most number of shooting victims at 3395, which was about 27.5% of total cases. 
Spring (3168) and fall (3109) had about the same number of cases. */


-- Total Shootings by Day of Week 

SELECT DATE_FORMAT(DateTime_, '%a') DayOfWeek, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings
GROUP BY DayOfWeek
ORDER BY Count DESC; 
-- Sunday had the most number of shooting victims at 1967, which was about 16% of total cases. 


-- Total Shootings by Hour of Day 

SELECT DATE_FORMAT(DateTime_, '%H') HourOfDay, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentOfTotal
FROM shootings
GROUP BY HourOfDay
ORDER BY Count DESC; 
-- 9-10pm had the most number of shooting victims at 972, which was about 8% of total cases. 
            
            
-- Total Shootings by Race 

SELECT race, COUNT(*) Count, COUNT(*)*100/@TotalCount AS PercentOfTotal
FROM shootings
WHERE race <> ''
GROUP BY race
ORDER BY PercentOfTotal DESC;
-- The majority of shootings are of African Americans at 83%. 


-- Percent of Fatal Shootings by Race 

SELECT race, SUM(fatal)*100/COUNT(*) PercentFatal
FROM shootings
WHERE race <> ''
GROUP BY race
ORDER BY PercentFatal DESC;
-- Asian, African Americans, and Whites have about the same percentage of fatal shootings at about 20%.


-- Total Shootings by Age Group 

SELECT AgeGroup, COUNT(*) Count, COUNT(*)*100/@TotalCount AS PercentOfTotal
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
FROM shootings
WHERE race <> ''
) t2
GROUP BY AgeGroup
ORDER BY COUNT(*) DESC;
-- Most shooting victims (44%) are in the age group 21-30. 


-- Fatal Shootings by Age Group 

SELECT AgeGroup, SUM(fatal) FatalCount, COUNT(*) TotalCount, SUM(fatal)*100/COUNT(*) PercentFatal
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
FROM shootings
WHERE race <> '') t3
GROUP BY AgeGroup
ORDER BY PercentFatal DESC;
/* The age group 81-90 had the highest percentage of fatal shootings at 100%. However, it is 
worth noting that the total count of cases in this age group was 2. The age group 0-10 had the 
next highest percentage of fatal shootings at 25.5%. */


-- Most dangerous hour of the day for each age group

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
FROM shootings
WHERE race <> '') t4
GROUP BY AgeGroup, HourOfDay
ORDER BY AgeGroup, TotalCount DESC)


SELECT x1.AgeGroup, x1.HourOfDay, x1.TotalCount, x1.TotalOutside, x1.TotalOutside*100/x1.TotalCount PercentOutside
FROM x x1 LEFT JOIN x x2 ON x1.AgeGroup = x2.AgeGroup AND x1.TotalCount < x2.TotalCount
WHERE x2.TotalCount IS NULL;
/* For the age group 0-20, the most dangerous hour of the day is 9pm with a total of 273 shootings. About 96% of these cases occcur outside.
To combat this, the city of Philadelphia can establish a 9pm curfew for minors who are not out with an adult or who do not have written permission
from their guardian to be outside. */ 


-- Percentage of Age Groups that are African American 

WITH x AS (
SELECT AgeGroup, race, COUNT(*) TotalCount, SUM(outside) TotalOutside, SUM(fatal) TotalFatal
FROM (SELECT race, fatal, outside,
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
FROM shootings
WHERE race <>'') t5
GROUP BY AgeGroup, race
ORDER BY AgeGroup, TotalCount DESC),

y AS (SELECT AgeGroup, COUNT(*) TotalCount
FROM (SELECT 
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
FROM shootings
WHERE race <>'') t5
GROUP BY AgeGroup
ORDER BY AgeGroup, TotalCount DESC)


SELECT race, AgeGroup, TotalCount*100/(SELECT TotalCount FROM y WHERE x.AgeGroup = y.AgeGroup)PercentOfAgeGroup
FROM x 
WHERE race = 'B'
ORDER BY AgeGroup;
/* For every age group except 81-90, African Americans comprise the majority of shooting victims. However, it is worth noting that the age group
81-90 consists of only 2 total shooting cases*/


-- Total Shootings by Sex 

SELECT sex, COUNT(*) Count, COUNT(*)*100/@TotalCount PercentofTotal
FROM shootings 
GROUP BY sex;
-- About 90% of shooting victims are male. 


-- Total Shootings w/ Officer Involved 

SELECT COUNT(*) CasesWithOfficer
FROM shootings 
WHERE officer_involved = 1;
## Officers were involved in 90 out of the 12336 cases. 


-- Total Shootings w/ Officer Involved Where Offender Deceased 

SELECT COUNT(*) CasesWithOfficerAndDeceasedOffender
FROM shootings 
WHERE officer_involved = 1 AND offender_deceased = 1;
-- In shootings with officers involved, 22% resulted in the offender deceased. 


-- Total Shootings within different distance intervals from my old off campus apartment at 4103 Walnut St. 

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
-- There were 283 shooting victims within a 1km radius of my old off campus apartment at 4103 Walnut St. 


            










































            








































