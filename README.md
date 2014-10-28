vivo
====

setup, tools and documentation for preparing and visualising spatial data for modelling input/output

The name is just 'cause we need one -- 'short and memorable' per Github's recommendations. Probably stands for 'visualise input; visualise output' (with a processing step in between).

Todo: expand documentation of scope.

#Installing

clone the repository: `git clone https://github/com/hpfast/vivo`

`web` contains the html application. Copy or symlink this directory to a web-accessible location and instruct your web server to serve it.

`server` (TODO) contains a script to connect to your processing outputs. Currently it handles custom queries to a postgresql database. You could add more scripts for other kinds of backends, or replace this component entirely with any other backend.

#Frontend

in config.js, edit the url for your backend.

##user-assets

stuff specific to your application goes here. (e.g. background map layers)

#Backend

in config.py, edit the connection parameters for your database.

