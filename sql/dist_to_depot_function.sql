--drop function if exists dist_to_depot(hz_id int) cascade;
--select dist from drc.hosp_dist where hz_id1=223 and hz_id2=23
--create function dist_to_depot(hz_id int)
--returns float as $$
--select round((dist/1000)::numeric,2)::float from drc.hosp_dist where hz_id1=223 and hz_id2=$1
--$$ language sql immutable strict;

drop function if exists dist_to_depot(hz_id int) cascade;
create function dist_to_depot(hz_id int) returns float AS
$$
if hz_id is None:
  return 0
sql = "select round((dist/1000)::numeric,2)::float from drc.hosp_dist where hz_id1=223 and hz_id2=%s" % hz_id
results = plpy.execute(sql)
return results[0]['round']
$$ LANGUAGE plpythonu;

-- Example (should be about 139 km from hgr 462 to depot (223)
select * from dist_to_depot(203);
--select * from dist_to_depot(Null);
--select * from drc.hosp_dist limit 5;

