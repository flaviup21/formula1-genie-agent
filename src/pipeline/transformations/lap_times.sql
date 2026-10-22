CREATE OR REFRESH MATERIALIZED VIEW lap_times (
  race_id INT COMMENT 'Race. Join key to races.race_id.',
  driver_id INT COMMENT 'Driver. Join key to drivers.driver_id.',
  lap INT COMMENT 'Lap number within the race (1 = first lap).',
  position INT COMMENT 'Driver\'s running position at the end of this lap.',
  lap_time STRING COMMENT 'Lap time as text in m:ss.sss format (e.g. \'1:21.046\'). Use lap_time_ms for calculations.',
  lap_time_ms BIGINT COMMENT 'Lap time in milliseconds.'
)
COMMENT 'Lap-by-lap timing (1982+), one row per driver per lap'
AS SELECT
  CAST(raceId AS INT) AS race_id,
  CAST(driverId AS INT) AS driver_id,
  CAST(lap AS INT) AS lap,
  CAST(position AS INT) AS position,
  time AS lap_time,
  CAST(milliseconds AS BIGINT) AS lap_time_ms
FROM read_files('${raw_path}/lap_times.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
