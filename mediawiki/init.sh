#!/bin/bash

UPGRADE_KEY_FILE=upgrade-key.html
LOCAL_SETTINGS=LocalSettings.php
EXTENSIONS_DIR=/var/www/html/extensions/
EXTENSIONS_URL=https://extdist.wmflabs.org/dist/extensions
DATA_FILE=mediawiki_full_backup.sql

echo "Waiting for database..."

sleep 5

echo "Installing extentions..."

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

mv mediawiki-extensions-EmbedVideo-3.4.2 EmbedVideo

find . -name "*.tar.gz" -type f -exec tar -xvf {} \;
rm *.tar.gz

cd -


# Install default LocalSettings.php

echo "Initializing database..."

php maintenance/install.php --dbname=${DB_NAME} --dbserver=${DB_SERVER} --dbport=3306 --dbuser=${DB_USER} --dbpass="${DB_PASSWORD}" --pass="${WIKI_ADMIN_PASSWORD}" "${WIKI_NAME}" "Admin"

echo "Generating and customizing LocalSettings.php..."

cp defaults/LocalSettings.default LocalSettings.php

sed -i -E "s/wgServer = \"[^\"]*\"/wgServer = \"http:\/\/${PUBLIC_HOSTNAME}\\/\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgServerName = \"[^\"]*\"/wgServerName = \"${PUBLIC_HOSTNAME}\"/g" ${LOCAL_SETTINGS}

sed -i -E "s/wgDBserver = \"[^\"]*\"/wgDBserver = \"${DB_SERVER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBname = \"[^\"]*\"/wgDBname = \"${DB_NAME}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBuser = \"[^\"]*\"/wgDBuser = \"${DB_USER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBpassword = \"[^\"]*\"/wgDBpassword = \"${DB_PASSWORD}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgBrowserFormatDetection=(.*);/wgBrowserFormatDetection = \"\1\";/g" ${LOCAL_SETTINGS}
sed -i -E "s/'host' *=> \".*\"/'host' => \"${SMTP_HOST}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/'IDHost' *=> \".*\"/'IDHost' => \"${PUBLIC_HOSTNAME}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/'username' *=> \".*\"/'username' => \"${SMTP_USER}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/'password' *=> \".*\"/'password' => \"${SMTP_PASS}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/user@email.com/${EMAIL_CONTACT}/g" ${LOCAL_SETTINGS}

echo "Updating database..."
php maintenance/update.php

# UpgradeKey
#curl -L -s -b cookies.txt -c cookies.txt -X POST -H "Content-Type: application/x-www-form-urlencoded" -o ${UPGRADE_KEY_FILE} http://${PUBLIC_HOSTNAME}/mw-config/index.php?page=ExistingWiki
#rm cookies.txt
#UPGRADE_KEY=`grep UpgradeKey ${LOCAL_SETTINGS}`
# eg: $wgUpgradeKey = '066c9247965445f2'
#UPGRADE_KEY=`sed -nE 's/.*UpgradeKey = "(.*)".*/\1/p' ${UPGRADE_KEY_FILE}`
#echo "\n\n\$wgUpgradeKey = '${UPGRADE_KEY}';" >> LocalSettings.php

echo "Importing production data..."

mkdir /app/data_import
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh-keyscan -H "$PRODUCTION_HOSTNAME" >> ~/.ssh/known_hosts
rsync -e "ssh -i /app/.ssh/id_docker_data" --progress --archive $DATA_IMPORT_USER@$PRODUCTION_HOSTNAME:~/$DATA_FILE /app/data_import/

mysql -u $DB_USER -p$DB_PASSWORD -h $DB_SERVER $DB_NAME < /app/data_import/$DATA_FILE

# Copy the data and image files

echo "Importing static files from production..."

rsync -e "ssh -i /app/.ssh/id_docker_data" --progress --archive $DATA_IMPORT_USER@$PRODUCTION_HOSTNAME:~/images/* /var/www/html/images/

# Prepare logs

# Remove symlinks that redirect files to stdout and stderr
rm /var/log/apache2/access.log
rm /var/log/apache2/error.log
rm /var/log/apache2/other_vhosts_access.log

echo "<?php
phpinfo();
?>" > /var/www/html/info.php

echo "log_errors = On
error_log = '/var/log/php_errors.log'" > /usr/local/etc/php/php.ini

#echo "ErrorLog \${APACHE_LOG_DIR}/error.log" >> /etc/apache2/apache2.conf
#echo "CustomLog \${APACHE_LOG_DIR}/access.log combined" >> /etc/apache2/apache2.conf

echo "Starting MediaWiki..."

#php-fpm
apache2-foreground

