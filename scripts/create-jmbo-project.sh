#! /bin/bash

# Will move to Genshi templates in future

# Defaults
SITE=site
PORT=90
CREATE_DIR=/tmp

# Prompt for params
echo -n "Egg name, eg. jmbo-myapp. It MUST have this form. [enter]: "
read EGG
#echo -n "Django app name, eg. myapp. [enter]: "
#read APP
echo -n "Site name, eg. ghana. This is useful if you have different sites forming a logical whole, eg. a site per country. (default=site) [enter]: "
read asite
if [ -n "$asite" ];
then
    SITE=$asite
fi
echo -n "Port base. Service ports are offset from this port. (default=90) [enter]: "
read aport
if [ -n "$aport" ];
then
    PORT=$aport
fi
echo -n "Source code directory. (default=/tmp) [enter]: "
read adir
if [ -n "$adir" ];
then
    CREATE_DIR=$adir
fi

# Extract app name. Convention is repo has form jmbo-foo or jmbo.foo.
INDEX=`expr index "$EGG" [-.]`
APP=${EGG:${INDEX}}

# Create the project
PROJECT_DIR=${CREATE_DIR}/${APP}
APP_DIR=${PROJECT_DIR}/${APP}
mkdir $PROJECT_DIR

# Copy requisite bits
cp .gitignore ${PROJECT_DIR}/
cp setup.py ${PROJECT_DIR}/
cp requirements.txt ${PROJECT_DIR}/
cp setup-development.sh ${PROJECT_DIR}/
cp handler.py ${PROJECT_DIR}/
cp deviceproxy.yaml.in ${PROJECT_DIR}/deviceproxy_${SITE}.yaml
cp config.yaml.in ${PROJECT_DIR}/config.yaml
cp test_settings.py ${PROJECT_DIR}/
cp manage.py ${PROJECT_DIR}/
cp wsgi.py ${PROJECT_DIR}/
cp MANIFEST.in ${PROJECT_DIR}/
cp tox.ini ${PROJECT_DIR}/
cp .travis.yml ${PROJECT_DIR}/
touch ${PROJECT_DIR}/AUTHORS.rst
touch ${PROJECT_DIR}/CHANGELOG.rst
touch ${PROJECT_DIR}/README.rst
cp -r scripts ${PROJECT_DIR}/
cp -r project ${PROJECT_DIR}/
cp -r fed ${PROJECT_DIR}/
cp -r conf ${PROJECT_DIR}/
cp -r skeleton ${PROJECT_DIR}/${APP}

# Delete pyc files
find ${PROJECT_DIR} -name "*.pyc" | xargs rm

# Create the settings files. First delete the existing ones, then copy and rename.
rm ${PROJECT_DIR}/project/settings_*_site.*
for f in project/settings_*.py; do
    F=$(basename $f)
    cp $f ${PROJECT_DIR}/project/${F/site/${SITE}};
done

# Change strings in the newly copied source
sed -i s/name=\'jmbo-skeleton\'/name=\'${EGG}\'/ ${PROJECT_DIR}/setup.py
sed -i "s/PORT_PREFIX_PLACEHOLDER/${PORT}/g" ${PROJECT_DIR}/deviceproxy_*.yaml
sed -i "s/PORT_PREFIX_PLACEHOLDER/${PORT}/g" ${PROJECT_DIR}/config.yaml
sed -i "s/skeleton/${APP}/g" ${PROJECT_DIR}/config.yaml

# Replace the word skeleton with the app name
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/*.py
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/project/*.py
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/conf/*.conf.in
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/MANIFEST.in
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/tox.ini
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/.travis.yml
sed -i s/skeleton/${APP}/g ${APP_DIR}/*.py
sed -i s/skeleton/${APP}/g ${APP_DIR}/migrations/*.py

# Set the secret key
SECRET_KEY=`date +%s | sha256sum | head -c 56`
sed -i "s/SECRET_KEY_PLACEHOLDER/${SECRET_KEY}/" ${PROJECT_DIR}/project/settings.py

# Indicate version of jmbo-skeleton used to create project
VERSION=`sed "5q;d" setup.py | awk -F= '{print $2}'`
echo "Changelog" > ${PROJECT_DIR}/CHANGELOG.rst
echo "=========" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "0.1" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "---" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "Project generated by jmbo-skeleton $VERSION" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "" >> ${PROJECT_DIR}/CHANGELOG.rst

echo "Done. You must set a proper API in deviceproxy_site.yaml for it to work in a production environment."
