#! /bin/bash

DEPLOY_DIR=/var/praekelt

echo "Prepare a clean Ubuntu 12.04 server to serve Jmbo sites"

# Parse arguments
while getopts "p:" opt; do
    case $opt in
        p)
            WEBDAV_PASSWORD=$OPTARG;;
    esac    
done

if [[ -z "$WEBDAV_PASSWORD" ]];
then
    echo "Usage: setup-server.sh -p (webdav_password)"
    echo "Example: setup-server.sh -p new_password"
    exit 1
fi

echo "Installing required Ubuntu packages..."
# Postgres is special. We want only one instance since Ubuntu will happily 
# install different versions side by side.
sudo /etc/init.d/postgresql stop
sudo apt-get remove "postgresql-8.4"
sudo apt-get --no-upgrade install python-virtualenv python-dev \
postgresql-9.1 libjpeg-dev zlib1g-dev build-essential git-core \
memcached supervisor nginx postgresql-server-dev-all libxslt1-dev \
apache2 --no-upgrade

echo "Configuring PostgreSQL..."
# xxx: regexes would be better
sudo sed -i "s/local   all             all                                     peer/local   all             all                                     trust/" /etc/postgresql/9.1/main/pg_hba.conf
sudo /etc/init.d/postgresql restart

echo "Configuring nginx..."
# todo. Set max bucket size.

echo "Setting up the www-data user..."
sudo mkdir /var/www
sudo mkdir /var/www/.buildout
sudo mkdir /var/www/.buildout/eggs
sudo su -c 'echo "[buildout]" > /var/www/.buildout/default.cfg'
sudo su -c 'echo "eggs-directory = /var/www/.buildout/eggs" >> /var/www/.buildout/default.cfg'
sudo chown -R www-data:www-data /var/www
sudo usermod www-data -s /bin/bash

echo "Configuring Apache2 to serve Webdav..."
sudo a2enmod dav_fs
sudo a2enmod dav
# Can't use port 80
sudo sed -i "s/80/81/g" /etc/apache2/ports.conf 
sudo rm /etc/apache2/sites-enabled/default
DIRNAME=`dirname $0`
sudo cp ${DIRNAME}/apache2-webdav.conf /etc/apache2/sites-enabled/000-default
# Replace servername
SERVERNAME=`sed "2q;d" /etc/hosts | awk '{print $2}'`
sudo sed -i s/SERVERNAME/${SERVERNAME}/ /etc/apache2/sites-enabled/000-default
sudo htpasswd -b -c /var/www/passwd.dav webdav $WEBDAV_PASSWORD
sudo /etc/init.d/apache2 restart

echo "Setting up the Django directory..."
sudo mkdir ${DEPLOY_DIR}
sudo virtualenv ${DEPLOY_DIR}/python --no-site-packages
sudo chown -R www-data:www-data ${DEPLOY_DIR}

echo ""
echo "All done! You probably want to run the deploy-project.sh script now."
echo "You can open a Webdav connection to $SERVERNAME on port 81 for the /praekelt folder. Username is webdav, password is $WEBDAV_PASSWORD."
