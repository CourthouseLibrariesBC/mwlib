# Use the official MediaWiki image as the base
FROM mediawiki:1.41.1

RUN apt-get update && \
    apt-get \
      -o Acquire::BrokenProxy="true" \
      -o Acquire::http::No-Cache="true" \
      -o Acquire::http::Pipeline-Depth="0" \
      -y install wget man vim curl iputils-ping

# Install extensions

ARG EXTENSIONS_DIR=/app/mediawiki/extensions

ARG COLLECTION_TAR=Collection-REL1_41-14d9f73.tar.gz
ARG COLLECTION_URL=https://extdist.wmflabs.org/dist/extensions

#RUN mkdir -p ${EXTENSIONS_DIR}/Collection/
#RUN wget ${COLLECTION_URL}/${COLLECTION_TAR} -O ${COLLECTION_TAR} && \
#    tar -xzf ${COLLECTION_TAR} -C ${EXTENSIONS_DIR}/Collection/ && \
#    rm ${COLLECTION_TAR}

# Set entrypoint to execute the install script before starting Apache
#ENTRYPOINT ["/init.sh"]
#ENTRYPOINT ["docker-php-entrypoint"]

# Default command (start Apache)
#CMD ["apache2-foreground"]
#CMD ["/init.sh"]

