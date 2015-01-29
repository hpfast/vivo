---- Note: Make sure we run most_recent_solution.sql afterward

drop function if exists minimum(anyarray) cascade;
create function minimum(anyarray)
returns anyelement as $$
select min($1[i]) from generate_series(array_lower($1,1),
array_upper($1,1)) g(i);
$$ language sql immutable strict;

drop function if exists maximum(anyarray) cascade;
create function maximum(anyarray)
returns anyelement as $$
select max($1[i]) from generate_series(array_lower($1,1), array_upper($1,1)) g(i);
$$ language sql immutable strict;

drop function average(anyarray) cascade;
create function average(anyarray)
returns anyelement as $$
select avg($1[i]) from generate_series(array_lower($1,1),
array_upper($1,1)) g(i);
$$ language sql immutable strict;

-- handle routes that straddle the origin degree
-- hack, but works for now
DROP FUNCTION IF EXISTS minimum2(anyarray float[]) cascade;;
CREATE FUNCTION minimum2(anyarray float[]) returns float AS $$
#plpy.info(anyarray) 
if max(anyarray) > 5.0 and min(anyarray)<1.0:
  newarray = [rad for rad in anyarray if rad>=1]
  return min(newarray)
else:
  return min(anyarray)
$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS maximum2(anyarray float[]) cascade;;
CREATE FUNCTION maximum2(anyarray float[]) returns float AS $$
#plpy.info(anyarray) 
if max(anyarray) > 5.0 and min(anyarray)<1.0:
  newarray = [rad for rad in anyarray if rad<=5]
  return max(newarray)
else:
  return max(anyarray)
$$ LANGUAGE plpythonu;



-- Get first item from array
-- NOT NEEDED using nodes[0]
DROP FUNCTION IF EXISTS first(anyarray int[]);
CREATE FUNCTION first(anyarray int[]) returns int AS $$
return anyarray[0]
$$ LANGUAGE plpythonu;







