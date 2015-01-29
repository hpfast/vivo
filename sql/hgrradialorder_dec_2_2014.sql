-- View: public.hgrradialorder

-- DROP VIEW public.hgrradialorder;

CREATE OR REPLACE VIEW public.hgrradialorder AS 
 SELECT row_number() OVER () AS "order", ordering.gid, ordering.name, ordering.pointm, ordering.hz_id, ordering.degree
   FROM ( SELECT a.gid, a.name, a.pointm, a.hz_id, st_azimuth(b.point, a.point) as "degree"
           FROM drc.hosp_merc a, drc.depot b
          ORDER BY st_azimuth(b.point, a.point)) ordering;

ALTER TABLE public.hgrradialorder
  OWNER TO postgres;

select * from public.hgrradialorder