#!/bin/bash

# db-init.sh — Runs once to initialize the MediaWiki database.
# Called by the db-init docker compose service (profile: init).
# The wiki-database healthcheck guarantees the DB is ready before this runs.

set -e

escape_sed() {
  printf '%s\n' "$1" | sed -e 's/[][\\.^$*+?{}|/]/\\&/g' -e 's/&/\\&/g'
}

LOCAL_SETTINGS=LocalSettings.php
DATA_FILE=mediawiki_full_backup.sql

# ── Idempotency check ────────────────────────────────────────────────
# If the wiki tables already exist, skip initialization.
if mysql -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_SERVER" "$DB_NAME" \
   -e "SELECT 1 FROM page LIMIT 1" 2>/dev/null; then
  echo "Database already initialized — skipping."
  exit 0
fi

echo "==> Initializing database..."

cd /var/www/html

# install.php refuses to run if LocalSettings.php exists.
# Move our custom template aside, let install.php create the DB schema,
# then replace its generated config with our template.
mv ${LOCAL_SETTINGS} ${LOCAL_SETTINGS}.default

php maintenance/install.php \
  --dbname="${DB_NAME}" \
  --dbserver="${DB_SERVER}" \
  --dbport=3306 \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASSWORD}" \
  --pass="${WIKI_ADMIN_PASSWORD}" \
  "${WIKI_NAME}" "Admin"

# Replace the generated LocalSettings.php with our custom template
mv ${LOCAL_SETTINGS}.default ${LOCAL_SETTINGS}

# ── Customize LocalSettings.php ──────────────────────────────────────
echo "==> Configuring LocalSettings.php..."

sed -i -E "s/wgServer = \"https:\/\/[^\"]*\"/wgServer = 'https:\/\/${PUBLIC_HOSTNAME}'/g" ${LOCAL_SETTINGS}
sed -i -E "s/wgServer = \"http:\/\/[^\"]*\"/wgServer = 'http:\/\/${PUBLIC_HOSTNAME}'/g" ${LOCAL_SETTINGS}
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

# Generate upgrade key
UPGRADE_KEY=$(openssl rand -hex 16)
echo "\$wgUpgradeKey = '${UPGRADE_KEY}';" >> ${LOCAL_SETTINGS}

# ── Configure msmtp for outbound email ───────────────────────────────
echo "==> Configuring msmtp..."

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

# ── Import production data ───────────────────────────────────────────
echo "==> Importing production data..."

mkdir -p /app/data_import
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh-keyscan -H "$PRODUCTION_SSH_HOST" >> ~/.ssh/known_hosts
rsync -e "ssh -i /app/.ssh/id_docker_data" --progress --archive \
  "$DATA_IMPORT_USER@$PRODUCTION_SSH_HOST:~/$DATA_FILE" /app/data_import/

mysql -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_SERVER" "$DB_NAME" < "/app/data_import/$DATA_FILE"

rm -rf /app/data_import

# ── Run database updates ─────────────────────────────────────────────
echo "==> Running maintenance/update.php..."
php maintenance/update.php

# ── Fix permissions ──────────────────────────────────────────────────
chmod 1777 /app/cache
chown -R www-data:www-data /var/www/html

echo "==> Database initialization complete."
