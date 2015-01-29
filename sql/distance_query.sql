SELECT hz_id, round(ST_Distance_Sphere(point, ST_MakePoint(18.78333, -5.033333)))
  as distance from hgr_subset
  where provname='Bandundu' 
  order by distance desc;
