-- 
select (d.route_seq_zero+1)%14 as ord, * from drc.most_recent_solution_instance d order by ord;
select (d.route_seq_rev_zero+1)%14 as ord, * from drc.most_recent_solution_instance d order by ord;

select * from drc.most_recent_solution_instance
select * from drc.most_recent_solution;
select * from drc.route_instances;
select * from drc.routes LIMIT 100; -- sol_id is incorrect, should probably be removed

--ALTER TABLE drc.routes RENAME COLUMN sol_id TO sol_id_tmp;

--select *, maximum2(rad_degree) from drc.most_recent_solution_instance order by maximum2(rad_degree) desc;

-- store both forward/reverse order based on minimum2(rad_degree)/maximum2(rad_degree)
-- add zero indexes for convenience
-- NOTE: reverse order of rad_degree is not necessarily the same as DESC order of forward due (see minimum2/maximum2 to see why) that is why we need to calculate the order indexes twice

DROP VIEW drc.most_recent_solution_instance;

CREATE OR REPLACE VIEW drc.most_recent_solution_instance AS
SELECT row_number() OVER () AS route_seq_rev, 
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
           FROM drc.most_recent_solution s
             JOIN drc.routes r ON s.route_id::text = r.name::text
          ORDER BY minimum2(r.rad_degree)) t
  ORDER BY maximum2(rad_degree) DESC) q;


select * from drc.most_recent_solution_instance;