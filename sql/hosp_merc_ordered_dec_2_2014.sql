-- View: public.hosp_merc_ordered

-- DROP VIEW public.hosp_merc_ordered;

CREATE OR REPLACE VIEW public.hosp_merc_ordered AS 
 SELECT o."order" AS radorder, h.gid, h.name, h.affiliation, h.id_nearest_airport, h.dist_nearest_airport, h.certainty, h.point, h.lvlid, h.source, h.provname, h.name_api, h.partenaire, h.gavi, h.hz_id, h.type, h.pointm, h.fakeid, h.x, h.y, h.depotdist, o.degree as rad_degree
   FROM hgrradialorder o
   JOIN drc.hosp_merc h ON o.gid = h.gid;

ALTER TABLE public.hosp_merc_ordered
  OWNER TO postgres;

select * from public.hosp_merc_ordered where provname='Bandundu'

