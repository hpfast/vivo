#!/usr/bin/python

"""
given query parameters to select hospitals, returns voronoi polygons around hospitals as GeoJSON.

DEPENDENCIES:
python voronoi function
	Add the Voronoi function from https://gist.githubusercontent.com/darrell/6056046/raw/43f54c8e8492e5c66e00aab86bf258cec60fdc4b/voronoi.sql
	
	run the sql to install it
	psql -f ~/voronoi.sql -d geodrc
psycopg2
(ppygis)
(shapely)
geojson
"""

import sys
import psycopg2	#connect to postgresql databases
import ppygis	#use postgis-specific types and convert them to python types
from shapely.wkb import dumps, loads	#manipulate geometries in python
from shapely.geometry import shape
import geojson	#do geojson stuff
import pprint


def main():
	"""
	main function
	"""	

	#get the query parameters from invocation arguments
	args = sys.argv[1:]
	params = argsparse(args)
	for param in params:
		print "param is \n"
		print param

	#build postgresql connection string
	conn_string = "host='localhost' port='5438' dbname='geodrc' user='hans' password=''"
	#print the connection string we will use to connect
	print "Connecting to database\n    ->%s" % (conn_string)
	
	try:
		# get a connection, if a connect cannot be made an exception will be raised here
		conn = psycopg2.connect(conn_string)

		# conn.cursor will return a cursor object, you can use this cursor to perform queries
		cursor = conn.cursor()
		print "connection successful"
		
		
		#build several queries, since we need to run the analysis in several steps.
		
		#build a query string from the parameters
		qWhereClause = ""
		
		#max two parameters. First if there's only one, parse as follows:
		
		if len(params) == 1:
			qWhereClause = "WHERE " + build_conditional(params[0])
				
		#else if there's two, join them with AND
		else:
			conditions = []
			conditions.append(build_conditional(params[0]))
			conditions.append(build_conditional(params[1]))
			qWhereClause = "WHERE " + " AND ".join(conditions)
		
		print qWhereClause
		
		#FROM clause hardcoded
		qTempTableFromClause = " FROM (SELECT st_collect(wkb_geometry) wkb_geometry FROM drc.larger_cities) as larger_cities, drc.hospitals "
		qTempSelect = "SELECT h.hz_id, h.point, h.name FROM drc.hospitals h, drc.larger_cities c"
		
		# a select clause for a voronoi function
		qSelect = "SELECT st_asgeojson(point) FROM voronoi('drc.hosp_select','point') AS (hz_id integer, point geometry) WHERE hz_id in (SELECT hospitals.hz_id" + qFromClause + qWhereClause + ")"
		
		
		print "Running voronoi on ..."
		print qTempSelect
		
		
		# 2. execute database queries
		
		#execute the queries
		cursor.execute(qTempSelect)
		cursor.execute(qVoronoi)
		
		#fetch the query results
		voronois = cursor.fetchall()
		
		print "finished executing query"
		
		# Close communication with the database
		cursor.close()
		conn.close()
		print "disconnection successful"
		col = []
		#convert the well-known-binary geometry representations to python data types
		for geom in voronois:
			u = ''.join(geom)
		
			#v = ppygis.Geometry.read_ewkb(geom)
			#print v
			#print geom
			#print geom.read_ewkb()
			w = geojson.loads(u)
			#print w
			#var = dumps(v)
			print w
			r = shape(w) #r is a shapely object
			print r
			#s = loads(str(geom)) this should also be a way to get shapely, but doesn't work.
			feature = geojson.Feature(
				geometry=w,
				properties={
					"name":"null"
						}
			)
			col.append(feature)
		
		collection = geojson.dumps(geojson.FeatureCollection(col))	
			
			# output is the main content, rowOutput is the content from each record returned
		output = ""
		rowOutput = ""
		count = 0
		for geom in voronois:
			count += 1
			gom = str(geom)
			#print gom
			oput = '{"type": "Feature", "properties": {"name": "duh"}, "geometry": ' + ''.join(geom) + '}'
			output += oput+',' 
		#print output
		# Assemble the GeoJSON
		totalOutput = '{ "type": "FeatureCollection", "features": [ ' + output + ' ]}'
			
		with open('/home/hans/priv/vivo/file.geojson', 'w') as outfile:
			#outfile.write(totalOutput)
			outfile.write(collection)
		print "wrote "+str(count)+" features"
	except:
		# Get the most recent exception
		exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
		# Exit the script and print an error telling what happened.
		sys.exit("Database connection failed!\n ->%s" % (exceptionValue))
	

#helper function to build conditionals for WHERE clause
def build_conditional(param):
	#very crude checks to use comparison operators and put single quotes around strings
	qComparitor = ">=" if (param[0] == "dist_city") else "="
	qValue = param[1] if param[0] == "dist_city" else "'"+param[1]+"'"
	qWhereCondition = lookup(param[0]) + qComparitor + qValue
	return qWhereCondition	


#helper function to translate cli-params to postgis functions/column names
def lookup(param):
	if param == "dist_city":
		return "st_distance(geography(st_transform(hospitals.point,4326)),geography(st_transform(st_closestpoint(larger_cities.wkb_geometry,hospitals.point),4326)))"
	elif param == "prov":
		return "hospitals.provname"

#helper function to parse arguments
def argsparse(args):
	"""
	get invocation arguments. Some quick and dirty checking.
	only takes two optional params:
	dist_city=INTEGER and province=STRING
	"""
	params = []
	if len(args) >=1:
		for argstring in args:
			try:
				parampairs = argstring.split("=")
				params.append(parampairs)
			except:
				print "parameter input was invalid, should be param_name=param_value"
	else:
		sys.exit("need some filter params, voronoi of all of Congo would take too long")

	return params









if __name__ == '__main__':
	sys.exit(main())
