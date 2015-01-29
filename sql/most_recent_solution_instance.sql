---------------- STALE DO NOT USE??? -----------------

--DROP VIEW IF EXISTS drc.most_recent_solution_instance cascade;
--CREATE VIEW drc.most_recent_solution_instance as
--select row_number() OVER () AS "route_seq", * from (select s.month, s.trip, r.* FROM drc.most_recent_solution s
--INNER JOIN drc.routes r ON (s.route_id=r.name)
--ORDER BY minimum2(rad_degree)) t;

DROP VIEW IF EXISTS drc.most_recent_solution;
CREATE VIEW drc.most_recent_solution as
select * from drc.route_instances i where sol_id=(select min(sol_id) from drc.solutions where run_id=(select max(run_id) from drc.runs))

--select sol_id from drc.solutions where run_id=(select max(run_id) from drc.runs)

--select * from drc.route_instances
--select * from drc.routes

select maximum(rad_degree)as max, minimum(rad_degree) as min, average(rad_degree)::float as a, * from drc.most_recent_solution_instance order by min;
select maximum(rad_degree)as max, minimum(rad_degree) as min, average(rad_degree)::float as a, * from drc.most_recent_solution_instance order by min desc;


select minimum2(rad_degree)as min, (route_seq + 7) % 14 as new_order, route_seq, med, rad_order, rad_degree from drc.most_recent_solution_instance order by new_order;
select total_dist from drc.most_recent_solution_instance where route_seq=4

-- next_node references the first node in the next route (helps us construct new routes)
select *, 
  (select nodes[2] from drc.most_recent_solution_instance where route_seq=((d.route_seq)%14)+1 and nodes[2]!=223) as next_node1, 
  (select nodes[3] from drc.most_recent_solution_instance where route_seq=((d.route_seq)%14)+1 and nodes[3]!=223) as next_node2, 
  (select nodes[4] from drc.most_recent_solution_instance where route_seq=((d.route_seq)%14)+1 and nodes[4]!=223) as next_node3, 
  (select nodes[5] from drc.most_recent_solution_instance m where route_seq=((d.route_seq)%14)+1 and nodes[5]!=223) as next_node4 
  from drc.most_recent_solution_instance d order by route_seq;

select * from pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (135,261,377,223) ORDER BY hz_id', 223);
-- DIST 409?
select round(SUM(cost/1000)::numeric, 2) from pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (135,261,377,223) ORDER BY hz_id', 223);
select ARRAY(select round((cost::numeric)/1000, 2) from pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (135,261,377,223) ORDER BY hz_id', 223));
select ARRAY(select id2 from pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (135,261,377,223) ORDER BY hz_id', 223));

--- example joined
SELECT name, hz_id, point, seq, cost, rad_degree, hosp_merc_ordered.*, h.seq from
        (SELECT seq, id1, id2, round(cost::numeric, 2) AS cost FROM
        pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (223,135,261,377) ORDER BY hz_id', 223)
        ) h
        INNER JOIN hosp_merc_ordered on (h.id2 = hosp_merc_ordered.hz_id) ORDER BY h.seq


select t.*, 
(select round(SUM(cost/1000)::numeric, 2) from pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (135,261,377,223) ORDER BY hz_id', 223))
 from (select *, 
  (select nodes[2] from drc.most_recent_solution_instance m where route_seq=((d.route_seq)%14)+1 and nodes[2]!=223) as next_node1 
  from drc.most_recent_solution_instance d order by route_seq) as t

with t as (select *, 
  (select nodes[2] from drc.most_recent_solution_instance m where route_seq=((d.route_seq)%14)+1 and nodes[2]!=223) as next_node1 
  from drc.most_recent_solution_instance d order by route_seq)
select t.*,
(select round(SUM(cost/1000)::numeric, 2) from pgr_tsp('SELECT hz_id as id, x, y FROM hosp_merc_ordered WHERE hz_id IN (135,261,377,223) ORDER BY hz_id', 223)) from t

-- glue it together
select *, (SELECT * from pgr_tsp_var(q.nodes || q.next_node1))-total_dist as increase from (select *, 
  (select nodes[2] from drc.most_recent_solution_instance where route_seq=((d.route_seq)%14)+1 and nodes[2]!=223) as next_node1
  from drc.most_recent_solution_instance d order by route_seq) as q;


select version();
select setting from pg_settings where name = 'data_directory';
 