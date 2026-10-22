CREATE OR REFRESH MATERIALIZED VIEW status (
  status_id INT COMMENT 'Primary key of the status. Join key to results.status_id and sprint_results.status_id.',
  status STRING COMMENT 'Finishing status: \'Finished\', \'+N Lap(s)\' (classified, laps behind the winner) or the retirement reason (e.g. \'Engine\', \'Collision\', \'Disqualified\').'
)
COMMENT 'Lookup of race finishing status (Finished, +1 Lap, Engine, Collision, ...)'
AS SELECT
  CAST(statusId AS INT) AS status_id,
  status
FROM read_files('${raw_path}/status.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
