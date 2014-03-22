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