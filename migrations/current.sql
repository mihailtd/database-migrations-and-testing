-- Enter migration here
DROP TABLE IF EXISTS practitioner_availability_day_of_week;

DROP TABLE IF EXISTS day_of_week;

DROP TABLE IF EXISTS slot;

DROP TABLE IF EXISTS practitioner_availability;

DROP TABLE IF EXISTS practitioner;

CREATE TABLE practitioner(
  id serial PRIMARY KEY,
  name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  planning_horizon integer NOT NULL DEFAULT 7
);

CREATE TABLE practitioner_availability(
  id serial PRIMARY KEY,
  practitioner_id integer REFERENCES practitioner(id),
  all_day boolean NOT NULL DEFAULT FALSE CHECK (all_day = TRUE OR (start_time IS NOT NULL AND end_time IS NOT NULL)),
  start_time time CHECK (start_time IS NULL OR end_time IS NULL OR start_time < end_time),
  end_time time CHECK (end_time IS NULL OR start_time IS NULL OR start_time < end_time),
  slot_size integer NOT NULL DEFAULT 60
);

COMMENT ON COLUMN practitioner_availability.slot_size IS 'The duration of each slot in minutes';

CREATE TABLE day_of_week(
  id serial PRIMARY KEY,
  name varchar(255) NOT NULL
);

INSERT INTO day_of_week(name)
  VALUES ('Monday'),
('Tuesday'),
('Wednesday'),
('Thursday'),
('Friday'),
('Saturday'),
('Sunday');

CREATE TABLE practitioner_availability_day_of_week(
  practitioner_availability_id integer REFERENCES practitioner_availability(id),
  day_of_week_id integer REFERENCES day_of_week(id),
  PRIMARY KEY (practitioner_availability_id, day_of_week_id)
);

CREATE TABLE slot(
  id serial PRIMARY KEY,
  practitioner_availability_id integer NOT NULL REFERENCES practitioner_availability(id) ON DELETE CASCADE,
  start_time timestamp NOT NULL,
  end_time timestamp NOT NULL
);

DROP FUNCTION IF EXISTS generate_appointment_slots(integer);

CREATE OR REPLACE FUNCTION generate_appointment_slots(_practitioner_id integer)
  RETURNS void
  AS $$
DECLARE
  start_date date;
  end_date date;
  planning_horizon integer;
  current_iteration_date date;
  current_day_of_week integer;
  availability practitioner_availability%ROWTYPE;
  start_time timestamp;
  end_time timestamp;
BEGIN
  start_date := CURRENT_DATE;
  current_iteration_date := start_date;
  SELECT
    p.planning_horizon INTO planning_horizon
  FROM
    practitioner p
  WHERE
    p.id = _practitioner_id;
  end_date := start_date + planning_horizon;
  WHILE current_iteration_date < end_date LOOP
    current_day_of_week := EXTRACT(ISODOW FROM current_iteration_date);
    SELECT
      *
    FROM
      practitioner_availability
      INNER JOIN practitioner_availability_day_of_week ON id = practitioner_availability_day_of_week.practitioner_availability_id
    WHERE
      practitioner_id = _practitioner_id
      AND day_of_week_id = current_day_of_week INTO availability;
    IF availability IS NOT NULL THEN
      start_time := current_iteration_date + availability.start_time;
      end_time := current_iteration_date + availability.end_time;
      WHILE start_time < end_time LOOP
        INSERT INTO slot(practitioner_availability_id, start_time, end_time)
          VALUES (availability.id, start_time, start_time + availability.slot_size * INTERVAL '1 minute');
        start_time := start_time + availability.slot_size * INTERVAL '1 minute';
      END LOOP;
    END IF;
    current_iteration_date := current_iteration_date + 1;
  END LOOP;
END;
$$
LANGUAGE plpgsql;
