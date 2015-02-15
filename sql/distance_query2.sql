select * from drc.routes where sol_id=(select min(sol_id) from drc.solutions where run_id=(select max(run_id) from drc.runs)) order by month, route_order;

select * from drc.routes where sol_id=795 order by month, trip
select * from (select DISTINCT ON (month, name) * from drc.routes where sol_id=815) as foo order by month, trip
select * from drc.solutions;

select * from (select DISTINCT ON (month, name) * from drc.routes where sol_id=820) as foo order by month, trip

select * from (select DISTINCT ON (month, name) * from drc.routes where sol_id=830) as foo order by month, trip
select * from drc.routes where sol_id=830 order by month, trip

select * from hgr_subset3

SELECT hosp_merc_ordered.radorder, hosp_merc_ordered.gid, hosp_merc_ordered.name, hosp_merc_ordered.affiliation, hosp_merc_ordered.id_nearest_airport, hosp_merc_ordered.dist_nearest_airport, hosp_merc_ordered.certainty, hosp_merc_ordered.point, hosp_merc_ordered.lvlid, hosp_merc_ordered.source, hosp_merc_ordered.provname, hosp_merc_ordered.name_api, hosp_merc_ordered.partenaire, hosp_merc_ordered.gavi, hosp_merc_ordered.hz_id, hosp_merc_ordered.type, hosp_merc_ordered.pointm, hosp_merc_ordered.fakeid, hosp_merc_ordered.x, hosp_merc_ordered.y, hosp_merc_ordered.depotdist
   FROM hosp_merc_ordered
      WHERE 
        hosp_merc_ordered.provname = 'Bandundu'::text AND 
        st_distance_sphere(hosp_merc_ordered.point, st_makepoint(18.78333::double precision, (-5.033333)::double precision)) >= (100 * 1000)::double precision OR hosp_merc_ordered.hz_id = 223 
      order by depotdist

CREATE OR REPLACE VIEW public.hgr_subset3 AS 
SELECT hosp_merc_ordered.radorder, hosp_merc_ordered.gid, hosp_merc_ordered.name, hosp_merc_ordered.affiliation, hosp_merc_ordered.id_nearest_airport, hosp_merc_ordered.dist_nearest_airport, hosp_merc_ordered.certainty, hosp_merc_ordered.point, hosp_merc_ordered.lvlid, hosp_merc_ordered.source, hosp_merc_ordered.provname, hosp_merc_ordered.name_api, hosp_merc_ordered.partenaire, hosp_merc_ordered.gavi, hosp_merc_ordered.hz_id, hosp_merc_ordered.type, hosp_merc_ordered.pointm, hosp_merc_ordered.fakeid, hosp_merc_ordered.x, hosp_merc_ordered.y, hosp_merc_ordered.depotdist
   FROM hosp_merc_ordered
      WHERE 
        hosp_merc_ordered.provname = 'Bandundu'::text AND 
        st_distance_sphere(hosp_merc_ordered.point, st_makepoint(18.78333::double precision, (-5.033333)::double precision)) >= (100 * 1000)::double precision OR hosp_merc_ordered.hz_id = 223 
      order by depotdist;

ALTER TABLE public.hgr_subset3
  OWNER TO postgres;


select max(depotdist) from hgr_subset3

select min(dist) from drc.hz_dist where hz_id_1=223 and hz_id_2 in (155)

select * from drc.hz_dist order by dist desc limit 100


DROP table IF EXISTS drc.hz_dist;
create table drc.hz_dist as
   SELECT a.hz_id as hz_id_1, b.hz_id as hz_id_2, ST_Distance(a.point, b.point) as dist
       from drc.hospitals a, drc.hospitals b
       where a.hz_id!=b.hz_id
       and b.hz_id=223
       order by hz_id_2, dist;

select * from drc.hz_dist;