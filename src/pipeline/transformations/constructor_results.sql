CREATE OR REFRESH MATERIALIZED VIEW constructor_results (
  constructor_results_id INT COMMENT 'Primary key of the row.',
  race_id INT COMMENT 'Race the points were scored in. Join key to races.race_id.',
  constructor_id INT COMMENT 'Constructor (team). Join key to constructors.constructor_id.',
  points DOUBLE COMMENT 'Constructors\' championship points scored by the team in this race, under the scoring system of that season.',
  status STRING COMMENT '\'D\' if the constructor was disqualified from this race, otherwise NULL.'
)
COMMENT 'Points scored by each constructor in each race'
AS SELECT
  CAST(constructorResultsId AS INT) AS constructor_results_id,
  CAST(raceId AS INT) AS race_id,
  CAST(constructorId AS INT) AS constructor_id,
  CAST(points AS DOUBLE) AS points,
  status
FROM read_files('${raw_path}/constructor_results.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
