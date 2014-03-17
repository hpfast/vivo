Setting up the data and importing data -- general notes
=======================================================


General notes -- see reference SQL files for install procedures.


The setup of the database is a schema `drc-admin and a schema  `hospitals. The first is for generated administrative boundary geometries which will be useable outside this project, and the second is for the analytical tables for this project. Keep the schemas clean by documenting edit steps well and cleaning up unused tables.

We will finally be using tables `hospitals `distances `cities and maybe some others.

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

Next is airports. Importing from CSV with geometrty fields we will use `ogr2ogr and a 'virtual format' file.

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




