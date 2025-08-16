# Use the official MediaWiki image as the base
FROM mediawiki:1.43.3

ARG WEB_ROOT=/var/www/html
ARG LOCAL_SETTINGS=$WEB_ROOT/LocalSettings.php

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

# Let Composer run as root during build without complaints
ENV COMPOSER_ALLOW_SUPERUSER=1

# Copy the Composer binary from the official composer image
WORKDIR /var/www/html
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN composer require \
      "mwstake/mediawiki-component-manifestregistry:^3.0" \
      "mwstake/mediawiki-componentloader:^1" \
      --update-no-dev --prefer-dist --no-interaction --no-progress

# Set entrypoint to execute the install script before starting Apache
ENTRYPOINT ["docker-php-entrypoint"]

# Default command (start Apache)
CMD ["/init.sh"]

