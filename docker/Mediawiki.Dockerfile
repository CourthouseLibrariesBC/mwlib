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
      -y install wget man vim curl iputils-ping tcpdump imagemagick openssh-client rsync mariadb-client msmtp msmtp-mta git unzip ca-certificates

RUN rm -f /.mediawiki-initialized

# Increase PHP upload limits from default 2MB to 10MB
RUN echo "upload_max_filesize = 10M\npost_max_size = 11M" > /usr/local/etc/php/conf.d/uploads.ini

# PHP config: error logging and memory limit
RUN echo "log_errors = On\nerror_log = /var/log/php_errors.log\nmemory_limit = 1024M" > /usr/local/etc/php/conf.d/custom.ini
RUN touch /var/log/php_errors.log && chmod a+w /var/log/php_errors.log

# Create info.php for diagnostics
RUN echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Install extensions at build time
RUN rm -rf /var/www/html/extensions/* \
    && cd /var/www/html/extensions \
    && wget -q https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo/archive/refs/tags/v4.0.0.tar.gz \
    && find . -name "*.tar.gz" -type f -exec tar -xf {} \; \
    && rm -f *.tar.gz* \
    && mv mediawiki-extensions-EmbedVideo-4.0.0 EmbedVideo \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/HeadScript \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Lingo \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Quiz \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Lockdown \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/EditAccount \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/Echo \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/WhoIsWatching \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmEdit \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiEditor \
    && git clone --depth 1 --branch REL1_43 https://gerrit.wikimedia.org/r/mediawiki/extensions/ParserFunctions \
    && curl -sL -o CommentStreams-REL1_43.tar.gz https://github.com/CourthouseLibrariesBC/mediawiki-extensions-CommentStreams/archive/refs/heads/REL1_43.tar.gz \
    && tar -xzf CommentStreams-REL1_43.tar.gz \
    && mv mediawiki-extensions-CommentStreams-REL1_43 CommentStreams \
    && rm -f CommentStreams-REL1_43.tar.gz

# Keys are not available in the repo.
# Request them from your admin.
COPY ./mediawiki/keys/* /app/.ssh/

COPY ./mediawiki/defaults/LocalSettings.default $LOCAL_SETTINGS

# Copy Collection extension
COPY ./Collection /var/www/html/extensions/Collection

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_MEMORY_LIMIT=-1 COMPOSER_HOME=/tmp/composer

WORKDIR /var/www/html

# add your extra deps here
COPY composer.local.json /var/www/html/composer.local.json

# install (honors composer.lock + composer.local.json)
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-security-blocking \
 && rm -rf /tmp/composer

RUN ssh-keyscan -H -t ed25519 $PRODUCTION_SSH_HOST > /tmp/known_hosts
RUN rsync -e "ssh -i /app/.ssh/id_docker_data -o UserKnownHostsFile=/tmp/known_hosts -o StrictHostKeyChecking=yes" --progress --archive $DATA_IMPORT_USER@$PRODUCTION_SSH_HOST:~/images/* /var/www/html/images/

# Copy the db-init script
COPY ./mediawiki/db-init.sh /db-init.sh
RUN chmod +x /db-init.sh

# Set ownership for web server
RUN chown -R www-data:www-data /var/www/html

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]
