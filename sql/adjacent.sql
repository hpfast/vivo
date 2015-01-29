-- Returns single column with hz_ids in adjacent to current hz_id
DROP FUNCTION IF EXISTS hz_adj(int);
CREATE FUNCTION hz_adj(int) RETURNS SETOF int as $$
    SELECT b.hz_id
        from drc.healthzones a, drc.healthzones b
        where a.hz_id != b.hz_id
          and a.hz_id=$1
          and ST_Distance(a.wkb_geometry, b.wkb_geometry) <= 0.001
$$LANGUAGE SQL;

-- Careful this can take a while for the entire table
select hz_id, array(select hz_adj(hz_id)) from drc.healthzones;




-- using HZ geometry
DROP FUNCTION IF EXISTS hz_adj(int, float);
CREATE FUNCTION hz_adj(int, float) RETURNS SETOF int as $$
    SELECT a.hz_id_2
       from drc.hz_dist a
       where a.hz_id_1=$1
       and a.dist <= $2
$$LANGUAGE SQL;

select hz_id, array(select hz_adj(hz_id, 0.01)) from drc.healthzones a where a.hz_id =8;

-- using voronoi of hospital location geometry
DROP FUNCTION IF EXISTS hz_adj_voronoi(int, float);
CREATE FUNCTION hz_adj_voronoi(int, float) RETURNS SETOF int as $$
SELECT a.hz_id_2
    from drc.hz_dist_voronoi a
    where a.hz_id_1=$1
      and a.dist <= $2
$$LANGUAGE SQL;


select hz_id, array(select hz_adj_voronoi(hz_id, 0.01)) as adj from drc.healthzones a where a.hz_id =8;



-- Create voronoi geom for each HGR location
-- maps the arbitrary ids from voronoi to hz_id
DROP table IF EXISTS drc.hgr_voronoi;
create table drc.hgr_voronoi as
  SELECT v.point, h.hz_id
    FROM (SELECT * FROM
      voronoi('drc.hospitals', 'point') AS (id integer, point geometry)
        WHERE id in
        (SELECT h.hz_id FROM drc.hospitals h order by h.hz_id)
     ) v INNER JOIN drc.hospitals h ON ST_Intersects(h.point, v.point);

select * from drc.hgr_voronoi

-- returns the hz_ids for adjacent hospitals according to a certain tolerance
-- tolerance of 0 means voronoi geom strictly adjacent
select hz_id, array(select hz_adj_voronoi(hz_id, 0)) as adj from drc.healthzones a where a.hz_id=410;
select hz_id, array(select hz_adj_voronoi(hz_id, 0.5)) as adj from drc.healthzones a where a.hz_id=410;


-- create table with distances between hzs (using voronoi geom) for further processing
-- careful, this can take several minutes
DROP table IF EXISTS drc.hz_dist_voronoi;
create table drc.hz_dist_voronoi as
   SELECT a.hz_id as hz_id_1, b.hz_id as hz_id_2, round(ST_Distance(a.point, b.point)::numeric,3)::float8 as dist
       from drc.hgr_voronoi a, drc.hgr_voronoi b
       where a.hz_id!=b.hz_id
       order by hz_id_2, dist;

select * from drc.hz_dist_voronoi;


-- create a handy reference for particular tolerance level
drop table if exists drc.hz_voronoi_adj;
create table drc.hz_adj_voronoi as
  select hz_id, array(select hz_adj_voronoi(hz_id, 0.5)) as adj from drc.healthzones a where a.hz_id=410;



-- I think this is the one we use as of Nov 19
-- using voronoi of hospital location geometry
DROP FUNCTION IF EXISTS hz_adj_voronoi(int, float);
CREATE FUNCTION hz_adj_voronoi(int, float) RETURNS SETOF int as $$
SELECT a.hz_id_2
    from drc.hz_dist_voronoi a
    where a.hz_id_1=$1
      and a.dist <= $2
$$LANGUAGE SQL;



-------------- final
DROP VIEW IF EXISTS drc.hz_dist_voronoi_2;
create view drc.hz_dist_voronoi_2 as
select d.*, h1.provname as prov_1, h2.provname as prov_2
   from drc.hz_dist_voronoi d, drc.hospitals h1, drc.hospitals h2
   where d.hz_id_1 = h1.hz_id and
   d.hz_id_2 = h2.hz_id;

DROP FUNCTION IF EXISTS hz_adj_2(int[], int);
CREATE FUNCTION hz_adj_2(int[],int) RETURNS SETOF int as $$
  SELECT distinct a.hz_id_2
    from drc.hz_dist_voronoi_2 a
    where a.hz_id_1 = ANY ($1)
       and NOT a.hz_id_2 = ANY ($1)
       and a.hz_id_2 != $2
       and a.dist <= 0;
       -- keeping this generic until final query step
       --and a.hz_id_2 in (select h.hz_id from drc.hospitals h where h.provname='Bandundu');
$$ LANGUAGE SQL;

select hz_adj_2(ARRAY[369,127,134,203,288], 441);

-- raw distance data
select * from drc.hz_dist_voronoi_2 where hz_id_1 = 134 and dist=0

-- adjacency data
select * from drc.hz_adj_voronoi;

ALTER TABLE drc.hz_adj_voronoi ADD COLUMN adj_2 int[];

-- run the hz_adj_2 function on each row
UPDATE drc.hz_adj_voronoi h SET adj_2 = array(select hz_adj_2(h.adj, h.hz_id));
select * from drc.hz_adj_voronoi;
select * from drc.hz_adj_voronoi where hz_id=58

