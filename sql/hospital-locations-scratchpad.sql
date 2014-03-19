drop table hospitals.test_join_with_contains;

select count(*) from drc_admin.healthzones_fixed limit 10;

--join the little polygons that pprepair added.
--NOTE alters ogc_fids.
drop table drc_admin.hz;
create table drc_admin.hz as select
	min(ogc_fid) as ogc_fid, st_union(wkb_geometry) as wkb_geometry, zs, lvlid, sourceyear, lvlld, source, provname, name_api, partenaire, gavi
from drc_admin.healthzones_fixed
group by zs, lvlid, sourceyear, lvlld, source, provname, name_api, partenaire, gavi
;--518

-- add a primary key
alter table drc_admin.hz add column gid serial primary key not null;

select * from drc_admin.healthzones_fixed where ogc_fid not in (select ogc_fid from drc_admin.hz);

update drc_admin.healthzones_fixed set wkb_geometry = st_setsrid(wkb_geometry,4326);


drop table hospitals.test_join_with_contains;
create table hospitals.test_join_with_contains as select
	a.name,
	a.wkb_geometry as point,
	b.ZS as name_hz,
b.wkb_geometry as pol
from
	drc_admin.cities a,
	drc_admin.hz b
where
	a.name = b.ZS
and
	st_contains(b.wkb_geometry, a.wkb_geometry)
;--490. So only 28 missing.

--add gid
alter table hospitals.test_join_with_contains add column gid serial;


	
drop table hospitals.centroids_unmatched_healthzones;

create table hospitals.centroids_unmatched_healthzones as select
	ZS as name,
	st_centroid(wkb_geometry) as point
from
	drc_admin.hz
where
	ZS not in (select name from hospitals.test_join_with_contains)
;
--Query returned successfully: 226 rows affected, 395 ms execution time.

drop table hospitals.dedup1;
create table hospitals.dedup1 (
	gid integer,
	point geometry(point,4326),
	name text,
	certainty text
);

with preselect as (
	select
		name,
		count(name) as count
	from
		hospitals.test_join_with_contains
	group by
		name
	)
	
insert into hospitals.dedup1
select
	a.gid,
	a.point,
	a.name,
	'single match'
from
	hospitals.test_join_with_contains a,
	preselect
where
	a.name = preselect.name
and
	preselect.count = 1
;
--139



----
drop table hospitals.pairs;
with preselect as (
	select
		min(gid) as gid,
		name,
		count(gid) as count
	from
		hospitals.test_join_with_contains
	group by
		name
	)

select st_distance(
		geography(st_transform(r.point,4326)),
		geography(st_transform(j.point,4326))
		) as distance,
		r.point,
	 r.gid as rgid, j.gid as jgid, r.name
into hospitals.pairs
from
(select a.gid, a.name, a.point from hospitals.test_join_with_contains a, preselect
where a.name = preselect.name and preselect.count =2) as r,
(select a.gid, a.name, a.point from hospitals.test_join_with_contains a, preselect
where a.name = preselect.name and preselect.count =2) as j
where r.name = j.name
and r.gid <> j.gid
;
--234
alter table hospitals.pairs add column sid serial;

delete from hospitals.pairs where sid in (select max(sid) from hospitals.pairs group by name);	
--117 deleted. check.

drop table hospitals.pairs_10k;
create table hospitals.pairs_10k as select
	a.*
from

hospitals.test_join_with_contains a,
(
	select * from hospitals.pairs where distance <= 10000
) b
where
	a.gid = b.rgid
or
	a.gid = b.jgid
-- 184


insert into hospitals.dedup1
select
	a.gid,
	a.point,
	a.name,
	'pair10km'
from
	hospitals.pairs_10k a
where
	a.gid in (
		select
			min(gid)
		from
			hospitals.pairs_10k
		group by
			name
	)
;
--92 --ok, but now remember to include the PAIRS that are more than 10km apart in the next one.

select count(*) from hospitals.dedup1;

select count(gid), name
from hospitals.test_join_with_contains
group by name
order by count desc;


----
--more than 2

drop table hospitals.dist_from_centroid;

with preselect as (
	select
		min(gid) as gid,
		name,
		count(gid) as count
	from
		hospitals.test_join_with_contains
	group by
		name
	)

select st_distance(a.point,b.centroid), a.point, a.name, a.gid
into hospitals.dist_from_centroid
from hospitals.test_join_with_contains a,
(select
	st_centroid(pol) centroid,
	name
from hospitals.test_join_with_contains) as b,
preselect as c
where a.name = b.name
and a.name= c.name
and c.count > 1
and c.gid not in (select gid from hospitals.pairs_10k)
group by a.name, a.gid, a.point, b.centroid
;
--490/117/167

drop table hospitals.closest_to_centroid;
create table hospitals.closest_to_centroid as
select a.*
from hospitals.dist_from_centroid a
where st_distance in (
	select min(st_distance)
	from hospitals.dist_from_centroid
	group by name
)
and a.gid not in (
	select gid from hospitals.pairs_10k
)
--201/37/62

insert into hospitals.dedup1
select
	a.gid,
	a.point,
	a.name,
	'closest to centroid'
from
	hospitals.test_join_with_contains a
where
	a.gid in (
		select gid from hospitals.closest_to_centroid
	)
;
--201/37/62

select count(*) from hospitals.dedup1;

insert into hospitals.dedup1
select
	null,
	a.point,
	a.name,
	'centroid'
from
	hospitals.centroids_unmatched_healthzones a
;
--226

select count(*) from hospitals.dedup1; --666/502/519 GRRR!


select * from hospitals.dedup1;
select count(*) from drc_admin.hz; --518

-- the duplication is because there are some in 'closest to centroid' that are at the same point.
-- well, that's not true because if we correct for that we get 16 too few ...
-- most probably this is because of the extra polygons generated by pprepair. Let's check:

select a.* from drc_admin.healthzones_fixed a, hospitals.dedup1 b where st_disjoint(a.wkb_geometry, b.point);


create table hospitals.check_match as
select
	a.gid,
	a.wkb_geometry,
	b.point,
	a.ZS as a_name,
	b.name as b_name
from
	drc_admin.hz a,
	hospitals.dedup1 b
where
	a.ZS = b.name


with preselect as (
	select
		min(gid) as gid,
		name,
		count(gid) as count
	from
		hospitals.test_join_with_contains
	group by
		name
	)
	
insert into hospitals.dedup1
select
	preselect.gid,
	a.point,
	a.name,
	'pair10km'
from
	hospitals.test_join_with_contains a,
	preselect,
	(select
		min(r.gid) as gid
	from
		hospitals.test_join_with_contains r,
		hospitals.test_join_with_contains q
	where
		st_distance(r.point,q.point) >= 10000
	and
		r.name = q.name
	and
		r.gid in (
			select gid
			from preselect
			where count = 2
		)

	) as b
where
	a.gid = preselect.gid
and
	a.gid = b.gid
and
	preselect.count = 2
;