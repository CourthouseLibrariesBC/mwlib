#!/bin/bash

UPGRADE_KEY_FILE=upgrade-key.html
LOCAL_SETTINGS=LocalSettings.php

echo Waiting for database...
sleep 5

echo "Initializing Clicklaw..."

# PUBLIC_IP=$(curl -s ifconfig.me)

# Install default LocalSetting.php

php maintenance/install.php --dbname=${DB_NAME} --dbserver=${DB_SERVER} --dbport=3306 --dbuser=${DB_USER} --dbpass="${DB_PASSWORD}" --pass="${WIKI_ADMIN_PASSWORD}" --confpath=. "${WIKI_NAME}" "Admin"

##sed -i -E "s/wgResourceBasePath = \"\$wgScriptPath\"/wgResourceBasePath = \"\/\"/g" ${LOCAL_SETTINGS}

sed -i -E "/wgResourceBasePath =/d" ${LOCAL_SETTINGS}
##sed -i -E "s/wgScriptPath = \"\/html\"/wgScriptPath = \"\/html\"/g" ${LOCAL_SETTINGS}

sed -i -E "s/localhost/${PUBLIC_HOSTNAME}/g" ${LOCAL_SETTINGS}

##cat "\n\n\$wgScript = \"\/html/index.php\"" >> ${LOCAL_SETTINGS}

echo "\$wgLoadScript = \"/load.php\";" >> ${LOCAL_SETTINGS}


# UpgradeKey fishing

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

wget -q https://wiki.clicklaw.bc.ca/ml/wiki-dump.xml -O wiki-dump.xml

php maintenance/importDump.php wiki-dump.xml

#while true; do
#	sleep 1
#done	


apache2-foreground

