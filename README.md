vivo
====

setup, tools and documentation for preparing and visualising spatial data for modelling input/output

The name is just 'cause we need one -- 'short and memorable' per Github's recommendations. Probably stands for 'visualise input; visualise output' (with a processing step in between).

Todo: expand documentation of scope.

#Installing

clone the repository: `git clone https://github/com/hpfast/vivo`

`web` contains the html application. Copy or symlink this directory to a web-accessible location and instruct your web server to serve it.

`server` (TODO) contains a script to connect to your processing outputs. Currently it handles custom queries to a postgresql database. You could add more scripts for other kinds of backends, or replace this component entirely with any other backend.

For the server backend you can choose from:

* postgresql-http-server (nodejs)

##postgresql-http-server (nodejs)

depends: [postgresql-http-server](https://github.com/bjornharrtell/postgresql-http-server)

`postgresql-http-server` is working but the code is a tad unmaintained and the suggested `npm` installation method didn't work for me. I don't know much about how to fix that, but I had success running the code directly on Ubuntu 14.04 and Debian unstable (2014):

    sudo apt-get update
    sudo apt-get install git npm nodejs coffeescript
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    git clone https://github.com/bjornharrtell/postgresql-http-server
    cd postgresql-http-server
    npm install
    
You can now run `postgresql-http-server` from the clone directory with:

    .bin/postgresql-http-server --database DATABASE --user USER --raw --cors
    
where --cors enables Cross-origin requests and --raw enables POSTing SQL to the API. See its readme for more information.


#Frontend

in config.js, edit the url for your backend.

##user-assets

stuff specific to your application goes here. (e.g. background map layers)

#Backend

in config.py, edit the connection parameters for your database.

