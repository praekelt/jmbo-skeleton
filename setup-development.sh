#!/bin/bash

if [ $# -ne 3 ]
then
    echo "Usage: `basename $0` {app_name} {buildout_config} [--no-setup-db|--setup-db]"
    exit 1
fi

sudo apt-get install python-virtualenv python2.7-dev \
libjpeg-dev zlib1g-dev build-essential git-core \
sqlite3 libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev \
libgdal1-1.7.0 libspatialite3 spatialite-bin libgeoip1 libgeoip-dev --no-upgrade

echo "Setting up sandboxed Python environment with Python 2.7"
rm -rf ve bin
virtualenv --python=python2.7 --no-site-packages --setuptools ve

# We must do a custom build of pysqlite
ve/bin/pip install --no-install pysqlite==2.6.0
echo "[build_ext]\
    
#define=\
    
include_dirs=/usr/local/include\
    
library_dirs=/usr/local/lib\
    
libraries=sqlite3\
    
#define=SQLITE_OMIT_LOAD_EXTENSION" > ve/build/pysqlite/setup.cfg
ve/bin/pip install --no-download pysqlite==2.6.0

ve/bin/python bootstrap.py -v 1.7.0

APP_NAME=$1
BUILDOUT_CONFIG=$2
SITE=${BUILDOUT_CONFIG//_/-}
SITE=${SITE/\.cfg/}
DB_SETUP=$3

./bin/buildout -Nv -c $BUILDOUT_CONFIG

if [ ${DB_SETUP} == "--setup-db" ]
then
	read -p "Create a superuser when prompted. Do not generate default content. [enter]" y
	./bin/${APP_NAME}-$SITE syncdb
	spatialite ${APP_NAME}.db "SELECT InitSpatialMetaData();"
	./bin/${APP_NAME}-$SITE migrate
	./bin/${APP_NAME}-$SITE load_photosizes
	./bin/${APP_NAME}-$SITE loaddata ${APP_NAME}/fixtures/sites.json
fi
rm -rf static
./bin/${APP_NAME}-$SITE collectstatic --noinput

if [ ${DB_SETUP} == "--no-setup-db" ]
then
	echo ""
	echo "Use the following command on a QA server to make a tarball of media files (by default only files less than 1 month old):"
	echo "find /path/to/${APP_NAME}-media-qa/ -type f -newerct `date --date "now -30 days" +"%Y-%m-%d"` | xargs -0 -d "\n" tar -cvf ~/${APP_NAME}-media.tar"
	echo ""
fi

echo "You may now start up the site with ./bin/${APP_NAME}-$SITE runserver 0.0.0.0:8000"
echo "Browse to http://localhost:8000/ for the public site."
echo "Browse to http://localhost:8000/admin for the admin interface."
