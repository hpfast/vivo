following http://brian.akins.org/blog/2013/03/19/building-openresty-on-ubuntu/

adding postgresql stuff.

#sudo apt-get -y install make ruby1.9.1 ruby1.9.1-dev git-core \
libpcre3-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev unzip zip build-essential 

apt-get install libreadline-dev libpcre3-dev libssl-dev perl

sudo gem install fpm

apt-get install postgresql postgresql-9.3-postgis-9.1 libpq5 libpq-dev

wget http://openresty.org/download/ngx_openresty-1.7.4.1.tar.gz

tar -xzvf ngx_openresty-1.7.4.1.tar.gz

#the failing npm way from above tutorial

apt-get -y install make ruby1.9.1 ruby1.9.1-dev git-core \
libpcre3-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev unzip zip build-essential 

cd ngx_openresty-1.7.4.1

./configure \
--with-luajit \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-log-path=/var/log/nginx/access.log \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--lock-path=/var/lock/nginx.lock \
--pid-path=/var/run/nginx.pid \
--with-http_dav_module \
--with-http_flv_module \
--with-http_geoip_module \
--with-http_gzip_static_module \
--with-http_image_filter_module \
--with-http_realip_module \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_sub_module \
--with-http_xslt_module \
--with-ipv6 \
--with-sha1=/usr/include/openssl \
--with-md5=/usr/include/openssl \
--with-mail \
--with-mail_ssl_module \
--with-http_stub_status_module \
--with-http_secure_link_module \
--with-http_sub_module \
--with-http_postgres_module

make

DESTDIR=/tmp/openresty

make install DESTDIR=$DESTDIR

mkdir -p $INSTALL/var/lib/nginx

install -m 0555 -D nginx.init $INSTALL/etc/init.d/nginx

install -m 0555 -D nginx.logrotate $INSTALL/etc/logrotate.d/nginx

fpm -s dir -t deb -n nginx -v 1.7.4 --iteration 1 -C $INSTALL \
--description "openresty 1.7.4.1" \
-d libxslt1.1 \
-d libgd2-xpm \
-d libgeoip1 \
-d libpcre3 \
--config-files etc/nginx/fastcgi.conf.default \
--config-files /etc/nginx/win-utf \
--config-files /etc/nginx/conf.d/default.conf \
--config-files /etc/nginx/fastcgi_params \
--config-files /etc/nginx/nginx.conf \
--config-files /etc/nginx/koi-win \
--config-files /etc/nginx/nginx.conf.default \
--config-files /etc/nginx/mime.types.default \
--config-files /etc/nginx/koi-utf \
--config-files /etc/nginx/uwsgi_params \
--config-files /etc/nginx/uwsgi_params.default \
--config-files /etc/nginx/sites-available/default \
--config-files /etc/nginx/fastcgi_params.default \
--config-files /etc/nginx/mime.types \
--config-files /etc/nginx/scgi_params.default \
--config-files /etc/nginx/scgi_params \
--config-files /etc/nginx/fastcgi.conf \
etc usr var


#the way from openresty.org

make

make install

see 
http://blog.kerkerj.in/blog/2014/08/05/openresty-on-ubuntu-14-dot-04/

for an example of then setting up a demo.

And how do we create an init.d script to run as a service?
