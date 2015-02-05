#!/bin/bash

if [ $# -ne 1 ]
then
    echo "Usage: `basename $0` [--no-setup-db|--setup-db]"
    exit 1
fi
DB_SETUP=$1

echo "Ensuring required system libraries are installed. You may be prompted for your password."
sudo apt-get install python-virtualenv python-dev \
libjpeg-dev zlib1g-dev build-essential git-core \
sqlite spatialite-bin --no-upgrade

if [ ! -d "ve" ]; then
    echo "Setting up sandboxed Python environment."
    rm -rf ve
    virtualenv ve
    ./ve/bin/pip install -r requirements.pip
fi

APP_NAME=${PWD##*/}

if [ ${DB_SETUP} == "--setup-db" ]
then
    ./ve/bin/python manage.py syncdb
    ./ve/bin/python manage.py migrate
    ./ve/bin/python manage.py load_photosizes
    ./ve/bin/python manage.py loaddata ${APP_NAME}/fixtures/sites.json
fi

if [ ${DB_SETUP} == "--no-setup-db" ]
then
	echo ""
	echo "Use the following command on a QA server to make a tarball of media files (by default only files less than 1 month old):"
	echo "find /path/to/${APP_NAME}-media-qa/ -type f -newerct `date --date "now -30 days" +"%Y-%m-%d"` | xargs -0 -d "\n" tar -cvf ~/${APP_NAME}-media.tar"
	echo ""
fi

echo "You may now start up the site with ./ve/bin/python manage.py runserver 0.0.0.0:8000"
echo "Browse to http://localhost:8000/ for the public site."
echo "Browse to http://localhost:8000/admin for the admin interface."
