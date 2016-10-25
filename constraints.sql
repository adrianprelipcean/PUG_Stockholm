-- CHECK CONSTRAINTS 
alter table trips add constraint 
valid_periods check(from_time <= to_time);

alter table triplegs add constraint 
valid_periods check(from_time <= to_time);

-- NOT NULL CONSTRAINTS 
alter table trips
alter column from_time set not null;

alter table trips
alter column to_time set not null;

alter table triplegs
alter column from_time set not null;

alter table triplegs
alter column to_time set not null;

alter table triplegs
alter column trip_id set not null;

--primary key and foreign key on declaration 

-- EXCLUDE CONSTRAINTS 

ALTER TABLE trips add
constraint non_overlapping_trip_periods
EXCLUDE USING gist
   (tsrange(from_time, to_time) with && );
   
ALTER TABLE triplegs add
constraint non_overlapping_tripleg_periods
EXCLUDE USING gist
   (tsrange(from_time, to_time) with && ); 