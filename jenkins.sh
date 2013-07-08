#!/bin/bash

# The following libraries must be installed on Ubuntu 12.04 for Jenkins to
# function:
# libjpeg-dev zlib1g-dev build-essential git-core libsqlite3-dev libxslt1-dev
# libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev libgeoip1 libgeoip-dev
# libgdal1-1.7.0 unzip

# Create the PostgreSQL user:
# create user test with password '';
# alter user test createdb;

rm -rf ve bin
virtualenv --no-site-packages ve
ve/bin/python bootstrap.py -v 1.7.0 --distribute
ve/bin/easy_install genshi
ve/bin/easy_install gunicorn

# Loop over all applicable buildouts
for f in `ls *_*_*.cfg`; do
    if [[ $f != *_base_*.cfg ]] && [[ $f != *_constants_*.cfg ]]; then
        echo "Buildout of file $f"
        ./bin/buildout -Nv -c $f
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            echo "Buildout failure. Aborting."
            exit 1
        fi
        # Hack required because (1) existing bin/setuptest-runner is removed if
        # the file does not declare that section and (2) django-setuptestrunner
        # has an idempotency bug.
        if [ -f bin/setuptest-runner ]; then
            mv bin/setuptest-runner .
        fi
    fi
done

# Restore setuptest-runner
cp setuptest-runner bin/

# If this product is jmbo-skeleton itself then run jmbo-foundry tests, else run
# product tests.
if [ -d "skeleton" ]; then
    # Bug in django-setuptest means database foundry must exist, even though it
    # is not used.
    psql -U test -d template1 -c "CREATE DATABASE foundry WITH OWNER test ENCODING 'UTF8' TEMPLATE template_postgis;"
    psql -U test -d template1 -c "DROP DATABASE test_foundry;"

    rm -rf src/jmbo-foundry
    git clone git@github.com:praekelt/jmbo-foundry.git src/jmbo-foundry
    cd src/jmbo-foundry
    ../../bin/setuptest-runner setup.py test
else
    ONE_LAYER_FAILED=0
    # Test all layers
    for layers in "('basic',)" "('smart', 'basic')" "('web', 'basic')"; do
        echo ""
        echo "****************************************************************"
        echo "TESTING LAYERS $layers"
        echo "****************************************************************"
        # Until django-setuptest can take a settings file as parameter hack the
        # test_settings.py file.
        sed -i '$d' test_settings.py
        echo "FOUNDRY['layers'] = ${layers}" >> test_settings.py
        # Bug in django-setuptest means database db_name must exist, even
        # though it is not used.
        psql -U test -d template1 -c "CREATE DATABASE db_name WITH OWNER test ENCODING 'UTF8' TEMPLATE template_postgis;"
        psql -U test -d template1 -c "DROP DATABASE test_db_name;"
        ./bin/setuptest-runner setup.py test
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            ONE_LAYER_FAILED=1
        fi
    done
    if [ $ONE_LAYER_FAILED == 1 ]; then
        echo "Tests failed for at least one layer. See the log."
        exit 1
    fi
fi
