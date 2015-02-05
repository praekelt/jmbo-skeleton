#!/bin/bash

# Add new sites or upgrade them if they already exist. This script is idempotent.


# Default values
CREDENTIALS=praekeltdeploy:password
USER=www-data

# Parse arguments
while getopts "d:r:b:c:u:l:" opt; do
    case $opt in
        d)
            DEPLOY_TYPE=$OPTARG;;
        r)
            OWNER_AND_REPO=$OPTARG;;
        b)
            BRANCH=$OPTARG;;
        c)
            CREDENTIALS=$OPTARG;;
        u)
            USER=$OPTARG;;
    esac
done

if [[ -z "$DEPLOY_TYPE" || -z "$OWNER_AND_REPO" || -z "$BRANCH" || -z "$CREDENTIALS" ]];
then
    echo "Usage: deploy-project.sh -d (deploy_type) -r (repo) -b (branch) -c (credentials) [-u (user)]"
    echo "Example: deploy-project.sh -p praekelt -d qa -r praekelt/jmbo-foo -b develop -c praekeltdeploy:mypassword"
    exit 1
fi

# Need this later
ADATE=`date +"%Y%m%dT%H%M"`

# Split OWNER_AND_REPO
INDEX=`expr index "$OWNER_AND_REPO" /`
REPO_OWNER=${OWNER_AND_REPO:0:(${INDEX}-1)}
REPO=${OWNER_AND_REPO:${INDEX}}

# Extract app name. Convention is repo has form jmbo-foo or jmbo.foo.
INDEX=`expr index "$REPO" [-.]`
APP_NAME=${REPO:${INDEX}}

# Compute deploy and working directory
DEPLOY_DIR=/var/${REPO_OWNER}
WORKING_DIR=/tmp/${REPO_OWNER}

# Ensure working directory is clean
#sudo rm -rf $WORKING_DIR
sudo -u $USER mkdir -p $WORKING_DIR

# Checkout / update repo to working directory
cd $WORKING_DIR
if [ -d $APP_NAME ]; then
    cd $APP_NAME
    sudo -u $USER git checkout $BRANCH
    sudo -u $USER git pull
else
    sudo -u $USER git clone -b $BRANCH https://${CREDENTIALS}@github.com/$REPO_OWNER/$REPO.git ${APP_NAME}
fi

# Create database. Safe to run even if database already exists.
IS_NEW_DATABASE=0
DB_NAME=$APP_NAME
RESULT=`sudo -u postgres psql -l | grep ${DB_NAME}`
if [ "$RESULT" == "" ]; then
	echo "CREATE USER $DB_NAME WITH PASSWORD '$DB_NAME'" | sudo -u postgres psql
    echo "CREATE DATABASE ${APP_NAME} WITH ENCODING 'UTF-8'" | sudo -u postgres psql
    echo "CREATE EXTENSION postgis" | sudo -u postgres psql ${APP_NAME}
    echo "CREATE EXTENSION postgis_topology" | sudo -u postgres psql ${APP_NAME}
	IS_NEW_DATABASE=1
fi

# Pip
cd /${WORKING_DIR}/${APP_NAME}
PIP_FILE=requirements.pip
DESIRED_PIP_FILE=requirements_${DEPLOY_TYPE}.pip
if [ -e "${DESIRED_PIP_FILE}" ]; then
    PIP_FILE=${DESIRED_PIP_FILE}
fi
sudo -u $USER ${DEPLOY_DIR}/python/bin/pip install -r ${PIP_FILE}
EXIT_CODE=$?
if [ $EXIT_CODE != 0 ]; then
    echo "Pip failure. Aborting."
    exit 1
fi

# Backup existing static directory if it exists
sudo -u $USER mkdir -p ${DEPLOY_DIR}/static-backups
if [ -d ${DEPLOY_DIR}/${APP_NAME}-static ]; then
    STATIC_BACKUP=${DEPLOY_DIR}/static-backups/${APP_NAME}/${ADATE}
    sudo -u $USER mkdir -p $STATIC_BACKUP
    sudo -u $USER cp -r ${DEPLOY_DIR}/${APP_NAME}-static ${STATIC_BACKUP}/
fi

# Database setup
DJANGO_MANAGE="${DEPLOY_DIR}/python/bin/python manage.py"
if [ $IS_NEW_DATABASE -eq 1 ]; then
    read -p "Create a superuser if prompted. Do not generate default content. [enter]" y
    sudo -u $USER $DJANGO_MANAGE syncdb --settings=project.settings_${DEPLOY_TYPE}_base
else
    # Some Jmbo apps only got South migrations at a later stage. Scenarios:
    # 1. Content type not in DB - normal migrate
    # 2. Content type in DB, 0001 migration does not exist - fake migrate 0001
    # 3. Content type in DB, 0001 migration exists - normal migrate
    FAKE_MIGRATE=""
    # Loop over apps. There is no way to query South if an app
    # has migrations so there will be some spam when attempting
    # to migrate non-South apps. It is perfectly safe. All this
    # can go away when http://south.aeracode.org/ticket/430 is
    # merged.
    for APP in `sudo -u $USER $DJANGO_MANAGE dumpdata contenttypes --indent=4 | grep app_label | awk -F'"' '{ print $4 }' | sort | uniq`; do
        RESULT=`sudo -u $USER $DJANGO_MANAGE dumpdata contenttypes | grep "\"app_label\": \"$APP\""`
        if [ "$RESULT" != "" ]; then
            # CT is in DB. Now check for 0001 migration.
            RESULT=`sudo -u $USER $DJANGO_MANAGE dumpdata south | grep "\"app_name\": \"$APP\", \"migration\": \"0001_initial\""`
            if [ "$RESULT" == "" ]; then
                # Migration is not in db. Add to fake migrate list.
                FAKE_MIGRATE="$FAKE_MIGRATE $APP"
            fi
        fi
    done

    sudo -u $USER $DJANGO_MANAGE syncdb --noinput --settings=project.settings_${DEPLOY_TYPE}_base

    # Apply fake migrations
    for APP in $FAKE_MIGRATE; do
        sudo -u $USER $DJANGO_MANAGE migrate ${APP} 0001_initial --fake
    done
fi
sudo -u $USER $DJANGO_MANAGE migrate --settings=project.settings_${DEPLOY_TYPE}_base
sudo -u $USER $DJANGO_MANAGE load_photosizes --settings=project.settings_${DEPLOY_TYPE}_base
sudo -u $USER $DJANGO_MANAGE loaddata ${APP_NAME}/fixtures/sites.json --settings=project.settings_${DEPLOY_TYPE}_base

# Static files. Settings file is quite hardcoded.
sudo -u $USER rm -rf static
sudo -u $USER $DJANGO_MANAGE collectstatic --noinput -v 0 --settings=project.settings_${DEPLOY_TYPE}_basic_site
sudo -u $USER $DJANGO_MANAGE collectstatic --noinput -v 0 --settings=project.settings_${DEPLOY_TYPE}_smart_site
sudo -u $USER $DJANGO_MANAGE collectstatic --noinput -v 0 --settings=project.settings_${DEPLOY_TYPE}_web_site

# Generate config files
sudo -u $USER ${DEPLOY_DIR}/python/bin/python scripts/generate-configs.py config.yaml

# Copy / move directories in working directory to deploy directory
for f in `ls $WORKING_DIR`
do
    # Delete target directories that contain source. The others (log, media etc are updated).
    if [[ $f == log ]] || [[ $f == *-media-* ]] || [[ $f == media-* ]]; then
        sudo -u $USER cp -r -u ${WORKING_DIR}/${f} $DEPLOY_DIR/
    else
        # Delete target if it exists
        if [ -d ${DEPLOY_DIR}/${f} ]; then
            sudo -u $USER rm -rf ${DEPLOY_DIR}/${f}
        fi
        sudo -u $USER mv ${WORKING_DIR}/${f} $DEPLOY_DIR/

        # Create nginx symlinks if required
        if [ -e ${DEPLOY_DIR}/${f}/conf/nginx.conf ]; then
            sudo ln -s ${DEPLOY_DIR}/${f}/conf/nginx.conf /etc/nginx/sites-enabled/${APP_NAME}.conf
        fi

        # Create supervisor symlinks if required
        if [ -e ${DEPLOY_DIR}/${f}/conf/supervisor.conf ]; then
            sudo ln -s ${DEPLOY_DIR}/${f}/conf/supervisor.conf /etc/supervisor/conf.d/${APP_NAME}.conf
        fi
    fi
done

# Update supervisor
sudo supervisorctl update

# Restart memcached
sudo /etc/init.d/memcached restart

# Restart affected processes
for process in `sudo supervisorctl status | grep ${APP_NAME}- | awk '{ print length(), $0 | "sort -n -r" }' | awk '{ print $2 }'`
do
    sudo supervisorctl restart $process
    sleep 1
done

# Reload nginx
sudo /etc/init.d/nginx reload
