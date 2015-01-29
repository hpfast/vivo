-- View: public.hgr_subset3

-- DROP VIEW public.hgr_subset3;

CREATE OR REPLACE VIEW public.hgr_subset3 AS 
 SELECT hosp_merc_ordered.radorder, hosp_merc_ordered.gid, hosp_merc_ordered.name, hosp_merc_ordered.affiliation, hosp_merc_ordered.id_nearest_airport, hosp_merc_ordered.dist_nearest_airport, hosp_merc_ordered.certainty, hosp_merc_ordered.point, hosp_merc_ordered.lvlid, hosp_merc_ordered.source, hosp_merc_ordered.provname, hosp_merc_ordered.name_api, hosp_merc_ordered.partenaire, hosp_merc_ordered.gavi, hosp_merc_ordered.hz_id, hosp_merc_ordered.type, hosp_merc_ordered.pointm, hosp_merc_ordered.fakeid, hosp_merc_ordered.x, hosp_merc_ordered.y, hosp_merc_ordered.depotdist, hosp_merc_ordered.rad_degree
   FROM hosp_merc_ordered
  WHERE hosp_merc_ordered.provname = 'Bandundu'::text AND st_distance_sphere(hosp_merc_ordered.point, st_makepoint(18.78333::double precision, (-5.033333)::double precision)) >= (100 * 1000)::double precision OR hosp_merc_ordered.hz_id = 223
  ORDER BY hosp_merc_ordered.depotdist;

ALTER TABLE public.hgr_subset3
  OWNER TO postgres;
