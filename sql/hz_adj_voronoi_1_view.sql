-- View: public.hz_adj_voronoi_1

-- DROP VIEW public.hz_adj_voronoi_1;

CREATE OR REPLACE VIEW public.hz_adj_voronoi_1 AS 
 SELECT a.hz_id, ARRAY( SELECT hz_adj_voronoi(a.hz_id) AS hz_adj_voronoi) AS adj
   FROM drc.healthzones a;

ALTER TABLE public.hz_adj_voronoi_1
  OWNER TO postgres;
