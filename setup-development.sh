#!/bin/bash

if [ $# -ne 2 ]
then
    echo "Usage: `basename $0` {app_name} {buildout_config}"
    exit 1
fi

# Distribute and bootstrap sometimes have version conflicts. Delete.
sudo rm -rf ve/lib/python2.7/site-packages/distribute*
sudo apt-get install python-virtualenv python2.7-dev \
libjpeg-dev zlib1g-dev build-essential git-core \
sqlite3 libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev \
libgdal1-1.7.0 libspatialite3 spatialite-bin libgeoip1 libgeoip-dev --no-upgrade
echo "Setting up sandboxed Python environment with Python 2.7"
virtualenv --python=python2.7 --no-site-packages ve

# We must do a custom build of pysqlite
if [ ! -f pysqlite-2.6.0.tar.gz ]; then
    wget http://pysqlite.googlecode.com/files/pysqlite-2.6.0.tar.gz
fi
tar xzf pysqlite-2.6.0.tar.gz
cd pysqlite-2.6.0
echo "[build_ext]\
    
#define=\
    
include_dirs=/usr/local/include\
    
library_dirs=/usr/local/lib\
    
libraries=sqlite3\
    
#define=SQLITE_OMIT_LOAD_EXTENSION" > setup.cfg
../ve/bin/python setup.py install
sudo /sbin/ldconfig
cd ..

echo "Downloading distribute"
ve/bin/python bootstrap.py -v 1.7.0

APP_NAME=$1
BUILDOUT_CONFIG=$2
SITE=${BUILDOUT_CONFIG//_/-}
SITE=${SITE/\.cfg/}

./bin/buildout -Nv -c $BUILDOUT_CONFIG

read -p "Create a superuser when prompted. Do not generate default content. [enter]" y
./bin/${APP_NAME}-$SITE syncdb
spatialite ${APP_NAME}.db "SELECT InitSpatialMetaData();"
./bin/${APP_NAME}-$SITE migrate
./bin/${APP_NAME}-$SITE load_photosizes
./bin/${APP_NAME}-$SITE loaddata ${APP_NAME}/fixtures/sites.json
rm -rf static
./bin/${APP_NAME}-$SITE collectstatic --noinput

echo "You may now start up the site with ./bin/${APP_NAME}-$SITE runserver 0.0.0.0:8000"
echo "Browse to http://localhost:8000/ for the public site."
echo "Browse to http://localhost:8000/admin for the admin interface."
