# Use the official MediaWiki image as the base
# 1.43.3 is the lts version
FROM mediawiki:1.43.3-fpm

ARG WEB_ROOT=/var/www/html
ARG LOCAL_SETTINGS=$WEB_ROOT/LocalSettings.php
ARG DATA_IMPORT_USER
ARG PRODUCTION_SSH_HOST

RUN apt-get update && \
    apt-get \
      -o Acquire::BrokenProxy="true" \
      -o Acquire::http::No-Cache="true" \
      -o Acquire::http::Pipeline-Depth="0" \
      -y install wget man vim curl iputils-ping imagemagick openssh-client rsync mariadb-client msmtp msmtp-mta

RUN rm -f /.mediawiki-initialized

# Keys are not available in the repo.
# Request them from your admin.
COPY ./mediawiki/keys/* /app/.ssh/

COPY ./mediawiki/defaults/LocalSettings.default $LOCAL_SETTINGS

COPY ./Collection /app/Collection

# ensure tools & composer env
RUN apt-get update && apt-get install -y --no-install-recommends git unzip ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_MEMORY_LIMIT=-1 COMPOSER_HOME=/tmp/composer

WORKDIR /var/www/html

# add your extra deps here
COPY composer.local.json /var/www/html/composer.local.json

# install (honors composer.lock + composer.local.json)
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress \
 && rm -rf /tmp/composer

RUN ssh-keyscan -H -t ed25519 $PRODUCTION_SSH_HOST > /tmp/known_hosts
#RUN ssh -vvv -i /app/.ssh/id_docker_data  $DATA_IMPORT_USER@$PRODUCTION_SSH_HOST
RUN rsync -e "ssh -i /app/.ssh/id_docker_data -o UserKnownHostsFile=/tmp/known_hosts -o StrictHostKeyChecking=yes" --progress --archive $DATA_IMPORT_USER@$PRODUCTION_SSH_HOST:~/images/* /var/www/html/images/

# Set entrypoint to execute the install script before starting Apache
ENTRYPOINT ["docker-php-entrypoint"]

# Default command (start Apache)
CMD ["/init.sh"]

