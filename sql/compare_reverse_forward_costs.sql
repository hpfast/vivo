select sum(tot_diff) from (
select *, diff_node1+diff_node2+diff_node3 as tot_diff from 
(select *,
  (s.incr_1+s.incr_2+s.incr_3) as incr_tot,
  (select * from dist_to_depot(prev_node1))-incr_1 as diff_node1,
  (select * from dist_to_depot(prev_node2))-incr_2 as diff_node2,
  (select * from dist_to_depot(prev_node3))-incr_3 as diff_node3
 from 
(select *, 
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node1))-total_dist as incr_1,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node2))-total_dist as incr_2,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node3))-total_dist as incr_3
   from 
  (select *, 
  (select med[1] from drc.most_recent_solution_instance where route_seq=((d.route_seq+12)%(select count(*) from drc.most_recent_solution_instance)+1)) as prev_node1,
  (select med[2] from drc.most_recent_solution_instance where route_seq=((d.route_seq+12)%(select count(*) from drc.most_recent_solution_instance)+1)) as prev_node2,
  (select med[3] from drc.most_recent_solution_instance where route_seq=((d.route_seq+12)%(select count(*) from drc.most_recent_solution_instance)+1)) as prev_node3
  from drc.most_recent_solution_instance d order by route_seq_rev) as q) as s) as t) as u;


select sum(tot_diff) from (
select *, diff_node1+diff_node2+diff_node3 as tot_diff from 
(select *,
  (s.incr_1+s.incr_2+s.incr_3) as incr_tot,
  (select * from dist_to_depot(prev_node1))-incr_1 as diff_node1,
  (select * from dist_to_depot(prev_node2))-incr_2 as diff_node2,
  (select * from dist_to_depot(prev_node3))-incr_3 as diff_node3
 from 
(select *, 
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node1))-total_dist as incr_1,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node2))-total_dist as incr_2,
  (SELECT * from pgr_tsp_var(q.nodes || q.prev_node3))-total_dist as incr_3
   from 
  (select *, 
  (select med[1] from drc.most_recent_solution_instance where route_seq=((d.route_seq+12)%(select count(*) from drc.most_recent_solution_instance)+1)) as prev_node1,
  (select med[2] from drc.most_recent_solution_instance where route_seq=((d.route_seq+12)%(select count(*) from drc.most_recent_solution_instance)+1)) as prev_node2,
  (select med[3] from drc.most_recent_solution_instance where route_seq=((d.route_seq+12)%(select count(*) from drc.most_recent_solution_instance)+1)) as prev_node3
  from drc.most_recent_solution_instance d order by route_seq) as q) as s) as t) as u;

