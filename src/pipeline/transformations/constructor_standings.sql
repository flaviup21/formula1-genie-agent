CREATE OR REFRESH MATERIALIZED VIEW constructor_standings (
  constructor_standings_id INT COMMENT 'Primary key of the row.',
  race_id INT COMMENT 'Race after which the standings apply. Join key to races.race_id; the last round of a season gives the final standings.',
  constructor_id INT COMMENT 'Constructor (team). Join key to constructors.constructor_id.',
  points DOUBLE COMMENT 'Cumulative constructors\' championship points for the season after this race.',
  position INT COMMENT 'Championship position after this race (1 = leader). Position 1 after the final round = constructors\' champion.',
  position_text STRING COMMENT 'Championship position as text; \'E\' if the constructor was excluded from the championship.',
  wins INT COMMENT 'Cumulative race wins for the season after this race.'
)
COMMENT 'Constructors championship standings after each race (cumulative)'
AS SELECT
  CAST(constructorStandingsId AS INT) AS constructor_standings_id,
  CAST(raceId AS INT) AS race_id,
  CAST(constructorId AS INT) AS constructor_id,
  CAST(points AS DOUBLE) AS points,
  CAST(position AS INT) AS position,
  positionText AS position_text,
  CAST(wins AS INT) AS wins
FROM read_files('${raw_path}/constructor_standings.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
