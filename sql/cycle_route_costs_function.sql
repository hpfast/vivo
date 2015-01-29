-- look back to the three nodes connecting and calculate increase in price of connecting with previous nodes
-- node cost of returning to depot in a small plane is about half the cost/km but we need to multiply x2 (return) so it works out to be about the distance from depot to node (eg dist_depot_node1..)
-- if diff_nodex is negative, then chartering a small plane is less expensive. 
-- if diff_nodex is postive and large, then we're making good use of piggy-backing
-- incr_x is the extra cost added to the original med route in order to reach the node x from the previous route.

drop function if exists cycle_route_costs_recent_solution(integer);
drop function if exists cycle_route_costs(integer, integer);
drop function if exists cycle_route_costs_rev(integer, integer);

DROP TYPE IF EXISTS temp_type;
CREATE TYPE temp_type AS (
f1 bigint,
f2 bigint,
f3 bigint,
f4 bigint,
month int,
trip int,
route_id bigint,
sol_id bigint,
name text,
nodes int[],
med int[],
dist int[],
rad_order int[],
rad_degree float[],
pickup int,
dropoff int,
total_dist int,
depot int,
prev_med int[],
incr_0 float,
incr_1 float,
incr_2 float,
incr_3 float,
route_0 int[],
route_1 int[],
route_2 int[],
route_3 int[],
tot_incr float,
diff_0 float,
diff_1 float,
diff_2 float,
diff_3 float,
dist_depot_0 float,
dist_depot_1 float,
dist_depot_2 float,
dist_depot_3 float,
tot_diff float
);


drop view if exists drc.cycle_routes ;
create view drc.cycle_routes as
select *, diff_node_0+diff_node_1+diff_node_2+diff_node_3 as tot_diff from 
(select *,
  (s.incr_0+s.incr_1+s.incr_2) as incr_tot,
  (select * from dist_to_depot(prev_node_0))-incr_0 as diff_node_0,
  (select * from dist_to_depot(prev_node_1))-incr_1 as diff_node_1,
  (select * from dist_to_depot(prev_node_2))-incr_2 as diff_node_2,
  (select * from dist_to_depot(prev_node_3))-incr_3 as diff_node_3,
  (select * from dist_to_depot(med[1])) as dist_depot_0,
  (select * from dist_to_depot(med[2])) as dist_depot_1,
  (select * from dist_to_depot(med[3])) as dist_depot_2,
  (select * from dist_to_depot(med[4])) as dist_depot_3
from 
(select *, 
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node_0))-total_dist as incr_0,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node_1))-total_dist as incr_1,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node_2))-total_dist as incr_2,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node_3))-total_dist as incr_3,
  (SELECT * from pgr_tsp_route(q.nodes || q.prev_node_0)) as route_0,
  (SELECT * from pgr_tsp_route(q.nodes || q.prev_node_1)) as route_1,
  (SELECT * from pgr_tsp_route(q.nodes || q.prev_node_2)) as route_2,
  (SELECT * from pgr_tsp_route(q.nodes || q.prev_node_3)) as route_3
   from 
  (select *, 
  (select med[1] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + 12) % 14) as prev_node_0,
  (select med[2] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + 12) % 14) as prev_node_1,
  (select med[3] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + 12) % 14) as prev_node_2,
  (select med[4] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + 12) % 14) as prev_node_3
  from drc.most_recent_solution_instance d order by route_seq_zero) as q) as s) as t;


CREATE FUNCTION cycle_route_costs_recent_solution(integer) RETURNS SETOF drc.cycle_routes AS $$
-- TODO JAN 2015: include parameter for cost/km for different planes in order to calculate the diff_node_n properly
-- first parameter is number of records
select *, diff_node_0+diff_node_1+diff_node_2+diff_node_3 as tot_diff from 
(select *,
  (s.incr_0+s.incr_1+s.incr_2) as incr_tot,
  (select * from dist_to_depot(prev_node_0))-incr_0 as diff_node_0,
  (select * from dist_to_depot(prev_node_1))-incr_1 as diff_node_1,
  (select * from dist_to_depot(prev_node_2))-incr_2 as diff_node_2,
  (select * from dist_to_depot(prev_node_3))-incr_3 as diff_node_3,
  (select * from dist_to_depot(med[1])) as dist_depot_0,
  (select * from dist_to_depot(med[2])) as dist_depot_1,
  (select * from dist_to_depot(med[3])) as dist_depot_2,
  (select * from dist_to_depot(med[4])) as dist_depot_3
 from 
(select *, 
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_node_0))-total_dist) as incr_0,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_node_1))-total_dist) as incr_1,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_node_2))-total_dist) as incr_2,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_node_3))-total_dist) as incr_3,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_node_0)) as route_0,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_node_1)) as route_1,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_node_2)) as route_2,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_node_3)) as route_3
   from 
  (select *, 
  (select med[1] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + $1 - 1) % $1) as prev_node_0,
  (select med[2] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + $1 - 1) % $1) as prev_node_1,
  (select med[3] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + $1 - 1) % $1) as prev_node_2,
  (select med[4] from drc.most_recent_solution_instance where route_seq_zero=(d.route_seq_zero + $1 - 1) % $1) as prev_node_3
  from drc.most_recent_solution_instance d order by d.route_seq_zero) as q) as s) as t;
$$ LANGUAGE sql;


--drop function if exists cycle_route_costs(integer, integer);

CREATE FUNCTION cycle_route_costs(integer, integer) RETURNS SETOF temp_type AS $$
-- TODO JAN 2015: include parameter for cost/km for different planes in order to calculate the diff_node_n properly
-- first parameter is number of records
select *, diff_node_0+diff_node_1+diff_node_2+diff_node_3 as tot_diff from 
(select *,
  (s.incr_0+s.incr_1+s.incr_2) as incr_tot,
  (select * from dist_to_depot(prev_med[0]))-incr_0 as diff_node_0,
  (select * from dist_to_depot(prev_med[1]))-incr_1 as diff_node_1,
  (select * from dist_to_depot(prev_med[2]))-incr_2 as diff_node_2,
  (select * from dist_to_depot(prev_med[3]))-incr_3 as diff_node_3,
  (select * from dist_to_depot(med[1])) as dist_depot_0,
  (select * from dist_to_depot(med[2])) as dist_depot_1,
  (select * from dist_to_depot(med[3])) as dist_depot_2,
  (select * from dist_to_depot(med[4])) as dist_depot_3
 from 
(select *, 
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[1]))-total_dist) as incr_0,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[2]))-total_dist) as incr_1,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[3]))-total_dist) as incr_2,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[4]))-total_dist) as incr_3,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[1])) as route_0,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[2])) as route_1,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[3])) as route_2,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[4])) as route_3
   from 
  (select *, 
  (select med from (select * from drc.get_solution_instance($2)) w where route_seq_zero=(d.route_seq_zero + $1 - 1) % $1) as prev_med
  from drc.get_solution_instance($2) d order by d.route_seq_zero) as q) as s) as t;
$$ LANGUAGE sql;

-- NOTE: TOTAL DRY violation below. Not sure how to generalize the function at this point
CREATE FUNCTION cycle_route_costs_rev(integer, integer) RETURNS SETOF temp_type AS $$
-- TODO JAN 2015: include parameter for cost/km for different planes in order to calculate the diff_node_n properly
-- first parameter is number of records
select *, diff_node_0+diff_node_1+diff_node_2+diff_node_3 as tot_diff from 
(select *,
  (s.incr_0+s.incr_1+s.incr_2) as incr_tot,
  (select * from dist_to_depot(prev_med[0]))-incr_0 as diff_node_0,
  (select * from dist_to_depot(prev_med[1]))-incr_1 as diff_node_1,
  (select * from dist_to_depot(prev_med[2]))-incr_2 as diff_node_2,
  (select * from dist_to_depot(prev_med[3]))-incr_3 as diff_node_3,
  (select * from dist_to_depot(med[1])) as dist_depot_0,
  (select * from dist_to_depot(med[2])) as dist_depot_1,
  (select * from dist_to_depot(med[3])) as dist_depot_2,
  (select * from dist_to_depot(med[4])) as dist_depot_3
 from 
(select *, 
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[1]))-total_dist) as incr_0,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[2]))-total_dist) as incr_1,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[3]))-total_dist) as incr_2,
  round((SELECT * from pgr_tsp_var(q.nodes || q.prev_med[4]))-total_dist) as incr_3,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[1])) as route_0,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[2])) as route_1,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[3])) as route_2,
  (SELECT * from pgr_tsp_route2(q.nodes, q.prev_med[4])) as route_3
   from 
  (select *, 
  (select med from (select * from drc.get_solution_instance($2)) w where route_seq_rev_zero=(d.route_seq_rev_zero + $1 - 1) % $1) as prev_med
  from drc.get_solution_instance($2) d order by d.route_seq_rev_zero) as q) as s) as t;
$$ LANGUAGE sql;





-- specify the solution we want
--select * from cycle_route_costs(14, 1670) as t1;
select * from cycle_route_costs(14, 1663) as t1;
select * from cycle_route_costs_rev(14, 1663) as t1;

--select * from drc.get_solution_instance(1633)

-- specify the most recent solution
--select * from cycle_route_costs_recent_solution(14) as t1;

--select med[4] from drc.most_recent_solution_instance
--SELECT pgr_tsp_route as temp from pgr_tsp_route(array[135,261,377,262,223] || 0);

--select count(*) from drc.most_recent_solution_instance