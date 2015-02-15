select * from drc.hz_dist_voronoi

DROP FUNCTION IF EXISTS hz_adj_2(int[], int);
CREATE FUNCTION hz_adj_2(int[],int) RETURNS SETOF int as $$
  SELECT distinct a.hz_id_2
    from drc.hz_dist_voronoi_bandundu a  
    where a.hz_id_1 = ANY ($1)
       and a.hz_id_2 != ANY ($1)
       and a.hz_id_2 != 441
       and a.dist <= 0
       and a.hz_id_2 in (select h.hz_id from drc.hospitals h where h.provname='Bandundu');
$$ LANGUAGE SQL;
 select hz_adj_2(ARRAY[369,127,134,203,288], 441);

-- testing a 2nd level adjacency, must also add source node (416 to the exclude list)
SELECT distinct a.hz_id_2
    from drc.hz_dist_voronoi_bandundu a  
    where a.hz_id_1 in (369,127,134,203,288)
       and a.hz_id_2 not in (369,127,134,203,288)
       and a.dist <= 0
       and a.hz_id_2 in (select h.hz_id from drc.hospitals h where h.provname='Bandundu');
    
select * from drc.hz_dist_voronoi where hz_id_1=441 and dist<=0.00

create view drc.hz_dist_voronoi_bandundu as
select d.*, h.provname 
   from drc.hz_dist_voronoi d, drc.hospitals h 
   where d.hz_id_1 = h.hz_id and
   h.provname='Bandundu';


select * from drc.hospitals h where h.hz_id = 416

select * from drc.hz_dist_voronoi_bandundu where hz_id_2=416


 select array( select hz_adj_2(ARRAY[369,127,134,203,288], 441))




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



http://dba.stackexchange.com/questions/61520/how-to-do-where-x-in-val1-val2-in-plpgsql