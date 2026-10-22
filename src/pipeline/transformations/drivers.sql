CREATE OR REFRESH MATERIALIZED VIEW drivers (
  driver_id INT COMMENT 'Surrogate primary key of the driver (Ergast driverId). Join key to results, qualifying, lap_times, pit_stops, sprint_results and driver_standings.',
  driver_ref STRING COMMENT 'Unique lowercase text key of the driver (e.g. \'hamilton\', \'max_verstappen\'); stable, URL-friendly identifier.',
  permanent_number INT COMMENT 'Driver\'s permanent race number chosen by the driver (introduced in 2014, e.g. 44 for Hamilton). NULL for drivers who raced before 2014. Can differ from the car number in a specific race.',
  driver_code STRING COMMENT 'Three-letter driver abbreviation shown on timing screens (e.g. HAM, VER, LEC). Mostly NULL for historic drivers; not guaranteed unique across eras.',
  forename STRING COMMENT 'Driver\'s first name(s).',
  surname STRING COMMENT 'Driver\'s family name.',
  driver_name STRING COMMENT 'Full display name: forename + \' \' + surname (e.g. \'Lewis Hamilton\'). Use this column to filter or group by driver.',
  date_of_birth DATE COMMENT 'Driver\'s date of birth. Use for age calculations (age at debut, age at win).',
  nationality STRING COMMENT 'Driver nationality as an adjective (e.g. \'British\', \'German\', \'Dutch\'). Not the country of the race.',
  first_season INT COMMENT 'First championship season (year) in which the driver started a Grand Prix.',
  last_season INT COMMENT 'Most recent championship season in which the driver started a Grand Prix.',
  first_race_date DATE COMMENT 'Date of the driver\'s first Grand Prix start (debut).',
  last_race_date DATE COMMENT 'Date of the driver\'s most recent Grand Prix start.',
  seasons_raced BIGINT COMMENT 'Number of distinct seasons in which the driver started at least one Grand Prix.',
  age_at_debut INT COMMENT 'Driver\'s age in whole years on the date of their first Grand Prix start.',
  is_active BOOLEAN COMMENT 'TRUE if the driver has started a Grand Prix in the current (latest) season in the data.',
  world_titles BIGINT COMMENT 'Number of Drivers\' World Championships won (position 1 in the final standings of a completed season). 0 if none.',
  title_seasons STRING COMMENT 'Comma-separated list of the seasons in which the driver won the Drivers\' World Championship (e.g. \'2021, 2022, 2023, 2024\'). NULL if no titles.',
  url STRING COMMENT 'Wikipedia page of the driver.'
)
COMMENT 'Formula 1 driver master data (dimension table). Grain: one row per driver who has ever entered a World Championship Grand Prix (1950 to the current season). Key: driver_id, referenced by results, sprint_results, qualifying, lap_times, pit_stops and driver_standings. Contents: identity (name, 3-letter code, permanent car number, nationality, date of birth) plus derived career attributes (first/last season, debut age, active flag, world titles). Notes: 1950-1960 seasons included the Indianapolis 500, so many US drivers have only Indy entries. Permanent numbers exist only since 2014 and driver codes mainly for modern drivers (NULL otherwise). World titles count completed seasons only; the season in progress is excluded. Source: Kaggle dataset jtrotman/formula-1-race-data (Ergast-compatible schema), file drivers.csv; career attributes computed from results, races and driver_standings.'
AS
WITH raw AS (
  SELECT * FROM read_files('${raw_path}/drivers.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N')
),
starts AS (
  SELECT r.driver_id, ra.year, ra.race_date
  FROM results r
  JOIN races ra ON r.race_id = ra.race_id
),
career AS (
  SELECT
    driver_id,
    MIN(year) AS first_season,
    MAX(year) AS last_season,
    MIN(race_date) AS first_race_date,
    MAX(race_date) AS last_race_date,
    COUNT(DISTINCT year) AS seasons_raced
  FROM starts
  GROUP BY driver_id
),
-- A season is completed once every scheduled race of that year has results
completed_seasons AS (
  SELECT ra.year, MAX_BY(ra.race_id, ra.round) AS final_race_id
  FROM races ra
  LEFT JOIN (SELECT DISTINCT race_id FROM results) r ON ra.race_id = r.race_id
  GROUP BY ra.year
  HAVING COUNT(*) = COUNT(r.race_id)
),
titles AS (
  SELECT
    ds.driver_id,
    COUNT(*) AS world_titles,
    ARRAY_JOIN(ARRAY_SORT(COLLECT_LIST(CAST(cs.year AS STRING))), ', ') AS title_seasons
  FROM driver_standings ds
  JOIN completed_seasons cs ON ds.race_id = cs.final_race_id
  WHERE ds.position = 1
  GROUP BY ds.driver_id
)
SELECT
  CAST(raw.driverId AS INT) AS driver_id,
  raw.driverRef AS driver_ref,
  CAST(raw.number AS INT) AS permanent_number,
  raw.code AS driver_code,
  raw.forename,
  raw.surname,
  CONCAT(raw.forename, ' ', raw.surname) AS driver_name,
  CAST(raw.dob AS DATE) AS date_of_birth,
  raw.nationality,
  c.first_season,
  c.last_season,
  c.first_race_date,
  c.last_race_date,
  c.seasons_raced,
  CAST(FLOOR(MONTHS_BETWEEN(c.first_race_date, CAST(raw.dob AS DATE)) / 12) AS INT) AS age_at_debut,
  COALESCE(c.last_season = (SELECT MAX(year) FROM starts), FALSE) AS is_active,
  COALESCE(t.world_titles, 0) AS world_titles,
  t.title_seasons,
  raw.url
FROM raw
LEFT JOIN career c ON CAST(raw.driverId AS INT) = c.driver_id
LEFT JOIN titles t ON CAST(raw.driverId AS INT) = t.driver_id;
