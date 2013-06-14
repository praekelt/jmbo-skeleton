#!/bin/sh

SITE_TYPE=basic

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

rm -rf src
./bin/buildout -Nv -c dev_${SITE_TYPE}_site.cfg
EXIT_CODE=$?
if [ $EXIT_CODE != 0 ]; then
    echo "Buildout failure. Aborting."
    exit 1
fi

# If this product is jmbo-skeleton itself then run jmbo-foundry tests, else run
# product tests.
if [ -d "skeleton" ]; then
    git clone git@github.com:praekelt/jmbo-foundry.git src/jmbo-foundry
    cd src/jmbo-foundry
    ../../bin/setuptest-runner setup.py test
else
    ./bin/setuptest-runner setup.py test
fi
