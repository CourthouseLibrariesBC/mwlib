#!/bin/bash

# DEPRECATED — This script has been replaced by:
#   - docker/Mediawiki.Dockerfile  (extensions, PHP config, static setup)
#   - mediawiki/db-init.sh         (DB init, LocalSettings config, data import)
#
# The db-init service runs via:  docker compose --profile init up
# Normal startup just runs:      docker compose up
#
# This file is kept for reference only and is no longer mounted or executed.
