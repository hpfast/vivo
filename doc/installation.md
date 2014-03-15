Software installation guide
===========================

The first thing we need is a spatial database which will allow us to store our data and modify it. We are going to use the PostgreSQL database with the PostGIS extension.


Steps:

1. download postgresql
2. install and configure postgresql
3. download/enable postgis extension
4. create a database with postgis extension

Note on versions: we are assuming PostgreSQL >= 9.1 and PostGIS >= 2.0.

Windows install. Note this is gathered from resources on the Internet and not first-hand experience -- additions and corrections are welcome. Furthermore, this is a summary of the main steps to take: for more detail see the linked resources at the bottom.

1. Download PostgreSQL
----------------------

Go to http://www.postgresql.org/download/ and follow the links to the installer for your operating system and architecture.


2. Install and configure PostgreSQL
-----------------------------------

Run the PostgreSQL installer you downloaded. You can optionally set some configuration settings regarding access policies now, but you can also change these later. For our purposes we will not be needing to set up external access so you can leave the connection settings as they are.

However, *note* that for exchange of data with other systems the encoding is important. If at all possible set it to *UTF-8.*

###user configuration

We want to create a user that can












Resources
---------

http://www.bostongis.com/PrinterFriendly.aspx?content_name=postgis_tut01
