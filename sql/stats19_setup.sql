-- STATS19 setup for SQLite
-- Run AFTER importing the three CSVs into staging tables:
--   stg_collision, stg_vehicle, stg_casualty
-- (all columns can be text; the casts below handle the types)
--
-- Check your column names first:
--   PRAGMA table_info(stg_collision);
-- Older DfT files use accident_index / accident_year instead of
-- collision_index / collision_year. If so, find-and-replace in this file.

-- =========================================================
-- 1. CLEAN TABLES
-- =========================================================
DROP TABLE IF EXISTS casualty;
DROP TABLE IF EXISTS vehicle;
DROP TABLE IF EXISTS collision;

-- One row per collision
CREATE TABLE collision (
    collision_index          TEXT PRIMARY KEY,
    collision_year           INTEGER,
    collision_severity       INTEGER,   -- 1 fatal, 2 serious, 3 slight
    number_of_vehicles       INTEGER,
    number_of_casualties     INTEGER,
    collision_date           TEXT,      -- ISO format YYYY-MM-DD
    day_of_week              INTEGER,   -- 1 = Sunday
    collision_time           TEXT,      -- HH:MM
    collision_hour           INTEGER,
    police_force             INTEGER,
    local_authority_district INTEGER,
    local_authority_ons      TEXT,
    first_road_class         INTEGER,
    road_type                INTEGER,
    speed_limit              INTEGER,
    junction_detail          INTEGER,
    light_conditions         INTEGER,
    weather_conditions       INTEGER,
    road_surface_conditions  INTEGER,
    urban_or_rural_area      INTEGER,
    latitude                 REAL,
    longitude                REAL
);

-- One row per vehicle in a collision
CREATE TABLE vehicle (
    collision_index   TEXT NOT NULL,
    vehicle_reference INTEGER NOT NULL,
    vehicle_type      INTEGER,
    vehicle_manoeuvre INTEGER,
    sex_of_driver     INTEGER,
    age_of_driver     INTEGER,
    age_band_of_driver INTEGER,
    engine_capacity_cc INTEGER,
    age_of_vehicle    INTEGER,
    PRIMARY KEY (collision_index, vehicle_reference),
    FOREIGN KEY (collision_index) REFERENCES collision (collision_index)
);

-- One row per casualty in a collision
-- Note: vehicle_reference is 0 for casualties not in a vehicle
-- (e.g. pedestrians), so there is no foreign key to vehicle.
CREATE TABLE casualty (
    collision_index     TEXT NOT NULL,
    casualty_reference  INTEGER NOT NULL,
    vehicle_reference   INTEGER,
    casualty_class      INTEGER,   -- 1 driver, 2 passenger, 3 pedestrian
    sex_of_casualty     INTEGER,
    age_of_casualty     INTEGER,
    age_band_of_casualty INTEGER,
    casualty_severity   INTEGER,
    casualty_type       INTEGER,
    PRIMARY KEY (collision_index, casualty_reference),
    FOREIGN KEY (collision_index) REFERENCES collision (collision_index)
);

CREATE INDEX idx_vehicle_collision  ON vehicle (collision_index);
CREATE INDEX idx_casualty_collision ON casualty (collision_index);

-- =========================================================
-- 2. LOAD FROM STAGING
-- Pattern for every numeric column:
--   CAST(NULLIF(NULLIF(TRIM(col), ''), '-1') AS INTEGER)
-- Blank and -1 (the "data missing" sentinel) become NULL.
-- =========================================================
INSERT INTO collision
SELECT
    collision_index,
    CAST(NULLIF(NULLIF(TRIM(collision_year), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(collision_severity), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(number_of_vehicles), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(number_of_casualties), ''), '-1') AS INTEGER),
    -- dd/mm/yyyy -> yyyy-mm-dd (explicit UK date handling)
    substr(date, 7, 4) || '-' || substr(date, 4, 2) || '-' || substr(date, 1, 2),
    CAST(NULLIF(NULLIF(TRIM(day_of_week), ''), '-1') AS INTEGER),
    time,
    CAST(substr(time, 1, 2) AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(police_force), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(local_authority_district), ''), '-1') AS INTEGER),
    NULLIF(NULLIF(TRIM(local_authority_ons_district), ''), '-1'),
    CAST(NULLIF(NULLIF(TRIM(first_road_class), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(road_type), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(speed_limit), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(junction_detail), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(light_conditions), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(weather_conditions), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(road_surface_conditions), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(urban_or_rural_area), ''), '-1') AS INTEGER),
    CAST(NULLIF(TRIM(latitude), '') AS REAL),
    CAST(NULLIF(TRIM(longitude), '') AS REAL)
FROM stg_collision;

INSERT INTO vehicle
SELECT
    collision_index,
    CAST(vehicle_reference AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(vehicle_type), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(vehicle_manoeuvre), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(sex_of_driver), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(age_of_driver), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(age_band_of_driver), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(engine_capacity_cc), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(age_of_vehicle), ''), '-1') AS INTEGER)
FROM stg_vehicle;

INSERT INTO casualty
SELECT
    collision_index,
    CAST(casualty_reference AS INTEGER),
    CAST(NULLIF(TRIM(vehicle_reference), '') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(casualty_class), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(sex_of_casualty), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(age_of_casualty), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(age_band_of_casualty), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(casualty_severity), ''), '-1') AS INTEGER),
    CAST(NULLIF(NULLIF(TRIM(casualty_type), ''), '-1') AS INTEGER)
FROM stg_casualty;

-- =========================================================
-- 3. VALIDATION (run each, read the result, don't skip)
-- =========================================================

-- Row counts: clean tables should match staging
SELECT 'collision' AS tbl, (SELECT COUNT(*) FROM stg_collision) AS staging, (SELECT COUNT(*) FROM collision) AS clean
UNION ALL
SELECT 'vehicle',   (SELECT COUNT(*) FROM stg_vehicle),   (SELECT COUNT(*) FROM vehicle)
UNION ALL
SELECT 'casualty',  (SELECT COUNT(*) FROM stg_casualty),  (SELECT COUNT(*) FROM casualty);

-- Date range sanity check (catches a wrong date format immediately)
SELECT MIN(collision_date) AS first_date, MAX(collision_date) AS last_date FROM collision;

-- Orphans: vehicles with no matching collision
SELECT COUNT(*) AS orphan_vehicles
FROM vehicle v
LEFT JOIN collision c ON c.collision_index = v.collision_index
WHERE c.collision_index IS NULL;

-- Orphans: casualties with no matching collision
SELECT COUNT(*) AS orphan_casualties
FROM casualty ca
LEFT JOIN collision c ON c.collision_index = ca.collision_index
WHERE c.collision_index IS NULL;

-- Collisions with no vehicle rows
SELECT COUNT(*) AS collisions_without_vehicles
FROM collision c
LEFT JOIN vehicle v ON v.collision_index = c.collision_index
WHERE v.collision_index IS NULL;

-- Casualties tied to a vehicle that doesn't exist (vehicle_reference 0 = not in a vehicle, so excluded)
SELECT COUNT(*) AS casualties_with_missing_vehicle
FROM casualty ca
LEFT JOIN vehicle v
       ON v.collision_index = ca.collision_index
      AND v.vehicle_reference = ca.vehicle_reference
WHERE ca.vehicle_reference > 0
  AND v.collision_index IS NULL;

-- Fan-out check: joining collision to casualty multiplies rows.
-- Compare these three numbers and explain the differences yourself.
SELECT
    (SELECT COUNT(*) FROM collision)                          AS collisions,
    (SELECT COUNT(*) FROM collision c
        JOIN casualty ca ON ca.collision_index = c.collision_index) AS rows_after_join,
    (SELECT COUNT(DISTINCT c.collision_index) FROM collision c
        JOIN casualty ca ON ca.collision_index = c.collision_index) AS distinct_collisions_after_join;

-- NULL counts after sentinel replacement
SELECT
    SUM(speed_limit IS NULL)       AS null_speed_limit,
    SUM(road_type IS NULL)         AS null_road_type,
    SUM(light_conditions IS NULL)  AS null_light,
    SUM(weather_conditions IS NULL) AS null_weather
FROM collision;
