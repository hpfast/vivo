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
    #hosps = {}
#    print sys.argv[1]
    try:
        arg = sys.argv[1]
        input_file = open(arg, 'r')
        inputline = input_file.readline()
        while inputline:
        #for inputline in input_file.readline():
#            print inputline
            line = inputline.rstrip()
            #route[i] = l #we'll need this later outside this scope
            ls = line.split(' ')
            ls = [int(i) for i in ls]
            hospar = ls
            hosps = dict((l,{}) for l in ls) #convert list to dict
            routes.append(hosps) #put the dict of hospitals into the array of routes
            inputline = input_file.readline()
#        print routes
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


    # -----------------------------------------------------
    # FETCH DATA FROM DATABASE AND MERGE INTO ROUTES OBJECT
    # -----------------------------------------------------

    for route in routes:
        db_matches = db_fetch(cursor, route)
        for f in db_matches:
            for h in route:
                if f[1] == h:
                    route[h].update({'name':f[0],'geom':f[2]}) #geom is still well-known binary format here


    # -------------------------------------
    # DRAW LINES BETWEEN CONSECUTIVE POINTS
    # -------------------------------------
    lines = []
    #convert geometries in hosps to shapely objects (from well-known-binary format received from postgis)
    for route in routes:
        for h in route:
            route[h]['geom'] = loads(a2b_hex(route[h]['geom'])) #postgis uses hex encoding, need to account for this
    #TODO: modify the following to create an array of key, multilinestring. In two steps? first create a multilinestring for each route, then
    #line can be as below
    #multiline the joined lines for each route
    #lines the container to hold them all.
        #create a new dict to hold our line features
        #initially contains key and empty dict as value
        #lines = dict((str(first)+"_"+str(second),{}) for first,second in grouper(list(route), 2))
        
        #add geometry and properties to lines dict
        #loop over every consecutive pair from input points
        #we can thus add attrs of both points, and create a line between them.
       # i = 1
       # for first, second in grouper(hospar, 2):
       #     for l in lines:
       #         if l == str(first)+"_"+str(second):
       #             #get x and y coords from shapely point objects   
       #             x1 = hosps[first]['geom'].x
       #             y1 = hosps[first]['geom'].y
       #             x2 = hosps[second]['geom'].x
       #             y2 = hosps[second]['geom'].y
       #             #create an item in lines with id and name of start/end hosps, and linestring geometry
       #             lines[l].update({
       #                 'start_id':first,
       #                 'start_name': hosps[first]['name'],
       #                 'end_id':second,
       #                 'end_name':hosps[second]['name'],
       #                 'order_id': i,
       #                 #here comes the new linestring geometry
       #                 'geom':LineString([(x1,y1),(x2,y2)]),
       #                 'line_id':l
       #                 #uses shapely LineString constructor with x,y coords of start and end points

       #                 # JBC: thought the following might work to add errors, but it couldn't serialize the output 
       #                 # 'geom':pylab.arrow(x1, y1, x2, y2, color='#999999', aa=True, head_width=1.0, head_length=1.0),
       #             })
       #     i+=1;       

    print routes
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
