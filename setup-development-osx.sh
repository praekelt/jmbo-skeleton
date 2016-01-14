#!/bin/bash
brew install gdal
brew install libgeoip

echo "Setting up sandboxed Python environment."
rm -rf ve
virtualenv ve
./ve/bin/pip install -r requirements.txt

APP_NAME=${PWD##*/}

./ve/bin/python manage.py syncdb
./ve/bin/python manage.py migrate
./ve/bin/python manage.py load_photosizes
./ve/bin/python manage.py loaddata ${APP_NAME}/fixtures/sites.json

echo "You may now start up the site with ./ve/bin/python manage.py runserver 0.0.0.0:8000"
echo "Browse to http://localhost:8000/ for the public site."
echo "Browse to http://localhost:8000/admin for the admin interface."
