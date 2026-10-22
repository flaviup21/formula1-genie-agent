CREATE OR REFRESH MATERIALIZED VIEW qualifying (
  qualify_id INT COMMENT 'Primary key of the row.',
  race_id INT COMMENT 'Race. Join key to races.race_id.',
  driver_id INT COMMENT 'Driver. Join key to drivers.driver_id.',
  constructor_id INT COMMENT 'Constructor the driver qualified for. Join key to constructors.constructor_id.',
  car_number INT COMMENT 'Car number used in this race weekend.',
  qualifying_position INT COMMENT 'Final qualifying classification (1 = pole position). Can differ from the starting grid because of penalties; see results.grid_position.',
  q1 STRING COMMENT 'Best lap time in Q1 as text (m:ss.sss). For seasons before the knockout format (2006) this holds the single qualifying time.',
  q2 STRING COMMENT 'Best lap time in Q2 as text (m:ss.sss). NULL if the driver was eliminated in Q1 or the format had no Q2.',
  q3 STRING COMMENT 'Best lap time in Q3 as text (m:ss.sss). NULL if the driver was eliminated before Q3 or the format had no Q3.'
)
COMMENT 'Qualifying results (1994+), one row per driver per race'
AS SELECT
  CAST(qualifyId AS INT) AS qualify_id,
  CAST(raceId AS INT) AS race_id,
  CAST(driverId AS INT) AS driver_id,
  CAST(constructorId AS INT) AS constructor_id,
  CAST(number AS INT) AS car_number,
  CAST(position AS INT) AS qualifying_position,
  q1,
  q2,
  q3
FROM read_files('${raw_path}/qualifying.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
