#!/bin/bash

# TODO:
# - Migrate whatever possible to the Mediawiki.Dockerfile

escape_sed() {
  printf '%s\n' "$1" | sed -e 's/[][\\.^$*+?{}|/]/\\&/g' -e 's/&/\\&/g'
}

# If the init script has already run, start apache
if [[ -e /.mediawiki-initialized ]]; then
  php-fpm
#  apache2-foreground
  exit
fi

# Else install all the things.

UPGRADE_KEY_FILE=upgrade-key.html
LOCAL_SETTINGS=LocalSettings.php
EXTENSIONS_DIR=/var/www/html/extensions/
EXTENSIONS_URL=https://extdist.wmflabs.org/dist/extensions
DATA_FILE=mediawiki_full_backup.sql

echo "Waiting for database..."

sleep 9

echo "Installing extentions..."

mkdir -p ${EXTENSIONS_DIR}/
cd ${EXTENSIONS_DIR}/ || { echo "Failed to cd into ${EXTENSIONS_DIR}"; exit 1; }
rm -Rf *

# TODO: These filenames seem to change on occasion. Change them to git clones.
#wget ${EXTENSIONS_URL}/HeadScript-REL1_43-2a10bd3.tar.gz
#wget ${EXTENSIONS_URL}/Renameuser-REL1_43-7f8e398.tar.gz # Merged into code
#wget ${EXTENSIONS_URL}/Lingo-REL1_43-3714aef.tar.gz 
wget https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo/archive/refs/tags/v4.0.0.tar.gz 
# wget ${EXTENSIONS_URL}/Quiz-REL1_43-d3d8313.tar.gz 
# wget ${EXTENSIONS_URL}/MobileFrontend-REL1_43-6fbfcff.tar.gz
#wget ${EXTENSIONS_URL}/UserMerge-REL1_43-816da9f.tar.gz 
#wget ${EXTENSIONS_URL}/Lockdown-REL1_43-7ac8966.tar.gz 
#wget ${EXTENSIONS_URL}/EditAccount-REL1_43-2fe1b31.tar.gz 
#wget ${EXTENSIONS_URL}/Echo-REL1_43-c1b049e.tar.gz
#wget ${EXTENSIONS_URL}/WhoIsWatching-REL1_43-2baa91d.tar.gz 
#wget ${EXTENSIONS_URL}/ConfirmEdit-REL1_43-b6f02db.tar.gz
#wget ${EXTENSIONS_URL}/WikiEditor-REL1_43-6c5e81a.tar.gz
#wget ${EXTENSIONS_URL}/ParserFunctions-REL1_43-f5aaf52.tar.gz

find . -name "*.tar.gz" -type f -exec tar -xvf {} \;
rm *.tar.gz*

mv mediawiki-extensions-EmbedVideo-4.0.0 EmbedVideo

git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/HeadScript
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Lingo
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Quiz
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Lockdown
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/EditAccount
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Echo
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/WhoIsWatching
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmEdit
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiEditor
git clone --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/ParserFunctions
git clone -b REL1_43 https://github.com/CourthouseLibrariesBC/mediawiki-extensions-CommentStreams.git CommentStreams


cp -R /app/Collection .

cd -

# Install default LocalSettings.php

echo "Initializing database..."

php maintenance/install.php --dbname=${DB_NAME} --dbserver=${DB_SERVER} --dbport=3306 --dbuser=${DB_USER} --dbpass="${DB_PASSWORD}" --pass="${WIKI_ADMIN_PASSWORD}" "${WIKI_NAME}" "Admin"

echo "Generating and customizing LocalSettings.php..."

#cp defaults/LocalSettings.default LocalSettings.php

sed -i -E "s/wgServer = \"[^\"]*\"/wgServer = 'http:\/\/${PUBLIC_HOSTNAME}'/g" ${LOCAL_SETTINGS}
#sed -i -E "s/wgServer = \"http:\/\/your.public.domain\"/wgServer = \"http:\/\/${PUBLIC_HOSTNAME}\\/\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgServerName = \"[^\"]*\"/wgServerName = '${PUBLIC_HOSTNAME}'/g" ${LOCAL_SETTINGS}

sed -i -E "s/wgDBserver = \"[^\"]*\"/wgDBserver = '${DB_SERVER}'/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBname = \"[^\"]*\"/wgDBname = '${DB_NAME}'/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBuser = \"[^\"]*\"/wgDBuser = '${DB_USER}'/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgDBpassword = \"[^\"]*\"/wgDBpassword = '${DB_PASSWORD}'/g" ${LOCAL_SETTINGS}

sed -i -E "s/wgBrowserFormatDetection=(.*);/wgBrowserFormatDetection = '\1';/g" ${LOCAL_SETTINGS}

sed -i -E "s/'host' *=> \".*\"/'host' => '${SMTP_HOST}'/g" ${LOCAL_SETTINGS}
sed -i -E "s/'IDHost' *=> \".*\"/'IDHost' => \"${PUBLIC_HOSTNAME}\"/g" ${LOCAL_SETTINGS}
sed -i -E "s/'username' *=> \".*\"/'username' => '${SMTP_USER}'/g" ${LOCAL_SETTINGS}
sed -i -E "s/'password' *=> \".*\"/'password' => '$(escape_sed ${SMTP_PASS})'/g" ${LOCAL_SETTINGS}

sed -i -E "s/user@email.com/${EMAIL_CONTACT}/g" ${LOCAL_SETTINGS}


cat <<EOF > /etc/msmtprc
# /etc/msmtprc
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        ses
host           ${SMTP_HOST}
port           ${SMTP_PORT}
from           ${EMAIL_CONTACT}
user           ${SMTP_USER}
password       ${SMTP_PASS}

account default : ses
EOF
chmod 600 /etc/msmtprc
chown www-data:www-data /etc/msmtprc
ln -sf /usr/bin/msmtp /usr/sbin/sendmail

#echo "Updating database..."
#php maintenance/update.php

# UpgradeKey
UPGRADE_KEY=`openssl rand -hex 16`
echo "\$wgUpgradeKey = '${UPGRADE_KEY}';" >> LocalSettings.php

echo "Importing production data..."

mkdir /app/data_import
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh-keyscan -H "$PRODUCTION_HOSTNAME" >> ~/.ssh/known_hosts
rsync -e "ssh -i /app/.ssh/id_docker_data" --progress --archive $DATA_IMPORT_USER@$PRODUCTION_HOSTNAME:~/$DATA_FILE /app/data_import/

mysql -u $DB_USER -p$DB_PASSWORD -h $DB_SERVER $DB_NAME < /app/data_import/$DATA_FILE

rm -Rf /app/data_import

# Copy the data and image files

#echo "Importing static files from production..."

#rsync -e "ssh -i /app/.ssh/id_docker_data" --progress --archive $DATA_IMPORT_USER@$PRODUCTION_HOSTNAME:~/images/* /var/www/html/images/

# Prepare logs

# Remove symlinks that redirect files to stdout and stderr
#rm /var/log/apache2/access.log
#rm /var/log/apache2/error.log
#rm /var/log/apache2/other_vhosts_access.log

echo "<?php
phpinfo();
?>" > /var/www/html/info.php

echo "log_errors = On
error_log = '/var/log/php_errors.log'" > /usr/local/etc/php/php.ini

#echo "ErrorLog \${APACHE_LOG_DIR}/error.log" >> /etc/apache2/apache2.conf
#echo "CustomLog \${APACHE_LOG_DIR}/access.log combined" >> /etc/apache2/apache2.conf

#cat <<EOF >> /etc/apache2/apache2.conf
#Alias /cache/ /app/cache/
#<Directory /app/cache/>
#    Options Indexes FollowSymLinks
#    AllowOverride None
#    Require all granted
#</Directory>
#AddType application/pdf .pdf
#EOF

echo "Initialization complete..."
touch /.mediawiki-initialized

echo "Updating database..."
php maintenance/update.php

chown -R www-data:www-data *

echo "Starting MediaWiki..."
php-fpm
#apache2-foreground

