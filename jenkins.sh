#!/bin/sh

# The following libraries must be installed on Ubuntu 12.04 for Jenkins to
# function:
# libjpeg-dev zlib1g-dev build-essential git-core libsqlite3-dev libxslt1-dev
# libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev libgeoip1 libgeoip-dev
# libgdal1-1.7.0 unzip

rm test.db

rm -rf ve bin	
virtualenv --no-site-packages ve
ve/bin/python bootstrap.py -v 1.7.0 --distribute

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

# Loop over all applicable buildouts
for f in `ls /tmp/${REPO}/${DEPLOY_TYPE}_*.cfg`
do
    if [[ $FILENAME != *_base_*.cfg ]] && [[ $FILENAME != *_constants_*.cfg ]] && [[ $FILENAME != buildout.cfg ]] && [[ $FILENAME != versions.cfg ]]; then
        ./bin/buildout -Nv -c $f
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            echo "Buildout failure. Aborting."
            exit 1
        fi
    fi
done

# If this product is jmbo-skeleton itself then run jmbo-foundry tests, else run
# product tests.
if [ -d "skeleton" ]; then
    git clone git@github.com:praekelt/jmbo-foundry.git src/jmbo-foundry
    cd src/jmbo-foundry
    ../../bin/setuptest-runner setup.py test
else
    ./bin/setuptest-runner setup.py test
fi
