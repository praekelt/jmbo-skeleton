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
	    libjpeg-dev zlib1g-dev build-essential git-core \
        sqlite3 libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev \
        libgdal1-1.7.0 libspatialite3 spatialite-bin --no-upgrade
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
    	libjpeg62-dev zlib1g-dev build-essential git-core \
        sqlite3 libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev \
        libgdal1-1.7.0 libspatialite3 spatialite-bin --no-upgrade
	    echo "Setting up sandboxed Python environment with Python 2.7"
    	virtualenv --python=python2.7 --no-site-packages ve
    fi
done

: <<'END'
# GeoDjango libs. Inspired by https://docs.djangoproject.com/en/dev/ref/contrib/gis/install/.
read -p "Your system may already be capable of supporting a spatial SQLite database. Should I install the required libraries? If unsure answer 'y'.(y/n)? "
if [ $REPLY == "y" ]; then
    wget http://download.osgeo.org/geos/geos-3.3.0.tar.bz2
    tar xjf geos-3.3.0.tar.bz2
    cd geos-3.3.0
    ./configure
    make
    sudo make install
    cd ..
    wget http://download.osgeo.org/proj/proj-4.7.0.tar.gz
    wget http://download.osgeo.org/proj/proj-datumgrid-1.5.zip
    tar xzf proj-4.7.0.tar.gz
    cd proj-4.7.0/nad
    unzip ../../proj-datumgrid-1.5.zip
    cd ..
    ./configure
    make
    sudo make install
    cd ..
    wget http://download.osgeo.org/gdal/gdal-1.9.1.tar.gz
    tar xzf gdal-1.9.1.tar.gz
    cd gdal-1.9.1
    ./configure
     make # Go get some coffee, this takes a while.
    sudo make install
    cd ..
    wget http://sqlite.org/sqlite-amalgamation-3.6.23.1.tar.gz
    tar xzf sqlite-amalgamation-3.6.23.1.tar.gz
    cd sqlite-3.6.23.1
    CFLAGS="-DSQLITE_ENABLE_RTREE=1" ./configure
    make
    sudo make install
    cd ..
    wget http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-amalgamation-2.4.0-5.tar.gz
    wget http://www.gaia-gis.it/gaia-sins/spatialite-tools-sources/spatialite-tools-2.4.0-5.tar.gz
    tar xzf libspatialite-amalgamation-2.4.0-5.tar.gz
    tar xzf spatialite-tools-2.4.0-5.tar.gz
    cd libspatialite-amalgamation-2.4.0
    ./configure # May need to modified, see notes below.
    make
    sudo make install
    cd ..
    cd spatialite-tools-2.4.0
    ./configure # May need to modified, see notes below.
    make
    sudo make install
    cd ..
    wget http://pysqlite.googlecode.com/files/pysqlite-2.6.0.tar.gz
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
fi
END

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

# Convert the app to South. This cannot be done in advance.
#rm skeleton/migrations/*.py
#rm skeleton/migrations/*.pyc
#./bin/skeleton-dev-$SITE_TYPE-site convert_to_south skeleton
## Add in a migration dependency on Foundry.
#MIGRATION=`./bin/skeleton-dev-$SITE_TYPE-site get_last_foundry_migration`
#sed -i s/"class Migration(SchemaMigration):"/"class Migration(SchemaMigration):\n    depends_on = (('foundry', '${MIGRATION}'),)"/ skeleton/migrations/0001_initial.py
#./bin/skeleton-dev-$SITE_TYPE-site migrate

./bin/skeleton-dev-$SITE_TYPE-site load_photosizes
./bin/skeleton-dev-$SITE_TYPE-site loaddata skeleton/fixtures/sites.json
rm -rf static
./bin/skeleton-dev-$SITE_TYPE-site collectstatic --noinput

echo "You may now start up the site with ./bin/skeleton-dev-$SITE_TYPE-site runserver 0.0.0.0:8000"
echo "Browse to http://localhost:8000/ for the public site."
echo "Browse to http://localhost:8000/admin for the admin interface."
