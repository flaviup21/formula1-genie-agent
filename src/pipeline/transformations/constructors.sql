CREATE OR REFRESH MATERIALIZED VIEW constructors (
  constructor_id INT COMMENT 'Primary key of the constructor (Ergast constructorId). Join key to results, qualifying, sprint_results and constructor tables.',
  constructor_ref STRING COMMENT 'Unique lowercase text key of the constructor (e.g. \'ferrari\', \'red_bull\').',
  constructor_name STRING COMMENT 'Team name (e.g. \'Ferrari\', \'McLaren\', \'Red Bull\'). Use this column to filter or group by team.',
  nationality STRING COMMENT 'Nationality of the constructor as an adjective (e.g. \'Italian\', \'British\', \'Austrian\').',
  url STRING COMMENT 'Wikipedia page of the constructor.'
)
COMMENT 'F1 constructors (teams), e.g. Ferrari, McLaren, Red Bull'
AS SELECT
  CAST(constructorId AS INT) AS constructor_id,
  constructorRef AS constructor_ref,
  name AS constructor_name,
  nationality,
  url
FROM read_files('${raw_path}/constructors.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
