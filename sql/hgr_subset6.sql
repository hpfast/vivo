CREATE OR REPLACE VIEW drc.hgr_subset5 AS 
 SELECT hosp_merc_ordered.radorder,
    hosp_merc_ordered.gid,
    hosp_merc_ordered.name,
    hosp_merc_ordered.affiliation,
    hosp_merc_ordered.id_nearest_airport,
    hosp_merc_ordered.dist_nearest_airport,
    hosp_merc_ordered.certainty,
    hosp_merc_ordered.point,
    hosp_merc_ordered.lvlid,
    hosp_merc_ordered.source,
    hosp_merc_ordered.provname,
    hosp_merc_ordered.name_api,
    hosp_merc_ordered.partenaire,
    hosp_merc_ordered.gavi,
    hosp_merc_ordered.hz_id,
    hosp_merc_ordered.type,
    hosp_merc_ordered.pointm,
    hosp_merc_ordered.fakeid,
    hosp_merc_ordered.x,
    hosp_merc_ordered.y,
    hosp_merc_ordered.depotdist,
    hosp_merc_ordered.rad_degree,
    st_distance_sphere(hosp_merc_ordered.point, st_makepoint(18.78333::double precision, (-5.033333)::double precision))  as distance
   FROM hosp_merc_ordered
  
  ORDER BY hosp_merc_ordered.depotdist;

create or replace view drc.hgr_subset6 as
select * from drc.hgr_subset5 where 
  (distance >= (100 * 1000)::double precision AND
  distance <= (400 * 1000)::double precision)
  OR hz_id = 223

create or replace view drc.hgr_subset6 as
select * from drc.hgr_subset5 where 
  (distance >= (100 * 1000)::double precision AND
  distance <= (700 * 1000)::double precision)
  OR hz_id = 223

select * from drc.hgr_subset6