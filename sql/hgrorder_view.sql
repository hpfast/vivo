-- View: public.hgrorder

-- DROP VIEW public.hgrorder;

CREATE OR REPLACE VIEW public.hgrorder AS 
 SELECT pgr_tsp.seq, pgr_tsp.id1, pgr_tsp.id2, round(pgr_tsp.cost::numeric, 2) AS cost
   FROM pgr_tsp('SELECT gid as id, x, y FROM hgr_subset ORDER BY gid'::text, 223) pgr_tsp(seq, id1, id2, cost);

ALTER TABLE public.hgrorder
  OWNER TO postgres;
