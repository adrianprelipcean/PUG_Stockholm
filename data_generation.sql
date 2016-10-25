CREATE TABLE IF NOT EXISTS locations 
(
id_ serial primary key, 
latitude_ double precision, 
longitude_ double precision,
time_ timestamp without time zone
);

	WITH gen_data AS(
		SELECT row_number() OVER (), generate_series AS time_ 
		FROM generate_series('2016-10-25 12:00:00'::timestamp without time zone, 
				     '2016-10-25 16:00:00' ::timestamp without time zone, 
				     '30 minutes')
		)

	INSERT INTO locations(latitude_, longitude_, time_)
	SELECT  random() * 180 - 90 AS latitude_, random() * 360 - 180 AS longitude_ , 
		CASE WHEN row_number % 2 = 0 
		THEN 
			generate_series(time_+ '1 minute', lead(time_) OVER time_window, '1 minute')
		ELSE 
			generate_series(time_, lead(time_) OVER time_window, '15 minutes') 
		END AS time_
	FROM gen_data 
	WINDOW time_window AS (ORDER BY time_);

-- TRIPS

CREATE TABLE IF NOT EXISTS trips
(id serial primary key, 
from_time timestamp without time zone,
to_time timestamp without time zone);

INSERT INTO trips (from_time, to_time) 
VALUES ('2016-10-25 12:00:00','2016-10-25 13:00:00'),
('2016-10-25 13:00:00','2016-10-25 14:00:00'),
('2016-10-25 14:00:00','2016-10-25 15:00:00'),
('2016-10-25 15:00:00','2016-10-25 16:00:00');

-- TRIPLEGS 

CREATE TABLE IF NOT EXISTS triplegs
(id serial primary key, 
trip_id integer REFERENCES trips(id),
from_time timestamp without time zone,
to_time timestamp without time zone);

INSERT INTO triplegs (trip_id, from_time, to_time) 
SELECT id, from_time, to_time FROM (
	SELECT id, time_ AS from_time, lead(time_) OVER (PARTITION BY ID ORDER BY time_) AS to_time FROM 
		(SELECT id, generate_series(from_time, to_time, '15 minutes') AS time_ FROM trips) as series_from_trips
		) AS triplegs_ 
	WHERE to_time IS NOT NULL;
 