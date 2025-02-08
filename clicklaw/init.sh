#!/bin/bash

UPGRADE_KEY_FILE=upgrade-key.html
LOCAL_SETTINGS=LocalSettings.php
EXTENSIONS_DIR=/var/www/html/extensions/
EXTENSIONS_URL=https://extdist.wmflabs.org/dist/extensions
DATA_FILE=mediawiki_full_backup.sql

echo "Waiting for database..."

sleep 5

echo "Initializing Clicklaw..."


# Install extensions

mkdir -p ${EXTENSIONS_DIR}/
cd ${EXTENSIONS_DIR}/

wget ${EXTENSIONS_URL}/Collection-REL1_41-fe5eaec.tar.gz \
${EXTENSIONS_URL}/HeadScript-REL1_41-ac3bcc2.tar.gz \
${EXTENSIONS_URL}/Renameuser-REL1_41-a93981c.tar.gz \
${EXTENSIONS_URL}/Lingo-REL1_41-7472327.tar.gz \
https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo/archive/refs/tags/v3.4.2.tar.gz \
${EXTENSIONS_URL}/Quiz-REL1_41-19518aa.tar.gz \
${EXTENSIONS_URL}/MobileFrontend-REL1_41-9e2489b.tar.gz \
${EXTENSIONS_URL}/UserMerge-REL1_41-9a30c61.tar.gz \
${EXTENSIONS_URL}/Lockdown-REL1_41-445f530.tar.gz \
${EXTENSIONS_URL}/EditAccount-REL1_41-822aac0.tar.gz \
${EXTENSIONS_URL}/CommentStreams-REL1_41-5121daf.tar.gz \
${EXTENSIONS_URL}/Echo-REL1_41-88415dd.tar.gz \
${EXTENSIONS_URL}/WhoIsWatching-REL1_41-1c81208.tar.gz \
${EXTENSIONS_URL}/ConfirmEdit-REL1_41-17bb33b.tar.gz \
${EXTENSIONS_URL}/WikiEditor-REL1_41-c2f962a.tar.gz \
${EXTENSIONS_URL}/ParserFunctions-REL1_41-69ba429.tar.gz

find . -name "*.tar.gz" -type f -exec tar -xvf {} \;
rm *.tar.gz

cd -


# Install default LocalSetting.php

php maintenance/install.php --dbname=${DB_NAME} --dbserver=${DB_SERVER} --dbport=3306 --dbuser=${DB_USER} --dbpass="${DB_PASSWORD}" --pass="${WIKI_ADMIN_PASSWORD}" "${WIKI_NAME}" "Admin"

cp defaults/LocalSettings.php LocalSettings.php

##sed -i -E "s/wgResourceBasePath = \"\$wgScriptPath\"/wgResourceBasePath = \"\/\"/g" ${LOCAL_SETTINGS}

##sed -i -E "/wgResourceBasePath =/d" ${LOCAL_SETTINGS}
##sed -i -E "s/wgScriptPath = \"\/html\"/wgScriptPath = \"\/html\"/g" ${LOCAL_SETTINGS}

#cat "\n\n\$wgScript = \"\/html/index.php\"" >> ${LOCAL_SETTINGS}

##echo "\$wgLoadScript = \"/load.php\";" >> ${LOCAL_SETTINGS}

sed -i -E "s/wgServer = \"[^\"]*\"/wgServer = \"http:\/\/${DOCKER_HOSTNAME}\\/\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgServerName = \"[^\"]*\"/wgServerName = \"${DOCKER_HOSTNAME}\"/g" ${LOCAL_SETTINGS}

sed -i -E "s/wgDBserver = \"[^\"]*\"/wgDBserver = \"${DB_SERVER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBname = \"[^\"]*\"/wgDBname = \"${DB_NAME}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBuser = \"[^\"]*\"/wgDBuser = \"${DB_USER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBpassword = \"[^\"]*\"/wgDBpassword = \"${DB_PASSWORD}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgBrowserFormatDetection=(.*);/wgBrowserFormatDetection = \"\1\";/g" ${LOCAL_SETTINGS}

echo "Updating MediaWiki database..."
php maintenance/update.php

# UpgradeKey
#curl -L -s -b cookies.txt -c cookies.txt -X POST -H "Content-Type: application/x-www-form-urlencoded" -o ${UPGRADE_KEY_FILE} http://${DOCKER_HOSTNAME}/mw-config/index.php?page=ExistingWiki
#rm cookies.txt
#UPGRADE_KEY=`grep UpgradeKey ${LOCAL_SETTINGS}`
# eg: $wgUpgradeKey = '066c9247965445f2'
UPGRADE_KEY=`sed -nE 's/.*UpgradeKey = "(.*)".*/\1/p' ${UPGRADE_KEY_FILE}`
#echo "\n\n\$wgUpgradeKey = '${UPGRADE_KEY}';" >> LocalSettings.php

echo "Importing wiki data..."

mkdir /app/data_import
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh-keyscan -H "$PRODUCTION_HOSTNAME" >> ~/.ssh/known_hosts
rsync -e "ssh -i /app/.ssh/id_clicklaw_docker_data" --progress --archive $SCP_USER@$PRODUCTION_HOSTNAME:~/$DATA_FILE /app/data_import/

mysql -u $DB_USER -p$DB_PASSWORD -h $DB_SERVER $DB_NAME < /app/data_import/$DATA_FILE

#php maintenance/importDump.php /app/data_import/$DATA_FILE

## SCP the data and image files

echo "Importing image data..."
rsync -e "ssh -i /app/.ssh/id_clicklaw_docker_data" --progress --archive $SCP_USER@$PRODUCTION_HOSTNAME:~/images/* /var/www/html/images/


apache2-foreground

