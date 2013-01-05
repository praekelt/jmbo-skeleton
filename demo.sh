#!/bin/bash

echo "The demo app checks out code from github and uses sqlite as backend. Installation is confined to this directory."
echo "Choose the Python version to use:"
choice=3
echo "1. 2.6"
echo "2. 2.7"
while [ $choice -eq 3 ]; do
    read choice
    read -p "Installing required libraries. You may be prompted for a password. [enter]" y
    if [ $choice -eq 1 ] ; then
	    if [ -f ./ve/bin/python2.7 ];
	    then
            sudo rm -rf ve bin
        else
            # Distribute and bootstrap sometimes have version conflicts. Delete.
            sudo rm -rf ve/lib/python2.6/site-packages/distribute*
	    fi
        sudo apt-get install python-virtualenv python2.6-dev \
	    libjpeg62-dev zlib1g-dev build-essential git-core \
        sqlite3 libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev \
        libgdal1-1.7.0 libspatialite3 spatialite-bin libgeoip1 libgeoip-dev --no-upgrade
    	echo "Setting up sandboxed Python environment with Python 2.6"
	    virtualenv --python=python2.6 --no-site-packages ve
    else
	    if [ -f ./ve/bin/python2.6 ];
    	then
            sudo rm -rf ve bin
        else
            # Distribute and bootstrap sometimes have version conflicts. Delete.
            sudo rm -rf ve/lib/python2.7/site-packages/distribute*
    	fi
	    sudo apt-get install python-virtualenv python2.7-dev \
    	libjpeg-dev zlib1g-dev build-essential git-core \
        sqlite3 libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev \
        libgdal1-1.7.0 libspatialite3 spatialite-bin libgeoip1 libgeoip-dev --no-upgrade
	    echo "Setting up sandboxed Python environment with Python 2.7"
    	virtualenv --python=python2.7 --no-site-packages ve
    fi
done

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
ve/bin/python bootstrap.py
echo "Choose the type of demo site:"
choice=4
echo "1. Basic (mobi for low-end and mid handsets)"
echo "2. Smart (mobi for smart handsets)"
echo "3. Web"
SITE_TYPE=basic
while [ $choice -eq 4 ]; do
    read choice
    if [ $choice -eq 1 ] ; then
        read -p "This part may take a while. If it fails with 'connection reset by peer' run ./demo again. [enter]" y
        ./bin/buildout -Nv -c dev_basic_site.cfg
    elif [ $choice -eq 2 ] ; then
        read -p "This part may take a while. If it fails with 'connection reset by peer' run ./demo again. [enter]" y
        ./bin/buildout -Nv -c dev_smart_site.cfg
        SITE_TYPE=smart
    else
        read -p "This part may take a while. If it fails with 'connection reset by peer' run ./demo again. [enter]" y
        ./bin/buildout -Nv -c dev_web_site.cfg
        SITE_TYPE=web
    fi
done

# Remove stale database
if [ -f skeleton.db ];
then
    rm skeleton.db
fi

read -p "Create a superuser when prompted. Do not generate default content. [enter]" y
./bin/skeleton-dev-$SITE_TYPE-site syncdb
spatialite skeleton.db "SELECT InitSpatialMetaData();"
./bin/skeleton-dev-$SITE_TYPE-site migrate
./bin/skeleton-dev-$SITE_TYPE-site load_photosizes
./bin/skeleton-dev-$SITE_TYPE-site loaddata skeleton/fixtures/sites.json
rm -rf static
./bin/skeleton-dev-$SITE_TYPE-site collectstatic --noinput

echo "You may now start up the site with ./bin/skeleton-dev-$SITE_TYPE-site runserver 0.0.0.0:8000"
echo "Browse to http://localhost:8000/ for the public site."
echo "Browse to http://localhost:8000/admin for the admin interface."
