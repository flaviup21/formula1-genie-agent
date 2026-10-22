CREATE OR REFRESH MATERIALIZED VIEW races (
  race_id INT COMMENT 'Primary key of the Grand Prix (Ergast raceId). Join key to results, qualifying, lap_times, pit_stops, sprint_results and standings.',
  year INT COMMENT 'Championship season (calendar year), 1950 to the current season.',
  round INT COMMENT 'Round number within the season (1 = season opener). The highest round of a season is the final race.',
  circuit_id INT COMMENT 'Circuit the race was held at. Join key to circuits.circuit_id.',
  race_name STRING COMMENT 'Grand Prix name (e.g. \'Monaco Grand Prix\'). Recurs every season; combine with year to identify a single race.',
  race_date DATE COMMENT 'Date of the Grand Prix.',
  race_start_time_utc STRING COMMENT 'Scheduled race start time in UTC (hh:mm:ss). NULL for most historic races.',
  url STRING COMMENT 'Wikipedia page of the race.',
  fp1_date DATE COMMENT 'Date of free practice 1. NULL for older seasons.',
  fp2_date DATE COMMENT 'Date of free practice 2. NULL for older seasons and some sprint weekends.',
  fp3_date DATE COMMENT 'Date of free practice 3. NULL for older seasons and sprint weekends.',
  quali_date DATE COMMENT 'Date of qualifying. NULL for older seasons.',
  sprint_date DATE COMMENT 'Date of the sprint race. NULL unless the weekend had a sprint (2021+).'
)
COMMENT 'F1 Grand Prix races, one row per race (year + round)'
AS SELECT
  CAST(raceId AS INT) AS race_id,
  CAST(year AS INT) AS year,
  CAST(round AS INT) AS round,
  CAST(circuitId AS INT) AS circuit_id,
  name AS race_name,
  CAST(date AS DATE) AS race_date,
  time AS race_start_time_utc,
  url,
  CAST(fp1_date AS DATE) AS fp1_date,
  CAST(fp2_date AS DATE) AS fp2_date,
  CAST(fp3_date AS DATE) AS fp3_date,
  CAST(quali_date AS DATE) AS quali_date,
  CAST(sprint_date AS DATE) AS sprint_date
FROM read_files('${raw_path}/races.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
