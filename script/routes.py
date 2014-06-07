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

import sys
import psycopg2	#connect to postgresql databases
#import ppygis	#use postgis-specific types and convert them to python types
from shapely.wkb import dumps, loads	#manipulate geometries in python
from shapely.geometry import shape
from binascii import a2b_hex, b2a_hex
import geojson	#do geojson stuff
import pprint


def main():
    """
    main function
    """	
    #get hospital IDs from list file, create dict
    hospstring = ''
    hosps = {}
    try:
        arg = sys.argv[1]
        input_file = open(arg, 'r')
        line = input_file.readline()
        line = line.rstrip()
        hospstring = line #we'll need this later outside this scope
        ls = line.split(' ')
        ls = [int(i) for i in ls]
        hosps = dict((l,{}) for l in ls) #convert list to dict
    except:
        exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
        sys.exit('error reading from input file. Does it exist?'+str(exceptionValue)+str(exceptionTraceback))

    #fetch hospital records from database and update hosps dict with name, point geometry.

    #build postgresql connection string
    conn_string = "host='localhost' port='5432' dbname='geodrc' user='hans' password=''"
    #print the connection string we will use to connect
    print "Connecting to database\n    ->%s" % (conn_string)

    try:
        # get a connection, if a connect cannot be made an exception will be raised here
        conn = psycopg2.connect(conn_string)

        # conn.cursor will return a cursor object, you can use this cursor to perform queries
        cursor = conn.cursor()
        print "connection successful"
        
        #create query string with list of hospitals
        ls = hospstring.split(' ')
        qSelect = "SELECT name, hz_id, point from drc.hospitals WHERE hz_id IN ('"+ "','".join(ls)+"')"
        #execute query and fetch results
        cursor.execute(qSelect)
        sel = cursor.fetchall()
        print sel
        
        #update hosps dict with name and geometry
        for f in sel:
            for h in hosps:
                if f[1] == h:
                    hosps[h].update({'name':f[0],'geom':f[2]})
        print hosps
    except:
        # Get the most recent exception
        exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
        # Exit the script and print an error telling what happened.
        sys.exit("error\n ->%s" % (exceptionValue))

    #draw lines between consecutive pairs of points using shapely.
    #import geometries into python
    for h in hosps:
        g = loads(a2b_hex(hosps[h]['geom'])) #postgis uses hex encoding, need to account for this
        hosps[h]['geom'] = g
    print hosps #now has shapely objects instead of well-known binary strings from postgis

    #merge geometries and features

    #output as geojson

if __name__ == '__main__':
    sys.exit(main())
