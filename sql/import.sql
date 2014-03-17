select count(*) from drc_admin.healthzones;


create table drc_admin.pyramide_assignation (
	aire_name text,
	zone_name text,
	territory_name text,
	province_name text
);

copy drc_admin.pyramide_assignation (
	aire_name,
	zone_name,
	territory_name,
	province_name
)

from '/home/hans/drc-data/pyramide_assignation_snis.csv'
with delimiter ','
csv header
;
--Query returned successfully: 8423 rows affected, 121 ms execution time.

select * from drc_admin.cities limit 100;
select count(*) from drc_admin.cities; --55183
select distinct(name) from drc_admin.cities; --38107
select count(name) from drc_admin.cities group by (name, province