#!/bin/bash
set -ex

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" <<-EOSQL
    CREATE USER ${BITBUCKET_DATABASE_USER} ENCRYPTED PASSWORD '${BITBUCKET_DATABASE_PASSWORD}';
    CREATE DATABASE ${BITBUCKET_DATABASE_NAME} ENCODING 'UNICODE' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;
    GRANT ALL PRIVILEGES ON DATABASE ${BITBUCKET_DATABASE_NAME} TO ${BITBUCKET_DATABASE_USER};
EOSQL