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
alter table drc_admin.airports_maf add column runway_m text;
alter table drc_admin.airports_maf add column elevation text, add column heading text, add column toda text;
alter table drc_admin.airports_maf add column fuel_jeta1 text, add column fuel_avgas text;
alter table drc_admin.airports_maf add column notes text;
select descriptio from drc_admin.airports_maf;
select regexp_matches(descriptio, 'Position:\sN\s.*?sE\s(.*?),') from drc_admin.airports_maf;

select regexp_matches(descriptio, 'Position:\sN\s(.*?)\sE') from drc_admin.airports_maf;
select regexp_matches(descriptio, 'ICAO:\s([A-Z]{4})') from drc_admin.airports_maf;
select regexp_matches(descriptio, 'AVGAS: [a-z]+', 'i') from drc_admin.airports_maf;
select regexp_matches(descriptio, 'JETA1: ([a-z]+),\sAVGAS: ([a-z]+), Notes:', 'i') from drc_admin.airports_maf;
select regexp_matches(descriptio, 'TODA:  ([a-z]+)', 'i') from drc_admin.airports_maf;
select regexp_matches(descriptio, 'Elevation: .*?\(([0-9]*?) m\),', 'i') from drc_admin.airports_maf; --metres
select regexp_matches(descriptio, 'Elevation: ([0-9]*?) ft', 'i') from drc_admin.airports_maf; --feet
alter table drc_admin.airports_maf add column elevation_m integer;
alter table drc_admin.airports_maf add column elevation_f integer;


update drc_admin.airports_maf set elevation = regexp_matches(descriptio,'Elevation: ([0-9]*?) ft', 'i');
update drc_admin.airports_maf set elevation_m = regexp_replace(regexp_replace(elevation, '^{',''),'}$','')::integer
update drc_admin.airports_maf set elevation_f = regexp_replace(regexp_replace(elevation, '^{',''),'}$','')::integer

select regexp_matches(descriptio, 'Runway Heading: (.*?),', 'i') from drc_admin.airports_maf;
update drc_admin.airports_maf set heading = regexp_matches(descriptio, 'Runway Heading: (.*?),', 'i');

select regexp_matches(descriptio, 'Notes: (.*)$', 'i') from drc_admin.airports_maf;
--!!only first line of multi-line notes. This is not essential for now so we'll get the rest some other time.

update drc_admin.airports_maf set fuel_jeta1 = regexp_matches(descriptio, 'JETA1: ([a-z]+),', 'i');
update drc_admin.airports_maf set fuel_avgas = regexp_matches(descriptio, 'AVGAS: ([a-z]+)', 'i');
update drc_admin.airports_maf set toda = regexp_matches(descriptio, 'TODA:  ([a-z]+)', 'i');
update drc_admin.airports_maf set name_new = regexp_matches(descriptio, 'Name:\s(.*?),');
update drc_admin.airports_maf set latitude = regexp_matches(descriptio, 'Position:\sN\s(.*?)\sE');
update drc_admin.airports_maf set runway_m = regexp_matches(descriptio, 'Length:\s([0-9]*)');
update drc_admin.airports_maf set icao = regexp_matches(descriptio, 'ICAO:\s([A-Z]{4})');

update drc_admin.airports_maf set notes = regexp_matches(descriptio, 'Notes: (.*)$', 'i');


select * from drc_admin.airports where icao = 'FZFU';
update drc_admin.airports set icao = substring(icao from 1 for 4);
--now we want to join the unique ones. How do we know if they're unique?
select * from drc_admin.airports_maf where icao not in (select icao from drc_admin.airports); --83!
--oops, strip off those brackets ...
update drc_admin.airports_maf set icao = substring(icao from 2 for 4);
select regexp_replace(name_new, '^"','') from drc_admin.airports_maf;
update drc_admin.airports_maf set name_new = regexp_replace(name_new, '"$','') from drc_admin.airports_maf;
update drc_admin.airports_maf set latitude = regexp_replace(regexp_replace(latitude, '^{"', ''),'"}$','');
update drc_admin.airports_maf set longitude = regexp_replace(regexp_replace(longitude, '^{"', ''),'"}$','');
update drc_admin.airports_maf set runway_m = regexp_replace(regexp_replace(runway_m, '^{',''),'}$','');
update drc_admin.airports_maf set fuel_jeta1 = regexp_replace(regexp_replace(fuel_jeta1, '^{',''),'}$','');
update drc_admin.airports_maf set fuel_avgas = regexp_replace(regexp_replace(fuel_avgas, '^{',''),'}$','');
update drc_admin.airports_maf set toda = regexp_replace(regexp_replace(toda, '^{',''),'}$','');
update drc_admin.airports_maf set heading = regexp_replace(regexp_replace(heading, '^{',''),'}$','');
update drc_admin.airports_maf set notes = regexp_replace(regexp_replace(notes, '^{',''),'}$','');

--where icao = icao and name = name, set point to maf (looks like these are more accurate).
--where maf icao not in general icao, add it (looks like the general icao is more complete?)
-- where maf does not have icao, add it.

--but for now, going to leave the step of expanding the airports table. Just going to use the basic airports table for now.
--so, let's proceed to the k-nearest neighbor.

--update: now we have checked out the maf airports in more detail. We can now create a new table for airports with all the necessary columns to merge the two together
drop table drc.airports_merged;
create table drc.airports_merged (
	sid serial primary key,
	point geometry(point,4326),
	ogc_fid_airports integer,
	ogc_fid_maf integer,
	name_a text,
	icao text,
	name_maf text,
	runway_length_m integer,
	heading text,
	latitude text,
	longitude text,
	fuel_jeta1 text,
	fuel_avgas text,
	elevation_m integer,
	elevation_f integer,
	toda text,
	notes text,
	kind text
)
;


--the point of this merging is twofold: to get more exact locations of airports (from MAF dataset); and to get the airports in the MAF set but not in the other one.
--NOTE that in most cases the MAF dataset is more accurate in location; but in some cases it is drastically off.
--also there is one case where the MAF ICAO code is incorrect; and there are two airports in the MAF set which we will not copy because they are in Uganda.
truncate table drc.airports_merged;
--now insert one set at a time. First, insert everything that matches on ICAO.
insert into drc.airports_merged (point,	ogc_fid_airports, ogc_fid_maf, name_a, icao, name_maf, runway_length_m, heading, latitude, longitude, fuel_jeta1, fuel_avgas, elevation_m, elevation_f, toda, notes, kind)
select
	b.wkb_geometry as point,
	b.ogc_fid as ogc_fid_airports,
	a.ogc_fid as ogc_fid_maf,
	b.name as name_a,
	a.icao as icao,
	b.name_new as name_maf,
	b.runway_m::integer as runway_length_m,
	b.heading as heading,
	b.latitude as latitude,
	b.longitude as longitude,
	b.fuel_jeta1 as fuel_jeta1,
	b.fuel_avgas as fuel_avgas,
	b.elevation_m as elevation_m,
	b.elevation_f as elevation_f,
	b.toda as toda,
	b.notes as notes,
	a.kind as kind
	
from
	drc_admin.airports a,
	drc_admin.airports_maf b
where
	a.icao = b.icao
;--80 --81?? yes, cause we fixed the ICAO code on Shabunda.

--now, let's insert the one with the typo in the ICAO

update drc_admin.airports_maf set icao = 'FZMW' where icao = 'FZNW';

insert into drc.airports_merged (point,	ogc_fid_airports, ogc_fid_maf, name_a, icao, name_maf, runway_length_m, heading, latitude, longitude, fuel_jeta1, fuel_avgas, elevation_m, elevation_f, toda, notes, kind)
select
	b.wkb_geometry as point,
	b.ogc_fid as ogc_fid_airports,
	a.ogc_fid as ogc_fid_maf,
	b.name as name_a,
	a.icao as icao,
	b.name_new as name_maf,
	b.runway_m::integer as runway_length_m,
	b.latitude as latitude,
	b.longitude as longitude,
	b.fuel_jeta1 as fuel_jeta1,
	b.fuel_avgas as fuel_avgas,
	b.elevation_m as elevation_m,
	b.elevation_f as elevation_f,
	b.heading as heading,
	b.toda as toda,
	b.notes as notes,
	a.kind as kind
	
from
	drc_admin.airports a,
	drc_admin.airports_maf b
where

	b.icao = 'FZMW'
and
	a.icao = b.icao

;--1

--ok. Now we can insert the ones that didn't mave an icao/didn't match on icao;
--we will filter out the missing ones.
insert into drc.airports_merged (point,	ogc_fid_airports, ogc_fid_maf, name_a, icao, name_maf, runway_length_m, heading, latitude, longitude, fuel_jeta1, fuel_avgas, elevation_m, elevation_f, toda, notes, kind)
select
	b.wkb_geometry as point,
	null as ogc_fid_airports,
	b.ogc_fid as ogc_fid_maf,
	b.name as name_a,
	null as icao,
	b.name_new as name_maf,
	case
		when b.runway_m = '""' then null
		else b.runway_m::integer
	end as runway_length_m,
	b.heading as heading,
	b.latitude as latitude,
	b.longitude as longitude,
	b.fuel_jeta1 as fuel_jeta1,
	b.fuel_avgas as fuel_avgas,
	b.elevation_m as elevation_m,
	b.elevation_f as elevation_f,
	b.toda as toda,
	b.notes as notes,
	null as kind
	
from
	drc_admin.airports_maf b
where

	(b.icao is null OR b.icao = 'FZCG') --FZCG is in MAF and has an ICAO (obviously), but not in other set so didn't match earlier
and
	b.ogc_fid <> 36 --id 36 has no ICAO but is in Uganda.

; --40

--and now finally insert the ones from airports that aren't in airports_maf.

insert into drc.airports_merged (point,	ogc_fid_airports, ogc_fid_maf, name_a, icao, name_maf, runway_length_m, heading, latitude, longitude, fuel_jeta1, fuel_avgas, elevation_m, elevation_f, toda, notes, kind)
select
	a.wkb_geometry as point,
	a.ogc_fid as ogc_fid_airports,
	null as ogc_fid_maf,
	a.name as name_a,
	a.icao as icao,
	null as name_maf,
	case
		when "max runway" = '' then null
		else left("max runway", -3)::integer
	end as runway_length_m,
	null as heading,
	a.latitude as latitude,
	a.longitude as longitude,
	null as fuel_jeta1,
	null as fuel_avgas,
	null as elevation_m,
	null as elevation_f,
	null as toda,
	null as notes,
	kind as kind
	
from
	drc_admin.airports a
where

	a.icao not in (
		    select a.icao from drc_admin.airports a, drc_admin.airports_maf b where a.icao = b.icao

	)
; --183

--check:

select count(*) from drc.airports_merged; --304
select count(*) from drc_admin.airports; --263
select count(*) from drc_admin.airports_maf;--123
--81 matched, -1 (not matched) +2 (in uganda) = 82;
select 123+263-82;--304 check!

--add a unique key to use in the following join

drop table drc.airports;
alter table drc.airports_merged rename to airports;
alter table drc.airports add column sid serial primary key;
create index geo_idx_airport_points on drc.airports using gist(point);

--now we can find the nearest airport to each hospital. NOTE: following query set has been edited, first it selected into nearest_airport_without_maf but now into nearest_airport_with_maf.
--first, index the hospital points.
create index geo_idx_hospitals_point on hospitals.hospitals using gist(point);

--Now we can supposedly find the nearest neighbor for each one.
drop table hospitals.nearest_airport_with_maf;

with preselect as (
	select
		h.hz_id,
		(select a.sid from drc.airports a
			order by h.point <-> a.point limit 1
		)
	from
		hospitals.hospitals h
)
select
	i.hz_id,
	i.name as h_name,
	b.name_a a_name,
	b.sid,
	b.icao,
	round(st_distance(
		geography(st_transform(i.point,4326)),
		geography(st_transform(b.point,4326))
	)) as distance
into
	hospitals.nearest_airport_with_maf
from
	hospitals.hospitals i,
	drc.airports b,
	preselect
where
	i.hz_id = preselect.hz_id
and
	b.sid = preselect.sid
;--518

--assuming ogc_fid is good ...
update hospitals.hospitals
set
	id_nearest_airport = n.sid
from
	hospitals.nearest_airport_with_maf n
where
	hospitals.hz_id = n.hz_id
;--518

update hospitals.hospitals
set
	dist_nearest_airport = n.distance
from
	hospitals.nearest_airport_with_maf n
where

	hospitals.hz_id = n.hz_id
;--518

select * from hospitals.hospitals;
select * from hospitals.nearest_airport_with_maf;


 -- return 1 NN
SELECT l.gid, (SELECT c.city_name FROM bndry.us_cities c 
  ORDER BY l.geom <#> c.the_geom LIMIT 1)
FROM offshore_meta.load_centers l;

--and then the airpot points.
create index geo_idx_airports_one on drc_admin.airports using gist(wkb_geometry);


-- CREATE OUTPUT SCHEMA

create schema drc;

--hospitals table
drop table drc.hospitals;
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
--replaced by above process to merge airport tables.
--create table drc.air_gen as select * from drc_admin.airports;
--create index idx_air_gen_point on drc.air_gen using gist(wkb_geometry);
--create index idx_air_gen_name on drc.air_gen using btree(name);
--create index idx_air_gen_ogc_fid on drc.air_gen using btree(ogc_fid);
--alter table drc.air_gen add constraint air_gen_pkey primary key(ogc_fid);

--alter table drc.air_gen rename to airports;

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

select distinct zone_name from drc_admin.pyramide_assignation order by zone_name;
select a.name, a.hz_id from drc.healthzones a where a.name in (select distinct zone_name from drc_admin.pyramide_assignation); --454.

--let's create a table with just the matched ones.
create table drc_admin.unique_zones as select zone_name, territory_name, province_name from drc_admin.pyramide_assignation group by zone_name, territory_name, province_name;
select * from drc_admin.unique_zones order by province_name;
create table drc_admin.nonmatched_zones as
select a.name from drc.healthzones a where a.hz_id not in (select a.hz_id from drc.healthzones a where a.name in (select zone_name from drc_admin.unique_zones));
--65 healthzones are not matched in the pyramide table.' 
--we want to update the pyramide names to match the healthzones.


select * from drc_admin.nonmatched_zones order by name;
select b.zone_name, a.name from drc_admin.unique_zones b, drc_admin.nonmatched_zones a where b.zone_name similar to concat('%',a.name,'%');
select b.zone_name, a.name from drc_admin.unique_zones b, drc_admin.nonmatched_zones a where a.name similar to concat('%',b.zone_name,'%');
select zone_name from drc_admin.unique_zones where zone_name like '%Nkulu%'
select name from drc.healthzones where name like '%Nkulu%'

create table drc_admin.zs_match_on_name as select
a.*,
b.*
from drc.healthzones a, drc_admin.unique_zones b
where a.name = b.zone_name
--454



select count(distinct(territory_name)) from drc_admin.pyramide_assignation; --213
select count(distinct(province_name)) from drc_admin.pyramide_assignation; --27
select distinct(province_name) from drc_admin.pyramide_assignation; --27



select * from drc_admin.unique_zones where zone_name not in (select zone_name from drc_admin.zs_match_on_name);
select * from drc_admin.ones_not_matching;
--let's select the geometries
with preselect as (select st_collect(a.point) as point from drc.hospitals a, drc_admin.zs_match_on_name b where a.hz_id = b.hz_id)
select a.hz_id, a.name, a.wkb_geometry into drc_admin.ones_not_matching from drc.healthzones a, preselect b where st_disjoint(b.point,a.wkb_geometry) --67

--so that's a bit of a tricky one.
--Let's just make the new provinces and we'll have to be happy with that for now.
drop table drc.provinces;
create table drc.provinces as select provname, st_union(st_buffer(wkb_geometry, 0)) as wkb_geometry from drc.healthzones group by provname;
select * from drc.healthzones where not st_isvalid(wkb_geometry);
create index geo_idx_provs on drc.provinces using gist(wkb_geometry);


--continuing on, we have a table of edits and we should be able to adjust this.
--import the match table and update (a copy of!) pyramide to fix the names.
create temp table tmp_match (name_pyr text, name_hz text, id_hz integer);
copy tmp_match from '/home/hans/drc-data/mismatched_v2.csv' CSV Header;
select * from tmp_match;

drop table drc_admin.pyr_fix1;
create table drc_admin.pyr_fix1 as select * from drc_admin.pyramide_assignation;

update drc_admin.pyr_fix1 set zone_name = t.name_hz from tmp_match t where zone_name = t.name_pyr; --803??
select * from drc_admin.pyr_fix1;
select * from drc_admin.pyramide_assignation;
select distinct(zone_name) from drc_admin.pyr_fix1;

--select just the health zones:
create table drc_admin.unique_zones_2 as select zone_name, territory_name, province_name from drc_admin.pyr_fix1 group by zone_name, territory_name, province_name;


--now try the matching again
drop table drc_admin.zs_match_on_name_2;
create table drc_admin.zs_match_on_name_2 as select
a.*,
b.*
from drc.healthzones a, drc_admin.unique_zones_2 b
where a.name = b.zone_name --8360 rows ... hm.
--502. any better? Yes, last time was 454.

--now we can correct the few remaining ones manually.

insert into drc_admin.unique_zones_2 (zone_name, province_name)
VALUES (
	'Kamango',
	'Nord-Kivu'
	)
;

insert into drc_admin.unique_zones_2 (zone_name, province_name) VALUES
	('Kalunguta','Nord-Kivu'),
	('Mabalako','Nord-Kivu'),
	('Alimbongo','Nord-Kivu'),
	('Bambo','Nord-Kivu'),
	('Rutshuru','Nord-Kivu'),
	('Nyiragongo','Nord-Kivu'),
	('Katoyi','Nord-Kivu'),
	('Kibwa','Nord-Kivu'),
	('Bili-EQ','Nord-Ubang'),
	('Bokonzi','Equateu')
;

update drc_admin.unique_zones_2
set zone_name = 'Lufungula' where zone_name = 'Police'
;
update drc_admin.unique_zones_2
set zone_name = 'Bijombo' where zone_name = 'Haut-Plateau'
;
update drc_admin.unique_zones_2
set zone_name = 'Kamina Base' where zone_name = 'Baka'
;

--ok, match again ...
drop table drc_admin.zs_match_on_name_2;
create table drc_admin.zs_match_on_name_2 as select
a.*,
b.*
from drc.healthzones a, drc_admin.unique_zones_2 b
where a.name = b.zone_name --516. almost there ...

--last two:
insert into drc_admin.unique_zones_2 (zone_name, province_name)
VALUES (
	'Nzanza',
	'Kongo Central'
	)
;

insert into drc_admin.unique_zones_2 (zone_name, province_name)
VALUES (
	'Bili-PO',
	'Bas-Uel'
	)
;

--try matching again:
--ok, match again ...
drop table drc_admin.zs_match_on_name_2;
create table drc_admin.zs_match_on_name_2 as select
a.*,
b.*
from drc.healthzones a, drc_admin.unique_zones_2 b
where a.name = b.zone_name --518. Let's check visually:

--very good, except I forgot to change those two incorrect matches:
update drc_admin.zs_match_on_name_2
set province_name = 'Tshop' where zone_name = 'Kabondo';
update drc_admin.zs_match_on_name_2
set province_name = 'Tshop' where zone_name = 'Lubunga-Kisangani';

--change this border case based on the map I found on the internet
update drc_admin.zs_match_on_name_2
set province_name = 'Sud-Ubang' where zone_name = 'Bokonzi';

--now that should be complete --- we can add a column to the healthzones,
--and create another province table.

alter table drc.healthzones add column provnew text;
update drc.healthzones b set provnew = a.province_name
from drc_admin.zs_match_on_name_2 a
where b.hz_id = a.hz_id; --518

--rename the other province column consistently
alter table drc.healthzones rename column provname to provold;

--create a new table with the new province boundaries
drop table drc.provinces_new;
create table drc.provinces_new as select provnew, st_union(st_buffer(wkb_geometry, 0)) as wkb_geometry from drc.healthzones group by provnew; --26
select * from drc.healthzones where not st_isvalid(wkb_geometry);
create index geo_idx_provs_new on drc.provinces_new using gist(wkb_geometry);
--rename the other province table too
alter table drc.provinces rename to provinces_old;

--roads!
create table drc.roads as select * from drc_admin.drc_roads;
update drc.roads set wkb_geometry = st_setsrid(wkb_geometry,4326);