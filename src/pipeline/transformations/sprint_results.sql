CREATE OR REFRESH MATERIALIZED VIEW sprint_results (
  result_id INT COMMENT 'Primary key of the sprint result row.',
  race_id INT COMMENT 'Grand Prix weekend the sprint belonged to. Join key to races.race_id.',
  driver_id INT COMMENT 'Driver. Join key to drivers.driver_id.',
  constructor_id INT COMMENT 'Constructor the driver raced for. Join key to constructors.constructor_id.',
  car_number INT COMMENT 'Car number used in the sprint.',
  grid_position INT COMMENT 'Starting grid position for the sprint (1 = first). 0 means a pit lane start.',
  finish_position INT COMMENT 'Sprint finishing position. NULL if the driver was not classified.',
  position_text STRING COMMENT 'Finishing position as text: a number, or R = retired, D = disqualified, N = not classified, W = withdrawn.',
  position_order INT COMMENT 'Ordering of all entrants in the sprint result (1..N) including non-finishers.',
  points DOUBLE COMMENT 'Championship points scored in the sprint. Not included in the Grand Prix points in results.',
  laps_completed INT COMMENT 'Number of sprint laps completed.',
  race_time STRING COMMENT 'Sprint time of the winner or gap to the winner for other classified finishers.',
  race_time_ms BIGINT COMMENT 'Total sprint time in milliseconds. NULL for lapped drivers or non-finishers.',
  fastest_lap_number INT COMMENT 'Lap on which the driver set their fastest sprint lap.',
  fastest_lap_time STRING COMMENT 'Driver\'s fastest sprint lap time as text (m:ss.sss).',
  status_id INT COMMENT 'Finishing status. Join key to status.status_id.'
)
COMMENT 'Sprint race results (2021+), one row per driver per sprint'
AS SELECT
  CAST(resultId AS INT) AS result_id,
  CAST(raceId AS INT) AS race_id,
  CAST(driverId AS INT) AS driver_id,
  CAST(constructorId AS INT) AS constructor_id,
  CAST(number AS INT) AS car_number,
  CAST(grid AS INT) AS grid_position,
  CAST(position AS INT) AS finish_position,
  positionText AS position_text,
  CAST(positionOrder AS INT) AS position_order,
  CAST(points AS DOUBLE) AS points,
  CAST(laps AS INT) AS laps_completed,
  time AS race_time,
  CAST(milliseconds AS BIGINT) AS race_time_ms,
  CAST(fastestLap AS INT) AS fastest_lap_number,
  fastestLapTime AS fastest_lap_time,
  CAST(statusId AS INT) AS status_id
FROM read_files('${raw_path}/sprint_results.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
