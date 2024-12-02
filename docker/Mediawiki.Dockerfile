# Use the official MediaWiki image as the base
FROM mediawiki:1.41.1

RUN apt-get update && \
    apt-get \
      -o Acquire::BrokenProxy="true" \
      -o Acquire::http::No-Cache="true" \
      -o Acquire::http::Pipeline-Depth="0" \
      -y install wget curl

# Install extensions

ARG EXTENSIONS_DIR=/app/mediawiki/extensions

ARG COLLECTION_TAR=Collection-REL1_41-7f5b0ce.tar.gz
ARG COLLECTION_URL=https://extdist.wmflabs.org/dist/extensions

RUN mkdir -p ${EXTENSIONS_DIR}/Collection/
RUN wget ${COLLECTION_URL}/${COLLECTION_TAR} -O ${COLLECTION_TAR} && \
    tar -xzf ${COLLECTION_TAR} -C ${EXTENSIONS_DIR}/Collection/ && \
    rm ${COLLECTION_TAR}

# Configure database and install LocalSetting.php

ARG WIKI_NAME
ARG WIKI_ADMIN_PASSWORD
ARG PUBLIC_HOSTNAME
ARG DB_SERVER
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD

#RUN echo ${DB_NAME} ${DB_USER} ${DB_PASSWORD}

#PUBLIC_IP=$(curl -s ifconfig.me) && \

# RUN php maintenance/install.php --dbname=${DB_NAME} --dbserver=${DB_SERVER} --dbuser=${DB_USER} --dbpass=${DB_PASSWORD} --pass=${WIKI_ADMIN_PASSWORD} "${WIKI_NAME}" "Admin" && \
#    wget http://${PUBLIC_HOSTNAME}/mw-config/index.php?download=1 /var/www/html/LocalSettings.php

#RUN chmod 600 /var/www/html/LocalSettings.php

