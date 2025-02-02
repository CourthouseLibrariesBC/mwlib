#!/bin/bash

UPGRADE_KEY_FILE=upgrade-key.html
LOCAL_SETTINGS=LocalSettings.php
EXTENSIONS_DIR=/var/www/html/extensions/
EXTENSIONS_URL=https://extdist.wmflabs.org/dist/extensions

echo Waiting for database...
sleep 5

echo "Initializing Clicklaw..."

# PUBLIC_IP=$(curl -s ifconfig.me)

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

sed -i -E "s/wgServer = \"[^\"]*\"/wgServer = \"http:\/\/${PUBLIC_HOSTNAME}\\/\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgServerName = \"[^\"]*\"/wgServerName = \"${PUBLIC_HOSTNAME}\"/g" ${LOCAL_SETTINGS}

sed -i -E "s/wgDBserver = \"[^\"]*\"/wgDBserver = \"${DB_SERVER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBname = \"[^\"]*\"/wgDBname = \"${DB_NAME}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBuser = \"[^\"]*\"/wgDBuser = \"${DB_USER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBpassword = \"[^\"]*\"/wgDBpassword = \"${DB_PASSWORD}\"/g" ${LOCAL_SETTINGS}


#cat "\n\n\$wgScript = \"\/html/index.php\"" >> ${LOCAL_SETTINGS}

##echo "\$wgLoadScript = \"/load.php\";" >> ${LOCAL_SETTINGS}

# UpgradeKey fishing

php maintenance/update.php

#echo curl -L -s -b cookies.txt -c cookies.txt -X POST -H "Content-Type: application/x-www-form-urlencoded" -o ${UPGRADE_KEY_FILE} http://${PUBLIC_HOSTNAME}/mw-config/index.php?page=ExistingWiki
#curl -L -s -b cookies.txt -c cookies.txt -X POST -H "Content-Type: application/x-www-form-urlencoded" -o ${UPGRADE_KEY_FILE} http://${PUBLIC_HOSTNAME}/mw-config/index.php?page=ExistingWiki

# Second request generates key prompt

#sleep 1
#curl -L -s -b cookies.txt -c cookies.txt -X POST -H "Content-Type: application/x-www-form-urlencoded" -o ${UPGRADE_KEY_FILE} http://${PUBLIC_HOSTNAME}/mw-config/index.php?page=ExistingWiki

#rm cookies.txt

#UPGRADE_KEY=`grep UpgradeKey ${LOCAL_SETTINGS}`

#echo $UPGRADE_KEY > ${UPGRADE_KEY_FILE}

# eg: $wgUpgradeKey = '066c9247965445f2'
#UPGRADE_KEY=`sed -nE 's/.*UpgradeKey = "(.*)".*/\1/p' ${UPGRADE_KEY_FILE}`

#echo UPGRADE_KEY: $UPGRADE_KEY

#echo "\n\n\$wgUpgradeKey = '${UPGRADE_KEY}';" >> LocalSettings.php

##wget -q https://wiki.clicklaw.bc.ca/ml/wiki-dump.xml -O wiki-dump.xml

##php maintenance/importDump.php wiki-dump.xml

#while true; do
#	sleep 1
#done	

apache2-foreground

