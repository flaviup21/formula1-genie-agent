CREATE OR REFRESH MATERIALIZED VIEW circuits (
  circuit_id INT COMMENT 'Primary key of the circuit (Ergast circuitId). Join key to races.circuit_id.',
  circuit_ref STRING COMMENT 'Unique lowercase text key of the circuit (e.g. \'monza\', \'silverstone\').',
  circuit_name STRING COMMENT 'Official track name (e.g. \'Circuit de Monaco\', \'Autodromo Nazionale di Monza\').',
  city STRING COMMENT 'City or locality of the circuit (e.g. \'Monza\', \'Silverstone\', \'Melbourne\').',
  country STRING COMMENT 'Country where the circuit is located (e.g. \'Italy\', \'UK\', \'USA\').',
  latitude DOUBLE COMMENT 'Latitude of the circuit in decimal degrees.',
  longitude DOUBLE COMMENT 'Longitude of the circuit in decimal degrees.',
  altitude_m INT COMMENT 'Altitude of the circuit above sea level in metres.',
  url STRING COMMENT 'Wikipedia page of the circuit.'
)
COMMENT 'F1 circuits / race tracks'
AS SELECT
  CAST(circuitId AS INT) AS circuit_id,
  circuitRef AS circuit_ref,
  name AS circuit_name,
  location AS city,
  country,
  CAST(lat AS DOUBLE) AS latitude,
  CAST(lng AS DOUBLE) AS longitude,
  CAST(alt AS INT) AS altitude_m,
  url
FROM read_files('${raw_path}/circuits.csv', format => 'csv', header => true, inferColumnTypes => false, nullValue => '\\N');
