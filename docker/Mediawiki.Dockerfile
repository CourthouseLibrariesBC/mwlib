# Use the official MediaWiki image as the base
FROM mediawiki:1.41.1

RUN apt-get update && \
    apt-get \
      -o Acquire::BrokenProxy="true" \
      -o Acquire::http::No-Cache="true" \
      -o Acquire::http::Pipeline-Depth="0" \
      -y install wget man vim curl iputils-ping imagemagick openssh-client rsync mariadb-client

# Keys are not available in the repo.
# Request them from your admin.
COPY mediawiki/keys/* /app/.ssh/

# Set entrypoint to execute the install script before starting Apache
ENTRYPOINT ["docker-php-entrypoint"]

# Default command (start Apache)
CMD ["/init.sh"]

