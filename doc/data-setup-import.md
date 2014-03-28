Setting up the data and importing data -- general notes
=======================================================


General notes -- see reference SQL files for install procedures.


The setup of the database is a schema `drc-admin` and a schema  `hospitals`. The first is for generated administrative boundary geometries which will be useable outside this project, and the second is for the analytical tables for this project. Keep the schemas clean by documenting edit steps well and cleaning up unused tables.

We will finally be using tables `hospitals` `distances` `cities` and maybe some others.

##Inventory of tables -- what to do with them?

Here are the datasets we have:

- COD_roads.3
- DRC_roads.3
- DRC_airports
- Roads.rar (containing COD_roads)
- MAF KIN Destinations.kmz
- congonames
- pyramide assignation
- DRC_518HZs


#Congo cities

First table is cities of Congo. We are importing this from a shapefile using ogr2ogr.

    ogr2ogr -f "PostgreSQL" PG:"host=localhost dbname=geodrc user=USER password=PASSWORD" -nln cities -nlt POINT -lco SCHEMA=drc_admin SHAPEFILE

#DRC Airports

Next is airports. Importing from CSV with geometry fields we will use `ogr2ogr` and a 'virtual format' file.

Create a VRT file with the following format:

    <OGRVRTDataSource>
        <OGRVRTLayer name="airports">
            <SrcDataSource>airports.csv</SrcDataSource>
            <GeometryType>wkbPoint</GeometryType>
                <LayerSRS>WGS84</LayerSRS>
            <GeometryField encoding="PointFromColumns" x="longitude" y="latitude"/>
        </OGRVRTLayer>
    </OGRVRTDataSource>

and save it with the name airports.vrt. Note that the OGRVRTLayer name attribute needs to match the name of the csv file you are importing and the GeometryField x and y attributes need to match the names of the appropriate columns in the csv file. The SrcDataSource also needs to be the name/path to the csv file.

Now you can import into PostgreSQL using ogr2ogr:

	ogr2ogr -f "PostgreSQL" PG:"dbname=geodrc" -nln airports -nlt POINT -lco SCHEMA=drc_admin -lco OVERWRITE=YES airports.vrt

#MAF Airports

We also have a KML file with airports from MAF. This has a different format. First, load kml in qgis and use MMQGIS tools to combine all the airports to one shapefile.
Problem: ogr2ogr postgresql import truncates the description field at first newline. Couldn't find any solution to this online, so used a macro in vim to delete all these newlines in the kml file, then use mmqgis to combine them.
Then import this into postgresql with ogr2ogr.

The idea is to add all unique airports from the two layers together. To be able to make this comparison, first we have to standardize the columns. We're going to use

#healthzones

Healthzones come from a shapefile. The geometries are not very good: the polygons don't match up very well. Before importing, I cleaned it up with pprepair:

	pprepair --i INPUTFILE.shp -o healthzones_fixed.shp -fix
	
Then import the shapefile into PostgreSQL with ogr2ogr:

    ogr2ogr -f "PostgreSQL" PG:"host=localhost dbname=geodrc user=USER password=PASSWORD" -nln healthzones -nlt POINT -lco SCHEMA=drc_admin healthzones_fixed.shp

#Locating hospitals


We are trying to find locations for hospitals by using the healthzone polygons. We join to cities by name to get the most likely location, assuming that the hospital for a healthzone will most often be in the populated place of the same name as the healthzone. We then process the remaining ones and mark those that are questionable.

## hospital locations first pass

### join to cities by name

Try to locate as many hospitals with a name join to the cities table. We add the further constraint that the cities must be spatially contained by the geometry of the health zone

	create table hospitals.test_join_with_contains as select
		a.name,
		a.wkb_geometry as point,
		b.ZS as name_hz,
	b.wkb_geometry as pol
	from
		drc_admin.cities a,
		drc_admin.healthzones b
	where
		a.name = b.ZS
	and
		st_contains(b.wkb_geometry, a.wkb_geometry)
	;
	--490

This gives fairly good results. Let's go ahead and find the centroids of the unmatched zones and store them in a temporary table. We'll add those in once we've removed the duplicates from this last step.

### using st_centroid for unmatched healthzones

	create table hospitals.centroids_unmatched_healthzones as select
		ZS as name,
		st_centroid(wkb_geometry) as point
	from
		drc_admin.healthzones
	where
		ZS not in (select name_api from hospitals.test_join_with_contains)
	;
	--Query returned successfully: 234 rows affected, 395 ms execution time.

## hospitals second pass -- removing duplicates in clusters

Taking the results of our first pass, we will try to select one location from the duplicates. We will do this by:

- where there is one point, select it and indicate as most certain

- where all points are less than 10km apart, we'll take the closest one at random and indicate this as the most certain.

- where points are more than 10km apart, we'll take the one closest to the centroid of the polygon and indicate this as doubtful.


### 1. create target table

	create table hospitals.dedup1 (
		point geometry(point,4326),
		name text,
		certainty text
	);
		
### 2. insert hospitals with exactly one match from previous step

	alter table hospitals.test_join_with_contains add column gid serial;

	with preselect as (
		select
			name,
			count(name) as count
		from
			hospitals.test_join_with_contains
		group by
			name
		)
		
	insert into hospitals.dedup1
	select
		a.point,
		a.name,
		'single match'
	from
		hospitals.test_join_with_contains a,
		preselect
	where
		a.name = preselect.name
	and
		preselect.count = 1
	;
	--139
	
### 3. insert hospitals with two matches less than 10 km apart

* create a pairs table with distances between points in healthzone (where count = 2)
* select only those where distance is 10km or less (table pairs10k)
* from this, we can select 1 at random using gid.



## hospitals third pass -- removing 


## hospitals final -- assembling final table

#final hospitals table with custom attributes

##nearest airport

It turns out to be a bit of a challenge to merge the two airport tables. Hard to know which one to take as authoritative.

So first I'm just using the airports table (without the MAF airports).

I create a table with the hospital id, the id of the nearest airport, and the distance between them in metres.

	with preselect as (
		select
			h.hz_id,
			(select a.ogc_fid from drc_admin.airports a
				order by h.point <-> a.wkb_geometry limit 1
			)
		from
			hospitals.hospitals h
	)
	select
		i.hz_id,
		i.name as h_name,
		b.name a_name,
		b.ogc_fid,
		b.icao,
		round(st_distance(
			geography(st_transform(i.point,4326)),
			geography(st_transform(b.wkb_geometry,4326))
		)) as distance
	into
		hospitals.nearest_airport_without_maf
	from
		hospitals.hospitals i,
		drc_admin.airports b,
		preselect
	where
		i.hz_id = preselect.hz_id
	and
		b.ogc_fid = preselect.ogc_fid
	;--518

Then, we can set the two airport-related columns in the hospitals table.

	--assuming ogc_fid is good ...
	update hospitals.hospitals
	set
		id_nearest_airport = n.ogc_fid
	from
		hospitals.nearest_airport_without_maf n
	where
		hospitals.hz_id = n.hz_id
	;--518

	update hospitals.hospitals
	set
		dist_nearest_airport = n.distance
	from
		hospitals.nearest_airport_without_maf n
	where
		hospitals.hz_id = n.hz_id
	;--518

#create final schema and tables

one schema for export:

* drc

with tables:

* hospitals
* airports
* healthzones
* cities
* larger_cities (view)

The tables are all indexed.
