#!/bin/bash

# Add new sites or upgrade them if they already exist. This script is idempotent.


# Default values
CREDENTIALS=praekeltdeploy:password
USER=www-data

# Parse arguments
while getopts "p:d:r:b:c:u:l:" opt; do
    case $opt in
        p)
            PREFIX=$OPTARG;;
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

if [[ -z "$PREFIX" || -z "$DEPLOY_TYPE" || -z "$OWNER_AND_REPO" || -z "$BRANCH" || -z "$CREDENTIALS" ]];
then
    echo "Usage: deploy-project.sh -p (prefix) -d (deploy_type) -r (repo) -b (branch) -c (credentials) [-u (user)]"
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
sudo rm -rf $WORKING_DIR
sudo -u $USER mkdir $WORKING_DIR

# Checkout / update repo to /tmp
cd /tmp
if [ -d $REPO ]; then
    cd $REPO
    sudo -u $USER git checkout $BRANCH
    sudo -u $USER git pull
else
    sudo -u $USER git clone -b $BRANCH https://${CREDENTIALS}@github.com/$REPO_OWNER/$REPO.git
fi

# Create database. Safe to run even if database already exists.
IS_NEW_DATABASE=0
DB_NAME=${PREFIX}_${DEPLOY_TYPE}
RESULT=`sudo -u postgres psql -l | grep ${DB_NAME}`
if [ "$RESULT" == "" ]; then
	echo "CREATE USER $DB_NAME WITH PASSWORD '$DB_NAME'" | sudo -u postgres psql
	echo "CREATE DATABASE $DB_NAME WITH OWNER $DB_NAME ENCODING 'UTF8' TEMPLATE template_postgis" | sudo -u postgres psql
	IS_NEW_DATABASE=1
fi

# Checkouts
DJANGO_SITE_INDEX=0
for f in `ls /tmp/${REPO}/${DEPLOY_TYPE}_*.cfg`
do
    FILENAME=$(basename $f)
    # ${DEPLOY_TYPE}_base_* and ${DEPLOY_TYPE}_constants_* files must be ignored.
    if [[ $FILENAME != *_base_*.cfg ]] && [[ $FILENAME != *_constants_*.cfg ]]; then

        # Calculate directory name. Also name of script.
        FTMP=${FILENAME%.*}
        THEDIR=$PREFIX-${FTMP//_/-}

        # Backup existing static directory if it exists
        sudo -u $USER mkdir -p ${DEPLOY_DIR}/static-backups
        if [ -d ${DEPLOY_DIR}/${THEDIR}/static ]; then
            STATIC_BACKUP=${DEPLOY_DIR}/static-backups/${THEDIR}/${ADATE}
            sudo -u $USER mkdir -p $STATIC_BACKUP
            sudo -u $USER cp -r ${DEPLOY_DIR}/${THEDIR}/static ${STATIC_BACKUP}/
        fi

        # Copy existing checkout
        cd ${WORKING_DIR}
        sudo -u $USER cp -r /tmp/${REPO} ${THEDIR}

        cd ${THEDIR}
        sudo chown -R $USER:$USER .git/

        # Always re-bootstrap in case of a new version of distribute
        # Try offline mode first. Download
        # python-distribute.org/distribute_setup.py to /var/www, and
        # https://pypi.python.org/packages/source/d/distribute/distribute-0.6.45.tar.gz
        # to /var/www/.buildout/downloads if they are not there.
        # todo: softcode
        #sudo -u $USER ${DEPLOY_DIR}/python/bin/python bootstrap.py -v 1.7.0 --distribute --setup-source=/var/www/distribute_setup.py --download-base=/var/www/.buildout/downloads --eggs=/var/www/.buildout/eggs
        #EXIT_CODE=$?
        #if [ $EXIT_CODE != 0 ]; then
        #    # Try online mode
        #    sudo -u $USER ${DEPLOY_DIR}/python/bin/python bootstrap.py -v 1.7.0 --distribute
        #fi

        # todo: distribute is deprecated and causing issues. Find offline equivalent for setuptools.
        sudo -u $USER ${DEPLOY_DIR}/python/bin/python bootstrap.py -v 1.7.0

        # Must use -i so buildout cache is used. That necessitates full paths as arguments.
        sudo -u $USER -i ${WORKING_DIR}/${THEDIR}/bin/buildout -Nv -c ${WORKING_DIR}/${THEDIR}/$FILENAME
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            echo "Buildout failure. Aborting."
            exit 1
        fi

        if [[ $FILENAME != *_common_*.cfg ]]; then

            # Database setup on first loop
            if [ $DJANGO_SITE_INDEX == 0 ]; then
                if [ $IS_NEW_DATABASE -eq 1 ]; then
                    read -p "Create a superuser if prompted. Do not generate default content. [enter]" y
                    sudo -u $USER ./bin/$THEDIR syncdb
    	        else
                    # Some Jmbo apps only got South migrations at a later stage. Scenarios:
                    # 1. CT not in DB - migrate
                    # 2. CT in DB, 0001 migration does not exist - fake migrate 0001
                    # 3. CT in DB, 0001 migration exists - migrate
                    FAKE_MIGRATE=""
                    for APP in competition music banner; do
                        RESULT=`sudo -u $USER ./bin/$THEDIR dumpdata contenttypes | grep "\"app_label\": \"$APP\""`
                        if [ "$RESULT" != "" ]; then
                            # CT is in DB. Now check for 0001 migration.
                            RESULT=`sudo -u $USER ./bin/$THEDIR dumpdata south | grep "\"app_name\": \"$APP\", \"migration\": \"0001_initial\""`
                            if [ "$RESULT" == "" ]; then
                                # Migration is not in db. Add to fake migrate list.
                                FAKE_MIGRATE="$FAKE_MIGRATE $APP"
                            fi
                        fi
                    done

	                sudo -u $USER ./bin/$THEDIR syncdb --noinput

                    # Apply fake migrations
                    for APP in $FAKE_MIGRATE; do
                        sudo -u $USER ./bin/$THEDIR migrate ${APP} 0001_initial --fake
                    done
                fi
                sudo -u $USER ./bin/$THEDIR migrate
                sudo -u $USER ./bin/$THEDIR load_photosizes
                sudo -u $USER ./bin/$THEDIR loaddata ${APP_NAME}/fixtures/sites.json
            fi

            sudo -u $USER rm -rf static
            sudo -u $USER ./bin/$THEDIR collectstatic --noinput

            # Cron entries
            # Skip over admin. Will be more elegant once we use celery for jobs.
            if [[ $FILENAME != *_admin_*.cfg ]]; then
                sudo rm /tmp/acron
                touch /tmp/acron
                sudo crontab -u $USER -l > /tmp/acron
                for COMMAND in report_naughty_words jmbo_publish; do
                    RESULT=`grep "${THEDIR} ${COMMAND}" /tmp/acron`
                    if [ "$RESULT" == "" ]; then
                        echo "0 * * * * ${DEPLOY_DIR}/${THEDIR}/bin/${THEDIR} ${COMMAND}" >> /tmp/acron
                    fi
                done
                sudo crontab -u $USER /tmp/acron
                rm /tmp/acron
            fi

            let DJANGO_SITE_INDEX++
        fi
    fi
done

# Delete pyc files. Replace occurrences of /tmp/praekelt with /var/praekelt.
# This sucks but is unavoidable since buildout interprets the directory from
# which it is executing. My bash-fu is not strong enough to make this more
# elegant.
sudo -u $USER find $WORKING_DIR -name "*.pyc" | sudo -u $USER xargs rm
for f in `find ${WORKING_DIR} -name "*.conf"`
do
    sudo -u $USER sed -i "s?${WORKING_DIR}?${DEPLOY_DIR}?g" $f
done
for f in `find ${WORKING_DIR} -name "*.cfg"`
do
    sudo -u $USER sed -i "s?${WORKING_DIR}?${DEPLOY_DIR}?g" $f
done
for f in `find ${WORKING_DIR} -type f -name "*" | grep /bin/`
do
    sudo -u $USER sed -i "s?${WORKING_DIR}?${DEPLOY_DIR}?g" $f
done

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
        if [ -d ${DEPLOY_DIR}/${f}/nginx ]; then
            sudo ln -s ${DEPLOY_DIR}/${f}/nginx/* /etc/nginx/sites-enabled/
        fi

        # Create supervisor symlinks if required
        if [ -d ${DEPLOY_DIR}/${f}/supervisor ]; then
            sudo ln -s ${DEPLOY_DIR}/${f}/supervisor/* /etc/supervisor/conf.d/
        fi
    fi
done

# Update supervisor
sudo supervisorctl update

# Restart memcached
sudo /etc/init.d/memcached restart

# Restart affected processes
for process in `sudo supervisorctl status | grep ${PREFIX}- | awk '{ print length(), $0 | "sort -n -r" }' | awk '{ print $2 }'`
do
    sudo supervisorctl restart $process
    sleep 1
done

# Reload nginx
sudo /etc/init.d/nginx reload
