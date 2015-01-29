-- Note: need to recreate cycle_route_costs() after this

--------------------------------------
DROP VIEW IF EXISTS drc.most_recent_solution cascade;
CREATE VIEW drc.most_recent_solution as
select * from drc.route_instances i where sol_id=(select min(sol_id) from drc.solutions where run_id=(select max(run_id) from drc.runs));

--------------------------------------
DROP FUNCTION IF EXISTS drc.get_solution(integer);
CREATE FUNCTION drc.get_solution(integer) RETURNS SETOF drc.route_instances AS $$
select * from drc.route_instances i where sol_id=$1
$$ LANGUAGE sql;

--------------------------------------
CREATE OR REPLACE VIEW drc.most_recent_solution_instance AS 
 SELECT row_number() OVER () AS route_seq_rev,
    row_number() OVER () - 1 AS route_seq_rev_zero,
    q.route_seq,
    q.route_seq_zero,
    q.month,
    q.trip,
    q.route_id,
    q.sol_id,
    q.name,
    q.nodes,
    q.med,
    q.dist,
    q.rad_order,
    q.rad_degree,
    q.pickup,
    q.dropoff,
    q.total_dist,
    q.depot
   FROM ( SELECT row_number() OVER () AS route_seq,
            row_number() OVER () - 1 AS route_seq_zero,
            t.month,
            t.trip,
            t.route_id,
            t.sol_id,
            t.name,
            t.nodes,
            t.med,
            t.dist,
            t.rad_order,
            t.rad_degree,
            t.pickup,
            t.dropoff,
            t.total_dist,
            t.depot
           FROM ( SELECT s.month,
                    s.trip,
                    r.route_id,
                    s.sol_id,
                    r.name,
                    r.nodes,
                    r.med,
                    r.dist,
                    r.rad_order,
                    r.rad_degree,
                    r.pickup,
                    r.dropoff,
                    r.total_dist,
                    r.depot
                   FROM drc.most_recent_solution s
                     JOIN drc.routes r ON s.route_id::text = r.name::text
                  ORDER BY minimum2(r.rad_degree)) t
          ORDER BY maximum2(t.rad_degree) DESC) q;

---------------------------------
DROP FUNCTION IF EXISTS drc.get_solution_instance(integer);
CREATE FUNCTION drc.get_solution_instance(integer) RETURNS SETOF drc.most_recent_solution_instance AS $$
-- NEED TO REVIEW THE FOLLOWING 
select row_number() OVER () AS route_seq_rev, 
       row_number() OVER () - 1 AS route_seq_rev_zero, 
       * 
  from (
 SELECT row_number() OVER () AS route_seq,
    row_number() OVER () - 1 AS route_seq_zero,
    t.month,
    t.trip,
    t.route_id,
    t.sol_id,
    t.name,
    t.nodes,
    t.med,
    t.dist,
    t.rad_order,
    t.rad_degree,
    t.pickup,
    t.dropoff,
    t.total_dist,
    t.depot
   FROM ( SELECT s.month,
            s.trip,
            r.route_id,
            s.sol_id,
            r.name,
            r.nodes,
            r.med,
            r.dist,
            r.rad_order,
            r.rad_degree,
            r.pickup,
            r.dropoff,
            r.total_dist,
            r.depot
           FROM drc.get_solution($1) s
             JOIN drc.routes r ON s.route_id::text = r.name::text
          ORDER BY minimum2(r.rad_degree)) t
  ORDER BY maximum2(rad_degree) DESC) q;
$$ LANGUAGE sql;


--select * from drc.get_solution(1589);
select * from drc.get_solution_instance(3124) order by route_seq;
--select * from drc.most_recent_solution_instance;

