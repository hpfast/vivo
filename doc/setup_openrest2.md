#Installing and configuring OpenResty/Nginx on Ubuntu 14.04

##Goal

This should guide you through installing Openresty and using its nginx to create an HTTP API for Postgresql.

We need to:

* download and install openresty with postgresql upstream support
* setup openresty nginx as a 'service' with init.d
* edit nginx's configuration file to create an API pointing to our database

## 1. Download and install Openresty

We need some dependencies, install them like this:

    sudo apt-get install libpq-dev libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make

If you don't have postgresql installed yet, you can get the required packages as followed (including postgis which we need for this project). Note in particular that libpq-dev is a requirement in both lists, we can't build openresty with the postgresql module unless we have it:

    sudo apt-get install postgresql postgresql-9.3-postgis-9.1 libpq5 libpq-dev

Find the latest openresty release from openresty.org/. Download it:

    wget http://openresty.org/download/ngx_openresty-1.7.4.1.tar.gz
    
extract it and enter the directory:

    tar -xzvf ngx_openresty-1.7.4.1.tar.gz
    cd ngx_openresty-1.7.4.1
    
configure the installation. We want to enable the postgresql module:

    ./configure --with-http_postgres_module
    
next, install.

    make
    sudo make install
    
That should be all you need to install openresty.

## 2. set up openresty's nginx as a service

Note: this method will cause 'nginx' to run with openresty's version, so if you have nginx installed already it will be bypassed. See below for an alternative.

Edit or create the init script for nginx. If `/etc/init.d/nginx` exists, move it to `/etc/init.d/nginx-old` or something. Then copy the openresty init.d script (in this repository at `/server/nginx/etc/openresty.init.d.script` or from <https://fzrxefe.googlecode.com/files/openresty.init.d.script>) to `/etc/init.d/nginx`. The PREFIX variable in this file needs to be `/usr/local/openresty/nginx` if you installed as in step 1.

Note: alternative if you want to prevent collision with existing nginx: just put this script at `/etc/init.d/openrestify` and use `openrestify` instead of `nginx` in service management commands.

To manage the service:

    sudo service nginx start|stop|restart|reload
    
Note that of course the two nginx's will need to listen on different ports, as specified in the configuration file, see next step.

## 3. Configure openresty/nginx to create a HTTP API for postgresql

We'll do everything in the main `nginx.conf` located at `/usr/local/openresty/nginx/conf/nginx.conf` -- you could of course put these directives in a virtual host file.

Here's the a complete configuration file, with comments below.

    worker_processes 8;

    events {}

    http {
      upstream database {
        postgres_server 127.0.0.1 dbname=postgres user=postgres password=postgres;
      }

      server {
        listen       8080;
        server_name  localhost;
        add_header Access-Control-Allow-Origin *;
        root /usr/local/openresty/nginx/html;

        # serve static files directly
        location ~* \.(?:jpg|jpeg|gif|css|png|js|ico)$ {
            access_log        off;
            expires           30d;
            add_header Pragma public;
            add_header Cache-Control "public";
            try_files $uri @fallback;
        }

        location  /routes {
          postgres_pass database;
          rds_json on;
          postgres_query HEAD GET "select *, to_json(route) from (select * from drc.routes order by route_id desc limit 6) as foo order by route_id";
          postgres_rewrite HEAD GET no_rows 410;
        }

        location ~ /routes/byid/(?<id>\d+) {
          postgres_pass database;
          rds_json on;
          postgres_escape $escaped_id $id;
          postgres_query HEAD GET "select * from drc.routes where route_id = $escaped_id";
          postgres_rewrite HEAD GET no_rows 410;
        }

        location ~ /routes/byrun/(?<id>\d+) {
          postgres_pass database;
          rds_json  on;
          postgres_escape $escaped_id $id;
          postgres_query HEAD GET "select a.*, b.run_id from drc.routes a, (select sol_id, run_id from drc.solutions b where run_id = $escaped_id) as b where a. sol_id = b.sol_id";
          postgres_rewrite HEAD GET no_rows 410;
          add_header Access-Control-Allow-Origin *;
        }
       location ~ /routes/byrun/latest {
          postgres_pass database;
          rds_json  on;
          postgres_query HEAD GET "select a.*, b.run_id from drc.routes a, (select sol_id, run_id from drc.solutions b where run_id = (select max(run_id) from drc.runs c) order by run_id desc limit 2) as b where a. sol_id = b.sol_id";
          postgres_rewrite HEAD GET no_rows 410;
          add_header Access-Control-Allow-Origin *;
        }
        location ~ /routes/bysolution/(?<id>\d+) {
          postgres_pass database;
          rds_json  on;
          postgres_escape $escaped_id $id;
          postgres_query HEAD GET "select * from drc.routes where sol_id = $escaped_id order by route_id";
          postgres_rewrite HEAD GET no_rows 410;
          add_header Access-Control-Allow-Origin *;
        }
      }
    }

We define an upstream for the postgresql database.

The server directive listens on port 8080 and the root is openresty's default public html directory.

For each endpoint on which users will be able to query, we define a location. Each location gets told about the database upstream, and turns on the rds_json module so we can serve json. The postgres_query parameter defines what query this will execute. Note the use of the id variable in some endpoints. We also create a rewrite to display an nginx error message when the database returns no rows. Finally we add an Allow-Origin header to enable cross-domain requests.

After making changes to nginx.conf, you need to reload it for the changes to take effect:

    sudo service nginx reload

If you get errors, it may be your database connection parameters are incorrect or postgresql is not configured to allow tcp/ip connections. Check nginx's error log at /usr/local/openresty/nginx/logs/error.log and if you see postgres stuff, make sure you have:

    host    all             all         all                trust

in /etc/postgresql/<version>/main/pg_hba.conf

and

    listen_addresses = *

in /etc/postgresql/<version>/main/postgresql.conf
    
These are insecure for production, but we're using these in a closed testing environment. More secure is to limit connection to localhost with:

    host    all             all             127.0.0.1/32            md5

in pg_hba.conf and

    listen_addresses = 'localhost, 127.0.0.1'
    
in postgresql.conf

Remember to reload postgresql after changing its configs:

    sudo service postgresql reload|restart


