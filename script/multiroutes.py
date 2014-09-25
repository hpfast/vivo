#!/usr/bin/python

"""
SUMMARY

Given ordered list of hospital IDs as input, returns their point geometries with their route order as label and routes between them as linestrings (in GeoJSON geometrycollection).
This version takes multiple ordered lists representing different routes, and combines these into separate multilinestrings within a single featurecollection representing all the routes.

USAGE

This is a demo so accepted input is very limited. Invoke as:

    routes.py LISTFILE
    
where listfile is a plain text file with each line representing one route, containing hospital IDs in order separated by spaces, e.g.:

    143 128 129 100 46
    133 25 28 100 121 131 133
    34 12 99 100 22 13 34
    
Writes a single file multiroutes.geojson.

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
    print os.path.normpath(config['output_path'])+'lines.geojson'
    with open(os.path.normpath(config['output_path']) + '/lines.geojson', 'w') as outfile:
        outfile.write(geojson.dumps(collection))
    outfile.close()
    print "wrote features to "+os.path.normpath(config['output_path'])+"lines.geojson"
    # -------------------------------------
    # DRAW LINES BETWEEN POINTS
    # -------------------------------------
    #convert geometries in hosps to shapely objects (from well-known-binary format received from postgis)
#    for route in routes:
#        line = []
#        for h in route:
#            route[h]['geom'] = loads(a2b_hex(route[h]['geom'])) #postgis uses hex encoding, need to account for this
#            line.append(dict((str(first)+"_"+str(second),{}) for first,second in grouper(list(route), 2)))
    #TODO: modify the following to create an array of key, multilinestring. In two steps? first create a multilinestring for each route, then
    #line can be as below
    #multiline the joined lines for each route
    #lines the container to hold them all.
        #create a new dict to hold our line features
        #initially contains key and empty dict as value
        
        #add geometry and properties to lines dict
        #loop over every consecutive pair from input points
        #we can thus add attrs of both points, and create a line between them.
#        i = 1
        #for first, second in grouper(list(route), 2):
           # print "first is "+str(first) +", second is "+str(second)
        #    for l in line:
               # if l == str(first)+"_"+str(second):
#                    print "hello!!!!!!!!!!!!!"
                    #get x and y coords from shapely point objects   
               #     x1 = route[first]['geom'].x
               #     y1 = route[first]['geom'].y
               #     x2 = route[second]['geom'].x
               #     y2 = route[second]['geom'].y
                    #create an item in lines with id and name of start/end hosps, and linestring geometry
               #     line[l].update({
               #         'start_id':first,
               #         'start_name': hosps[first]['name'],
               #         'end_id':second,
               #         'end_name':hosps[second]['name'],
               #         'order_id': i,
               #         #here comes the new linestring geometry
               #         'geom':LineString([(x1,y1),(x2,y2)]),
               #         'line_id':l
                        #uses shapely LineString constructor with x,y coords of start and end points

                        # JBC: thought the following might work to add errors, but it couldn't serialize the output 
                        # 'geom':pylab.arrow(x1, y1, x2, y2, color='#999999', aa=True, head_width=1.0, head_length=1.0),
               #     })
           # i+=1;       

    #end main

#db fetch function. A separate query for each route -- sufficient performance for small route sets.
def db_fetch(cursor, route):
    keys = list(route)
    cursor.execute("SELECT name, hz_id, point from drc.hospitals WHERE hz_id IN ('"+ "','".join(str(x) for x in keys)+"')")
    db_matches = cursor.fetchall()
    return db_matches

#helper function from stackoverflow to iterate consecutive pairs
def grouper(input_list, n = 2):
    for i in xrange(len(input_list) - (n - 1)):
        yield input_list[i:i+n]
        
if __name__ == "__main__":
    sys.exit(main())
