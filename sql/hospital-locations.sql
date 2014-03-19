-- find locations for hospitals

--1. join on name, limiting with st_contains


	create table hospitals.test_join_with_contains as select
		a.name,
		a.wkb_geometry as point,
		b.name_api,
	b.wkb_geometry as pol
	from
		drc_admin.cities a,
		drc_admin.healthzones b
	where
		a.name = b.name_api
	and
		st_contains(b.wkb_geometry, a.wkb_geometry)
	;
	--Query returned successfully: 490 rows affected, 2415 ms execution time.
	
--2 create a point for remaining ones using centroid
	
	create table hospitals.centroids_unmatched_healthzones as select
		ZS as name,
		st_centroid(wkb_geometry) as point
	from
		drc_admin.healthzones
	where
		ZS not in (select name_api from hospitals.test_join_with_contains)
	;
	--Query returned successfully: 226 rows affected, 395 ms execution time.

--3

	
