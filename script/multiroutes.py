#!/usr/bin/python

"""
SUMMARY

Given lists of hospital IDs representing routes, This script produces a GeoJSON featurecollection representing all the routes.

USAGE

This is a demo so accepted input is very limited. Invoke as:

    routes.py LISTFILE
    
where listfile is a plain text file with each line representing one route, containing hospital IDs in order separated by spaces, e.g.:

    143 128 129 100 46
    133 25 28 100 121 131 133
    34 12 99 100 22 13 34
    
Writes a single file as specified in the config file 'userconfig.py'.

DEPENDENCIES

psycopg2
shapely
geojson
"""
import os
import sys
import psycopg2	#connect to postgresql databases
#import ppygis	#use postgis-specific types and convert them to python types
from shapely.wkb import dumps, loads	#manipulate geometries in python
from shapely.geometry import shape, LineString #create new geometries
from binascii import a2b_hex, b2a_hex #convert wkb geometries
import geojson	#do geojson stuff
import pprint
from userconfig import *


def main():
    """
    main function
    """	
    
    # ------------------------
    # IMPORT LIST OF HOSPITALS
    # ------------------------
    
    #The main datastructure is an array representing all the rountes.
    # Each route is a dict with key = hospID and value empty ready to hold geometries.
    routes = [] 
    inputlines = []
#    print sys.argv[1]
    try:
        arg = sys.argv[1]
        input_file = open(arg, 'r')
        inputline = input_file.readline()
        while inputline:
            line = inputline.rstrip()
            ls = line.split(' ')
            ls = [int(i) for i in ls]
            hospar = ls
            inputlines.append(hospar) #put the array of hospital ids into the array of routes
            inputline = input_file.readline()
        input_file.close()
    except:
        exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
        sys.exit('error reading from input file. Does it exist?'+str(exceptionValue)+str(exceptionTraceback))


    # -----------------------------
    # ESTABLISH DATABASE CONNECTION
    # -----------------------------

    try:
        # get a connection, if a connect cannot be made an exception will be raised here
        conn = psycopg2.connect(config['conn_string'])

        # conn.cursor will return a cursor object, you can use this cursor to perform queries
        cursor = conn.cursor()
    except:
        # Get the most recent exception
        exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
        # Exit the script and print an error telling what happened.
        sys.exit("error connecting to database\n ->%s" % (exceptionValue))


    # -------------------------------------------------
    # FETCH DATA FROM DATABASE AND MERGE WITH HOSPITALS
    # -------------------------------------------------
    print inputlines
    lines2=[]
    for hosps in inputlines:
        line = {}
        ids = []
        points = []
        db_matches = db_fetch(cursor, hosps)
        for h in hosps:
            for f in db_matches:
                if f[1] == h:
                    ids.append(h)
                    points.append(loads(a2b_hex(f[2])))
        line.update({'ids':ids,'points':points})
        xys = LineString([l.x,l.y] for l in line['points'])
        line.update({'geom':xys})
        line.update({'start_id':line['ids'][0],'end_id':line['ids'][-1]})
        lines2.append(line)

    # ------------            
    # GEOJSONIFY
    # ------------
    
    #list to hold features
    col = []
    
    #create a geojson Feature out of every item in lines
    i = 0;
    for r in lines2:
        feature = geojson.Feature(
            geometry=lines2[i]['geom'],
            id=i+1,
            properties = {k: v for k, v in lines2[i].iteritems() if k != 'geom'} #everything not geom goes in props
        ) 
        col.append(feature)
        i+=1
    
    #make all features into a featurecollection
    collection = geojson.FeatureCollection(col)
    
    #order is in order_id key.
 
    #write featurecollection to file
    with open(os.path.normpath(config['output_path']) + '/lines.geojson', 'w') as outfile:
        outfile.write(geojson.dumps(collection))
    outfile.close()
    print "wrote features to "+os.path.normpath(config['output_path'])+"lines.geojson"

    #end main

#db fetch function. A separate query for each route -- sufficient performance for small route sets.
def db_fetch(cursor, route):
    keys = list(route)
    cursor.execute("SELECT name, hz_id, point from drc.hospitals WHERE hz_id IN ('"+ "','".join(str(x) for x in keys)+"')")
    db_matches = cursor.fetchall()
    return db_matches

        
if __name__ == "__main__":
    sys.exit(main())
