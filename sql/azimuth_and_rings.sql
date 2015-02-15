--creating new geometry columns in different reference system
--3857 = global mercator, metres
--4326 = latitude/longitude

create table drc.hosp_merc as select * from drc.hospitals;
alter table drc.hosp_merc add column point2 geometry(point,3857);
update drc.hosp_merc set point2 = st_transform(point,3857);
select distinct(st_srid(point2)) from drc.hosp_merc;
alter table drc.hosp_merc rename column point2 to pointm;
select st_astext(pointm) from drc.hosp_merc limit 1;

select * from drc.depot;

create table drc.depot as select * from drc.cities where name = 'Kikwit' limit 1;

alter table drc.depot add column point geometry(point,3857);
update drc.depot set point = st_transform(wkb_geometry,3857);

select * from drc.hosp_merc limit 1;

--select ordered by azimuth
select row_number() over() as order, name, pointm from (select a.gid, a.name, a.pointm from drc.hosp_merc a, drc.depot b order by st_azimuth(b.point,a.pointm)) as ordering;

alter table drc.hosp_merc add column fakeid serial;



drop table drc.bandundu_buffer_1 
create table drc.bandundu_buffer_1 as
select
	st_buffer(wkb_geometry,-0.001) as geom_latlon
from
	drc.provinces_old
where provname = 'Bandundu'

--creating x and y columns
select * from drc.hosp_merc
alter table drc.hosp_merc add column x integer;
update drc.hosp_merc set x = st_x(pointm);
alter table drc.hosp_merc add column y integer;
update drc.hosp_merc set y = st_y(pointm);







--------------
create table drc.hosp_merc2 as select * from drc.active_hospitals;
alter table drc.hosp_merc2 add column point2 geometry(point,3857);

ST_Transform(geometry,target_CRS) 

update drc.hosp_merc2 set point2 = ST_transform(point,3857);
select distinct(st_srid(point2)) from drc.hosp_merc2;
alter table drc.hosp_merc2 rename column point2 to pointm;
select st_astext(pointm) from drc.hosp_merc2 limit 1;




