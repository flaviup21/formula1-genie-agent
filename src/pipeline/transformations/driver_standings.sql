CREATE OR REFRESH MATERIALIZED VIEW driver_standings (
  driver_standings_id INT COMMENT 'Primary key of the row.',
  race_id INT COMMENT 'Race after which the standings apply. Join key to races.race_id; the last round of a season gives the final standings.',
  driver_id INT COMMENT 'Driver. Join key to drivers.driver_id.',
  points DOUBLE COMMENT 'Cumulative drivers\' championship points for the season after this race.',
  position INT COMMENT 'Championship position after this race (1 = leader). Position 1 after the final round = drivers\' world champion.',
  position_text STRING COMMENT 'Championship position as text; \'D\' if the driver was disqualified from the championship.',
  wins INT COMMENT 'Cumulative race wins for the season after this race.'
)
COMMENT 'Drivers championship standings after each race (cumulative)'
AS SELECT
  CAST(driverStandingsId AS INT) AS driver_standings_id,
  CAST(raceId AS INT) AS race_id,
  CAST(driverId AS INT) AS driver_id,
  CAST(points AS DOUBLE) AS points,
  CAST(position AS INT) AS position,
  positionText AS position_text,
  CAST(wins AS INT) AS wins
FROM read_files('${raw_path}/driver_standings.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
