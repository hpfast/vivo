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
import os
import sys
import psycopg2	#connect to postgresql databases
import ppygis	#use postgis-specific types and convert them to python types
from shapely.wkb import dumps, loads	#manipulate geometries in python
from shapely.geometry import shape
from binascii import a2b_hex, b2a_hex
import geojson	#do geojson stuff
import pprint
from userconfig import *

def main():
	"""
	main function
	"""	

	#get the query parameters from invocation arguments
	args = sys.argv[1:]
	params = argsparse(args)
	if params:
		for param in params:
			print "param is \n"
			print param

	#build postgresql connection string
    #conn_string = "host='gis' port='5432' dbname='postgres' user='postgres' password=''"
	#print the connection string we will use to connect
	print "Connecting to database\n    ->%s" % (config['conn_string'])
	
	try:
		# get a connection, if a connect cannot be made an exception will be raised here
		conn = psycopg2.connect(config['conn_string'])

		# conn.cursor will return a cursor object, you can use this cursor to perform queries
		cursor = conn.cursor()
		print "connection successful"
		
		
		#build several queries, since we need to run the analysis in several steps.
		
		#build a query string from the parameters
		qWhereClause = ""
		
		#max two parameters. First if there's only one, parse as follows:
		
		if params:
			if len(params) == 1:
				qWhereClause = "WHERE " + build_conditional(params[0])
					
			#else if there's two, join them with AND
			elif len(params) == 2:
				conditions = []
				conditions.append(build_conditional(params[0]))
				conditions.append(build_conditional(params[1]))
				qWhereClause = "WHERE " + " AND ".join(conditions)
			elif len(params) == 0:
				qWhereClause = ""
		
		print qWhereClause
		
		#FROM clause hardcoded
		qTempTableFromClause = " FROM (SELECT st_collect(wkb_geometry) wkb_geometry FROM drc.larger_cities) as larger_cities, drc.hospitals "
		qTempSelect = " hospitals.hz_id FROM drc.hospitals , drc.larger_cities  "
		
		# a select clause for a voronoi function
		qSelect = "SELECT * FROM voronoi('drc.hospitals', 'point') AS (id integer, point geometry) WHERE id in (SELECT "+ qTempSelect + qWhereClause + ")"
		
		
		print "Running voronoi on ..."
		print qSelect
		
		
		# 2. execute database queries
		
		#execute the queries
		#cursor.execute(qTempSelect)
		cursor.execute(qSelect)
		
		#fetch the query results
		voronois = cursor.fetchall()
		
		print "finished executing query"
		
		# Close communication with the database
		cursor.close()
		conn.close()
		print "disconnection successful"
		col = []
		#convert the well-known-binary geometry representations to python data types
		for record in voronois: #obj is a tuple with attributes from postgresql table
			#u = ''.join(geom[1])
			#print u
			#v = ppygis.Geometry.read_ewkb(geom[1])
			#print geom[0]
			#w = geojson.Polygon(v)
			#print " ", geom[0]
			#print u.read_ewkb()
			
			#w = geojson.loads(geom[1])
			##print w
			#var = geojson.dumps(v)
			#print var
			#print w
			#r = shape(u) #r is a shapely object
			#print r
			
			s = loads(a2b_hex(record[1])) #postgis uses hex encoding, need to account for this
			#print s, record[0]
			feature = geojson.Feature(
				geometry=s,
				properties={
					"id": record[0]
						}
			)
			col.append(feature)
		
		collection = geojson.dumps(geojson.FeatureCollection(col))	
		
		#below is an alternative method to pass through the geojson if we use the postgis st_asgeojson() to request our geometries in geojson format already: just concat them together with the geojson fluff manually.	
			# output is the main content, rowOutput is the content from each record returned
		#output = ""
		#rowOutput = ""
		#count = 0
		#for geom in voronois:
			#print geom
			#count += 1
			#gom = (geom[0])
			#print gom
			#oput = '{"type": "Feature", "properties": {"id": "'+str(geom[1])+'"}, "geometry": ' + ''.join(gom) + '}'
			#output += oput+',' 
		#print output
		### Assemble the GeoJSON
		#totalOutput = '{ "type": "FeatureCollection", "features": [ ' + output + ' ]}'
			
		with open(os.path.normpath(config['output_path']) + 'file.geojson', 'w') as outfile:
			#outfile.write(totalOutput)
			outfile.write(collection)
		#print "wrote "+str(count)+" features"
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
		#sys.exit("need some filter params, voronoi of all of Congo would take too long")
		return
	return params



if __name__ == '__main__':
	sys.exit(main())
