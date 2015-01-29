drop table if exists drc.hosp_dist;
create table drc.hosp_dist as
SELECT 
    h1.hz_id as hz_id1,
    h2.hz_id as hz_id2,
    round(st_distance_sphere(h1.point, h2.point)::numeric,2)::float as dist
FROM
    drc.hospitals as h1,
    drc.hospitals as h2
WHERE 
    h1.hz_id != h2.hz_id;

select * from drc.hosp_dist where hz_id1=223
