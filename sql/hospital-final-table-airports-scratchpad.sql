create table hospitals.hospitals (
	gid serial primary key,
	hzid integer,
	name text,
	affiliation text,
	id_nearest_airport integer,
	dist_nearest_airport integer,
	certainty text,
	point geometry(point,4326),
	lvlid text,
	source text,
	provname text,
	name_api text,
	partenaire text,
	gavi text
)

alter table hospitals.hospitals rename column hz_gid to gid;

insert into hospitals.hospitals(
	name,
	certainty,
	point,
	lvlid,
	source,
	provname,
	name_api,
	partenaire,
	gavi
)
select
	a.name,
	a.certainty,
	a.point,
	b.lvlid,
	b.source,
	b.provname,
	b.name_api,
	b.partenaire,
	b.gavi
from
	hospitals.dedup1 a,
	drc_admin.hz b
where
	a.name = b.zs
;
--519

select * from hospitals.hospitals limit 10;
select count(name), name from hospitals.hospitals group by name order by count desc;

select * from hospitals.hospitals where name = 'Kabinda';
delete from hospitals.hospitals where gid = 147;

alter table hospitals.hospitals drop column hzid;
alter table hospitals.hospitals add column hz_id serial unique not null;
alter table drc_admin.hz add column hz_id serial;
update drc_admin.hz set hz_id = a.hz_id from hospitals.hospitals a where hz.zs = a.name;
alter table drc_admin.hz add constraint hz_hz_id_unique_key unique (hz_id);

--index geometries in preparation for airports
--don't forget to import other airports from maf?

--import maf airports into their own table
--modify the maf table to be able to compare with the other airports table.
--extract the fields from description into their own columns.
select * from drc_admin.airports_maf limit 10;
select descriptio from drc_admin.airports_maf;
select count(*) from drc_admin.airports_maf;
drop table drc_admin.airports_maf;

"Airstrip: BUMBA GPS: ICAO: FZFU, Name: BUMBA, Country: DR Congo, Position: N 02 10.96 E 022 28.90, Elevation: 1201 ft (366 m), Runway Heading: 12-30, Length: 1600 m, TODA:  m, Fuel Available JETA1: False, AVGAS: False, Notes: Tower and Cranes to the west"


select * from drc_admin.airports limit 10;
--now that we've imported one without linebreaks, let's do some regex matches to get the right table structures.
alter table drc_admin.airports_maf add column icao text, add column name_new text, add column "max runway" text, add column latitude text, add column longitude text;
alter table drc_admin.airports_maf add column runway_m text,
select descriptio from drc_admin.airports_maf;
select regexp_matches(descriptio, 'Position:\sN\s.*?sE\s(.*?),') from drc_admin.airports_maf;

select regexp_matches(descriptio, 'Position:\sN\s(.*?)\sE') from drc_admin.airports_maf;
select regexp_matches(descriptio, 'ICAO:\s([A-Z]{4})') from drc_admin.airports_maf;


update drc_admin.airports_maf set name_new = regexp_matches(descriptio, 'Name:\s(.*?),');
update drc_admin.airports_maf set latitude = regexp_matches(descriptio, 'Position:\sN\s(.*?)\sE');
update drc_admin.airports_maf set runway_m = regexp_matches(descriptio, 'Length:\s([0-9]*)');

update drc_admin.airports_maf set icao = regexp_matches(descriptio, 'ICAO:\s([A-Z]{4})');

select * from drc_admin.airports limit 1;
update drc_admin.airports set icao = substring(icao from 1 for 4);
--now we want to join the unique ones. How do we know if they're unique?
select * from drc_admin.airports_maf where icao not in (select icao from drc_admin.airports); --83!
--oops, strip off those brackets ...
update drc_admin.airports_maf set icao = substring(icao from 2 for 4);
select regexp_replace(name_new, '^"','') from drc_admin.airports_maf;
update drc_admin.airports_maf set name_new = regexp_replace(name_new, '"$','') from drc_admin.airports_maf;

--where icao = icao and name = name, set point to maf (looks like these are more accurate).
--where maf icao not in general icao, add it (looks like the general icao is more complete?)
-- where maf does not have icao, add it.

--but for now, going to leave the step of expanding the airports table. Just going to use the basic airports table for now.
--so, let's proceed to the k-nearest neighbor.

--first, index the hospital points.
create index geo_idx_hospitals_point on hospitals.hospitals using gist(point);

Now we can supposedly find the nearest neighbor for each one.

with preselect as (
	select
		h.hz_id,
		(select a.ogc_fid from drc_admin.airports a
			order by h.point <-> a.wkb_geometry limit 1
		)
	from
		hospitals.hospitals h
)
select
	i.hz_id,
	i.name as h_name,
	b.name a_name,
	b.ogc_fid,
	b.icao,
	round(st_distance(
		geography(st_transform(i.point,4326)),
		geography(st_transform(b.wkb_geometry,4326))
	)) as distance
into
	hospitals.nearest_airport_without_maf
from
	hospitals.hospitals i,
	drc_admin.airports b,
	preselect
where
	i.hz_id = preselect.hz_id
and
	b.ogc_fid = preselect.ogc_fid
;--518

--assuming ogc_fid is good ...
update hospitals.hospitals
set
	id_nearest_airport = n.ogc_fid
from
	hospitals.nearest_airport_without_maf n
where
	hospitals.hz_id = n.hz_id
;--518

update hospitals.hospitals
set
	dist_nearest_airport = n.distance
from
	hospitals.nearest_airport_without_maf n
where

	hospitals.hz_id = n.hz_id
;--518

select * from hospitals.hospitals;
select * from hospitals.nearest_airport_without_maf;


 -- return 1 NN
SELECT l.gid, (SELECT c.city_name FROM bndry.us_cities c 
  ORDER BY l.geom <#> c.the_geom LIMIT 1)
FROM offshore_meta.load_centers l;

--and then the airpot points.
create index geo_idx_airports_one on drc_admin.airports using gist(wkb_geometry);


-- CREATE OUTPUT SCHEMA

create schema drc;

--hospitals table
create table drc.hospitals as select * from hospitals.hospitals;
create index idx_hospitals_drc_point on drc.hospitals using gist(point);
alter table drc.hospitals add constraint hospitals_pkey primary key(gid);
alter table drc.hospitals add constraint hospitals_hz_id_key unique(hz_id);
alter table drc.hospitals add column type text;

--cities
create table drc.cities as select * from drc_admin.cities;
alter table drc.cities add constraint cities_pkey primary key(ogc_fid);
create index idx_cities_drc_point on drc.cities using gist(wkb_geometry);
create index idx_cities_ogc_fid on drc.cities using btree(ogc_fid);
create index idx_cities_name on drc.cities using btree(name);

--this table is actually all names, rename for now and make views for actual populated places ...
alter table drc.cities rename to placenames;

--large cities
create or replace view drc.larger_cities as
	select * from drc.placenames
	where population <> '0'
	and "feature cl" = 'P'
;

--all cities as a view for now...
create or replace view drc.cities as
	select * from drc.placenames
	where "feature cl" = 'P'
;

--airports
create table drc.air_gen as select * from drc_admin.airports;
create index idx_air_gen_point on drc.air_gen using gist(wkb_geometry);
create index idx_air_gen_name on drc.air_gen using btree(name);
create index idx_air_gen_ogc_fid on drc.air_gen using btree(ogc_fid);
alter table drc.air_gen add constraint air_gen_pkey primary key(ogc_fid);

alter table drc.air_gen rename to airports;

--healthzones -- cleaned up geometry
create table drc.healthzones as select * from drc_admin.hz;
alter table drc.healthzones add constraint hz_id_key unique(hz_id);
alter table drc.healthzones add constraint hz_pkey primary key(gid);
create index idx_hz_hz_id on drc.healthzones using btree(hz_id);
create index idx_hz_geom on drc.healthzones using gist(wkb_geometry);
cluster idx_hz_geom on drc.healthzones;
alter table drc.healthzones rename column zs to name;
create index idx_hz_name on drc.healthzones using btree(name);

select * from drc.hospitals limit 10;

select distinct certainty from drc.hospitals;

select h.* from drc.hospitals h, drc.healthzones z
where st_contains(z.wkb_geometry, h.point)
and z.provname='Bandundu';

--pyramide

select * from drc_admin.pyramide_assignation;
select trim(trailing  ' Zs' from zone_name) from drc_admin.pyramide_assignation;
update drc_admin.pyramide_assignation set zone_name = trim(trailing  ' Zs' from zone_name);
update drc_admin.pyramide_assignation set aire_name = trim(trailing  ' As' from aire_name);
update drc_admin.pyramide_assignation set territory_name = trim(trailing  ' Tr' from territory_name);
update drc_admin.pyramide_assignation set province_name = trim(trailing  ' Province' from province_name);