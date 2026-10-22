CREATE OR REFRESH MATERIALIZED VIEW pit_stops (
  race_id INT COMMENT 'Race. Join key to races.race_id.',
  driver_id INT COMMENT 'Driver. Join key to drivers.driver_id.',
  stop_number INT COMMENT 'Sequence number of the stop for this driver in this race (1 = first stop).',
  lap INT COMMENT 'Lap on which the driver entered the pits.',
  time_of_day STRING COMMENT 'Local time of day of the stop (hh:mm:ss).',
  duration STRING COMMENT 'Time spent in the pit lane as text, in seconds (e.g. \'22.354\'); longer stops can be in m:ss.sss. Use duration_ms for calculations.',
  duration_ms BIGINT COMMENT 'Time spent in the pit lane in milliseconds (pit entry to pit exit, not stationary time).'
)
COMMENT 'Pit stops (1994+), one row per stop'
AS SELECT
  CAST(raceId AS INT) AS race_id,
  CAST(driverId AS INT) AS driver_id,
  CAST(stop AS INT) AS stop_number,
  CAST(lap AS INT) AS lap,
  time AS time_of_day,
  duration,
  CAST(milliseconds AS BIGINT) AS duration_ms
FROM read_files('${raw_path}/pit_stops.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
