CREATE OR REFRESH MATERIALIZED VIEW seasons (
  year INT COMMENT 'Championship season (calendar year). Primary key; join key to races.year.',
  url STRING COMMENT 'Wikipedia page of the season.'
)
COMMENT 'F1 championship seasons'
AS SELECT
  CAST(year AS INT) AS year,
  url
FROM read_files('${raw_path}/seasons.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
