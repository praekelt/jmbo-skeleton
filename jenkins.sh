#!/bin/sh

SITE_TYPE=basic

rm skeleton.db

rm -rf ve bin	
virtualenv --no-site-packages ve
ve/bin/python bootstrap.py

# We must do a custom build of pysqlite
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
cd ..

rm -rf src
./bin/buildout -v -c dev_${SITE_TYPE}_site.cfg

./bin/skeleton-dev-$SITE_TYPE-site syncdb --noinput
./bin/skeleton-dev-$SITE_TYPE-site migrate
./bin/skeleton-dev-$SITE_TYPE-site load_photosizes
./bin/skeleton-dev-$SITE_TYPE-site loaddata skeleton/fixtures/sites.json
rm -rf static
./bin/skeleton-dev-$SITE_TYPE-site collectstatic --noinput

# Checkout jmbo-foundry explicitly so we can run tests
git clone git@github.com:praekelt/jmbo-foundry.git src/jmbo-foundry
cd src/jmbo-foundry
../../bin/setuptest-runner setup.py test
cd -
