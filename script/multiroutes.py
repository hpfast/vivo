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
