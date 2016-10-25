CREATE OR REPLACE FUNCTION trip_period_integrity()
  RETURNS trigger AS
$BODY$
    BEGIN 
	-- UPDATE NEXT PERIOD
	IF (OLD.to_time <> NEW.to_time) THEN
	UPDATE trips SET from_time = NEW.to_time
		WHERE id = (SELECT id FROM trips WHERE from_time>=OLD.to_time AND id <> NEW.id ORDER BY from_time ASC LIMIT 1);  
	END IF;  
	-- UPDATE PREVIOUS PERIOD 
	IF (OLD.from_time <> NEW.from_time) THEN 
	UPDATE trips SET to_time = NEW.from_time
		WHERE id = (SELECT id FROM trips WHERE to_time<=OLD.from_time AND id <> NEW.id ORDER BY to_time DESC, from_time DESC LIMIT 1);  
	END IF; 
    RETURN NEW;  
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION tripleg_location_validity()
  RETURNS TRIGGER AS
$BODY$
DECLARE 
locations_within_new_period int;
    BEGIN
    locations_within_new_period := count(id_) FROM locations WHERE time_ BETWEEN NEW.from_time AND NEW.to_time;

    -- NEED AT LEAST 2 POINTS TO FORM A LINE
    IF locations_within_new_period < 2 THEN
    RAISE EXCEPTION 'proposed period modification of tripleg % does not contain enough locations', NEW.id;
    END IF;
    
    RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tripleg_period_integrity()
  RETURNS TRIGGER AS
$BODY$
    BEGIN 
    
    IF NEW.to_time<>OLD.to_time THEN 
	-- update the period of last tripleg
        UPDATE triplegs SET to_time = NEW.to_time WHERE id = (SELECT id FROM triplegs WHERE trip_id = NEW.id ORDER BY from_time DESC, to_time DESC LIMIT 1);
    END IF;

    IF (NEW.from_time <> OLD.from_time) then
        -- update previous period 
        UPDATE triplegs SET from_time = NEW.from_time WHERE id = (SELECT id FROM triplegs WHERE trip_id= NEW.id ORDER BY from_time, to_time LIMIT 1);  
    END IF;
    
    RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql; 

-- DROP TRIGGER trip_induced_tripleg_period_integrity_check ON trips
CREATE TRIGGER trip_induced_tripleg_period_integrity_check
  AFTER UPDATE
  ON trips
  FOR EACH ROW
  WHEN (((old.from_time <> new.from_time) OR (old.to_time <> new.to_time)))
  EXECUTE PROCEDURE tripleg_period_integrity();

-- DROP TRIGGER trip_period_integrity ON trips
CREATE TRIGGER trip_period_integrity
AFTER UPDATE
  ON trips
  FOR EACH ROW
  WHEN (old.to_time <> new.to_time or new.from_time <> old.from_time)
  EXECUTE PROCEDURE trip_period_integrity();

-- DROP TRIGGER tripleg_modified_location_check ON triplegs
CREATE TRIGGER tripleg_modified_location_check
  AFTER UPDATE
  ON triplegs
  FOR EACH ROW
  WHEN (((old.from_time <> new.from_time) OR (old.to_time <> new.to_time)))
  EXECUTE PROCEDURE tripleg_location_validity();