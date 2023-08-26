/* Exploring Canadian Covid-19 data using Postgres SQL */

--data from https://www150.statcan.gc.ca/n1/en/catalogue/13260003

--9 or 99 is used as dummy value for week and year categories, when value unknown




--create tables containing values for all feature encoded columns in our data

CREATE TABLE genders
(gender_id INT, gender VARCHAR);

INSERT INTO genders (gender_id, gender)
VALUES
	(1, 'Male'),
	(2, 'Female'),
	(9, 'Not stated');

CREATE TABLE regions
(region_id INT, region varchar);

INSERT INTO regions (region_id, region)
VALUES
	(1, 'Atlantic'),
	(2, 'Quebec'),
	(3, 'Ontario & Nunavut'),
	(4, 'Prairies'),
	(5, 'BC & Yukon');
	
CREATE TABLE age_groups
(age_group_id INT, age_group VARCHAR);

INSERT INTO age_groups (age_group_id, age_group)
VALUES
	(1, '0 to 19 years'),
	(2, '20 to 29 years'),
	(3, '30 to 39 years'),
	(4, '40 to 49 years'),
	(5, '50 to 59 years'),
	(6, '60 to 69 years'),
	(7, '70 to 79 years'),
	(8, '80+ years'),
	(99, 'Not stated');
	
CREATE TABLE hospital_states
(hospital_status_id INT, hospital_status VARCHAR);

INSERT INTO hospital_states (hospital_status_id, hospital_status)
VALUES
	(1, 'ICU'),
	(2, 'Non-emergency'),
	(3, 'Not hospitalized'),
	(9, 'Not stated');

CREATE TABLE death_states
(death_id INT, death VARCHAR);

INSERT INTO death_states (death_id, death)
VALUES
	(1, 'Yes'),
	(2, 'No'),
	(9, 'Not stated');
	
-- import data from stats canada csv file

DROP TABLE IF EXISTS covid_data_raw CASCADE;

CREATE TABLE covid_data_raw
(case_id INT PRIMARY KEY, region_id INT, week INT, week_group INT, year INT,
gender_id INT, age_group_id INT, hospital_status_id INT, death_id INT);

COPY covid_data_raw FROM 'C:\Users\pvang\Desktop\COVID19_SQL\COVID19-eng.csv' WITH DELIMITER ',' CSV HEADER;

--create view 
DROP VIEW IF EXISTS covid_data;

CREATE VIEW covid_data AS
SELECT case_id, region, year, week, gender, age_group, hospital_status, death
FROM covid_data_raw	
	JOIN genders ON covid_data_raw.gender_id = genders.gender_id
	JOIN regions ON covid_data_raw.region_id = regions.region_id
	JOIN age_groups ON covid_data_raw.age_group_id = age_groups.age_group_id
	JOIN hospital_states ON covid_data_raw.hospital_status_id = hospital_states.hospital_status_id
	JOIN death_states ON covid_data_raw.death_id = death_states.death_id
;


/* **************************************************************************** */



-- quick peek at base table view we'll be working from

SELECT * FROM covid_data
ORDER BY year , week
LIMIT 1000;


--new infections grouped by week

SELECT year, week, COUNT(*) AS new_infections
FROM covid_data
GROUP BY year, week;

--Rolling count of new infections

WITH new_infections_table AS (
	SELECT year, week, COUNT(*) AS new_infections
	FROM covid_data
	GROUP BY year, week
)

SELECT year, week, new_infections,
SUM(new_infections) OVER (ORDER BY year, week) AS total_infections
FROM new_infections_table
WHERE year !=99 AND week !=99
ORDER BY year, week;



--total cases and deaths by age group

SELECT age_group,
	   COUNT(*) AS total_cases,
	   SUM(CASE death WHEN 'Yes' THEN 1 ELSE 0 END) AS total_deaths
FROM covid_data
GROUP BY age_group;


--hospitalization and death count per week

SELECT year, week, COUNT(*) AS new_infections,
	   SUM(CASE hospital_status 
		   WHEN 'ICU' THEN 1
		   WHEN 'Non-emergency' THEN 1
		   ELSE 0 END) AS hospitalized,
	   SUM(CASE death WHEN 'Yes' THEN 1 ELSE 0 END) AS deaths
FROM covid_data
WHERE year != 99 AND week != 99
GROUP BY year, week;


--weekly and running total for infections, hospitalization and deaths all together for export

WITH weekly_counts AS (

	SELECT year, week, COUNT(*) AS new_infections,
	   SUM(CASE hospital_status 
		   WHEN 'ICU' THEN 1
		   WHEN 'Non-emergency' THEN 1
		   ELSE 0 END) AS hospitalized,
	   SUM(CASE death WHEN 'Yes' THEN 1 ELSE 0 END) AS deaths
	FROM covid_data
	WHERE year != 99 AND week != 99
	GROUP BY year, week
)

SELECT year, week, 
new_infections, SUM(new_infections) OVER (ORDER BY year, week) AS total_infections,
hospitalized, SUM(hospitalized) OVER (ORDER BY year, week) AS total_hospitalized,
deaths, SUM(deaths) OVER (ORDER BY year, week) AS total_deaths
FROM weekly_counts
WHERE year !=99 AND week !=99
ORDER BY year, week;


















