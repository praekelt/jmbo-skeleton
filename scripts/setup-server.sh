#! /bin/bash

DEPLOY_DIR=/var/praekelt

echo "Prepare a clean Ubuntu 12.04 server to serve Jmbo sites"

# Default values
WEBDAV_PASSWORD=""
INSTALL_SENTRY=0

# Parse arguments
while getopts "p:s:" opt; do
    case $opt in
        p)
            WEBDAV_PASSWORD=$OPTARG;;
        s)
            INSTALL_SENTRY=$OPTARG;;
    esac
done


echo "Installing required Ubuntu packages..."
# Postgres is special. We want only one instance since Ubuntu will happily
# install different versions side by side.
sudo /etc/init.d/postgresql stop
sudo apt-get remove "postgresql-8.4"
sudo apt-get install python-virtualenv python-dev \
postgresql-9.1 libjpeg-dev zlib1g-dev build-essential git-core \
memcached supervisor nginx postgresql-server-dev-all libxslt1-dev \
libproj0 libproj-dev libgeos-3.2.2 libgdal1-dev libgeoip1 \
libgeoip-dev libgdal1-1.7.0 postgis postgresql-9.1-postgis haproxy unzip --no-upgrade

echo "Configuring PostgreSQL..."
# xxx: regexes would be better
sudo sed -i "s/local   all             all                                     peer/local   all             all                                     trust/" /etc/postgresql/9.1/main/pg_hba.conf
sudo /etc/init.d/postgresql restart

echo "Configuring PostGIS..."
sudo -u postgres createdb -E UTF8 template_postgis
sudo -u postgres createlang -d template_postgis plpgsql
sudo -u postgres psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='template_postgis';"
sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql -d template_postgis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
sudo -u postgres psql -d template_postgis -c "GRANT ALL ON geometry_columns TO PUBLIC;"
sudo -u postgres psql -d template_postgis -c "GRANT ALL ON spatial_ref_sys TO PUBLIC;"
sudo -u postgres psql -d template_postgis -c "GRANT ALL ON geography_columns TO PUBLIC;"

echo "Configuring nginx..."
# todo. Set max bucket size.
DIRNAME=`dirname $0`
sudo cp ${DIRNAME}/resources/50x.html /usr/share/nginx/www/
sudo cp ${DIRNAME}/resources/50x.png /usr/share/nginx/www/

echo "Setting up the www-data user..."
sudo mkdir /var/www
sudo mkdir /var/www/.buildout
sudo mkdir /var/www/.buildout/eggs
sudo mkdir /var/www/.buildout/downloads
sudo su -c 'echo "[buildout]" > /var/www/.buildout/default.cfg'
sudo su -c 'echo "eggs-directory = /var/www/.buildout/eggs" >> /var/www/.buildout/default.cfg'
sudo su -c 'echo "download-cache = /var/www/.buildout/downloads" >> /var/www/.buildout/default.cfg'
sudo chown -R www-data:www-data /var/www
sudo usermod www-data -s /bin/bash

if [ "$WEBDAV_PASSWORD" != "" ]; then
    sudo apt-get install apache2
    echo "Configuring Apache2 to serve Webdav..."
    sudo a2enmod dav_fs
    sudo a2enmod dav
    # Can't use port 80
    sudo sed -i "s/80/81/g" /etc/apache2/ports.conf
    sudo rm /etc/apache2/sites-enabled/default
    DIRNAME=`dirname $0`
    sudo cp ${DIRNAME}/resources/apache2-webdav.conf /etc/apache2/sites-enabled/000-default
    # Replace servername
    SERVERNAME=`sed "2q;d" /etc/hosts | awk '{print $2}'`
    sudo sed -i s/SERVERNAME/${SERVERNAME}/ /etc/apache2/sites-enabled/000-default
    sudo htpasswd -b -c /var/www/passwd.dav webdav $WEBDAV_PASSWORD
    sudo /etc/init.d/apache2 restart
fi

echo "Setting up the Django directory..."
sudo mkdir ${DEPLOY_DIR}
sudo virtualenv ${DEPLOY_DIR}/python --no-site-packages --setuptools
sudo mkdir ${DEPLOY_DIR}/log
sudo chown -R www-data:www-data ${DEPLOY_DIR}

# Install genshi and gunicorn library for virtualenv Python
sudo -u www-data ${DEPLOY_DIR}/python/bin/easy_install genshi
sudo -u www-data ${DEPLOY_DIR}/python/bin/easy_install gunicorn

# Sentry server
if [ $INSTALL_SENTRY != 0 ]; then
    # Own virtualenv because Sentry installs eggs in it
    sudo virtualenv ${DEPLOY_DIR}/python-sentry --no-site-packages
    sudo chown -R www-data:www-data ${DEPLOY_DIR}/python-sentry
    SENTRY_CONFIG=${DEPLOY_DIR}/sentry/sentry.conf.py
    sudo -u www-data ${DEPLOY_DIR}/python-sentry/bin/easy_install sentry
    sudo -u www-data ${DEPLOY_DIR}/python-sentry/bin/sentry init $SENTRY_CONFIG
    # Use our own conf file
    sudo -u www-data cp ${DIRNAME}/resources/sentry.conf.py $SENTRY_CONFIG
    # Replace secret key
    SECRET_KEY=`date +%s | sha256sum | head -c 56`
    sudo -u www-data sed -i "s/SECRET_KEY_PLACEHOLDER/${SECRET_KEY}/" $SENTRY_CONFIG
    sudo -u www-data ${DEPLOY_DIR}/python-sentry/bin/sentry --config=$SENTRY_CONFIG upgrade
    sudo cp ${DIRNAME}/resources/supervisor.sentry.conf /etc/supervisor/conf.d/sentry.conf
    sudo supervisorctl update
fi

# device-proxy
# Own virtualenv because device-proxy installs eggs in it
sudo virtualenv ${DEPLOY_DIR}/python-deviceproxy --no-site-packages
sudo chown -R www-data:www-data ${DEPLOY_DIR}/python-deviceproxy
sudo -u www-data ${DEPLOY_DIR}/python-deviceproxy/bin/pip install device-proxy
sudo rm /tmp/wurfl-2.1.zip
sudo rm /tmp/wurfl.xml
wget -O /tmp/wurfl-2.1.zip "http://mirror.transact.net.au/pub/sourceforge/w/project/wu/wurfl/WURFL/2.1.1/wurfl-2.1.zip"
unzip -o /tmp/wurfl-2.1.zip -d /tmp
sudo -u www-data ${DEPLOY_DIR}/python-deviceproxy/bin/wurfl2python.py -o ${DEPLOY_DIR}/python-deviceproxy/lib/python2.7/site-packages/devproxy/handlers/wurfl_handler/wurfl_devices.py /tmp/wurfl.xml
# Legacy (pre-pypi) requires this checkout. Directory changing required because git gets confused.
cd ${DEPLOY_DIR}
sudo -u www-data git clone https://github.com/praekelt/device-proxy.git
cd -
sudo -u www-data ${DEPLOY_DIR}/python-deviceproxy/bin/wurfl2python.py -o ${DEPLOY_DIR}/device-proxy/devproxy/handlers/wurfl_handler/wurfl_devices.py /tmp/wurfl.xml

echo ""
echo "All done! You probably want to run the deploy-project.sh script now."
if [ "$WEBDAV_PASSWORD" != "" ]; then
    echo "You can open a Webdav connection to $SERVERNAME on port 81 for the /praekelt folder. Username is webdav, password is $WEBDAV_PASSWORD."
fi
