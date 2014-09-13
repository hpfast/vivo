#!/usr/bin/python

"""
SUMMARY

Given ordered list of hospital IDs as input, returns their point geometries with their route order as label and routes between them as linestrings (in GeoJSON geometrycollection).

USAGE

This is a demo so accepted input is very limited. Invoke as:

    routes.py LISTFILE
    
where listfile is a plain text file with a single line, containing hospital IDs in order separated by spaces, e.g.:

    143 128 129 100 46
    
Writes a single file routes.geojson.

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
    
    #get hospital IDs from list file, create dict
    #we'll also need a string and an array for iteration
    hospstring = ''
    hospar = []
    hosps = {}
    try:
        arg = sys.argv[1]
        input_file = open(arg, 'r')
        line = input_file.readline()
        line = line.rstrip()
        hospstring = line #we'll need this later outside this scope
        ls = line.split(' ')
        ls = [int(i) for i in ls]
        hospar = ls
        hosps = dict((l,{}) for l in ls) #convert list to dict
    except:
        exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
        sys.exit('error reading from input file. Does it exist?'+str(exceptionValue)+str(exceptionTraceback))


    # ---------------------------
    # FETCH RECORDS FROM DATABASE
    # ---------------------------
    
    #fetch hospital records from database and update hosps dict with name, geometry.

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
        
        #create query string with list of hospitals
        ls = hospstring.split(' ')
        qSelect = "SELECT name, hz_id, point from drc.hospitals WHERE hz_id IN ('"+ "','".join(ls)+"')"
        #execute query and fetch results
        cursor.execute(qSelect)
        sel = cursor.fetchall()
        
        #update hosps dict with name and geometry from db selection
        for f in sel:
            for h in hosps:
                if f[1] == h: #we match on hz_id
                    hosps[h].update({'name':f[0],'geom':f[2]}) #geom is still well-known binary format here
                    print hosps[h]
    except:
        # Get the most recent exception
        exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
        # Exit the script and print an error telling what happened.
        sys.exit("error\n ->%s" % (exceptionValue))

    # -------------------------------------
    # DRAW LINES BETWEEN CONSECUTIVE POINTS
    # -------------------------------------
    
    #convert geometries in hosps to shapely objects (from well-known-binary format received from postgis)
    for h in hosps:
        hosps[h]['geom'] = loads(a2b_hex(hosps[h]['geom'])) #postgis uses hex encoding, need to account for this

    #create a new dict to hold our line features
    #initially contains key and empty dict as value
    lines = dict((str(first)+"_"+str(second),{}) for first,second in grouper(hospar, 2))
    
    #add geometry and properties to lines dict
    #loop over every consecutive pair from input points
    #we can thus add attrs of both points, and create a line between them.
    i = 1
    for first, second in grouper(hospar, 2):
        for l in lines:
            if l == str(first)+"_"+str(second):
                #get x and y coords from shapely point objects   
                x1 = hosps[first]['geom'].x
                y1 = hosps[first]['geom'].y
                x2 = hosps[second]['geom'].x
                y2 = hosps[second]['geom'].y
                #create an item in lines with id and name of start/end hosps, and linestring geometry
                lines[l].update({
                    'start_id':first,
                    'start_name': hosps[first]['name'],
                    'end_id':second,
                    'end_name':hosps[second]['name'],
                    'order_id': i,
                    #here comes the new linestring geometry
                    'geom':LineString([(x1,y1),(x2,y2)]),
                    'line_id':l
                    #uses shapely LineString constructor with x,y coords of start and end points

                    # JBC: thought the following might work to add errors, but it couldn't serialize the output 
                    # 'geom':pylab.arrow(x1, y1, x2, y2, color='#999999', aa=True, head_width=1.0, head_length=1.0),
                })
        i+=1;       
                 
    # ------------            
    # GEOJSONIFY
    # ------------
    
    #list to hold features
    col = []
    
    #create a geojson Feature out of every item in lines
    for r in lines:
        feature = geojson.Feature(
            geometry=lines[r]['geom'],
            id=r,
            properties = {k: v for k, v in lines[r].iteritems() if k != 'geom'} #everything not geom goes in props
        ) 
        col.append(feature)
    
    #make all features into a featurecollection
    collection = geojson.FeatureCollection(col)
    print "HERE COMES THE COLLECTION"
    print geojson.dumps(collection)
    
    #order is in order_id key.
 
    #write featurecollection to file
    print os.path.normpath(config['output_path'])+'lines.geojson'
    with open(os.path.normpath(config['output_path']) + '/lines.geojson', 'w') as outfile:
        outfile.write(geojson.dumps(collection))
    outfile.close()
    print "wrote features\n"
    
    
#helper function from stackoverflow to iterate consecutive pairs
def grouper(input_list, n = 2):
    for i in xrange(len(input_list) - (n - 1)):
        yield input_list[i:i+n]

if __name__ == '__main__':
    sys.exit(main())
