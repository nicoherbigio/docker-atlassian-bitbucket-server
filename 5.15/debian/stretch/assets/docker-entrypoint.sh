#!/bin/bash
set -euo pipefail


# Setup Java Keystore

if [ -d "/secrets" ]; then
    KEYTOOL="${JAVA_HOME}/bin/keytool"
    KEYSTORE="${JAVA_HOME}/jre/lib/security/cacerts"

    for CERT_FILE in "/secrets/*.crt"; do
        echo "Importing certificate file ${CERT_FILE} into Java Keystore ${KEYSTORE}"

        ${KEYTOOL} -delete -keystore ${KEYSTORE} -storepass changeit -noprompt -alias "${CERT_FILE}" 2>&1 > /dev/null || :
        ${KEYTOOL} -importcert -keystore ${KEYSTORE} -storepass changeit -trustcacerts -noprompt -alias "${CERT_FILE}" -file ${CERT_FILE}
    done
fi


# Setup Catalina Opts

: ${CATALINA_CONNECTOR_PROXYNAME:=}
: ${CATALINA_CONNECTOR_PROXYPORT:=}
: ${CATALINA_CONNECTOR_SCHEME:=http}
: ${CATALINA_CONNECTOR_SECURE:=false}

: ${CATALINA_OPTS:=}

: ${ELASTICSEARCH_ENABLED:=true}
: ${APPLICATION_MODE:=}

CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyName=${CATALINA_CONNECTOR_PROXYNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyPort=${CATALINA_CONNECTOR_PROXYPORT}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorScheme=${CATALINA_CONNECTOR_SCHEME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorSecure=${CATALINA_CONNECTOR_SECURE}"

export CATALINA_OPTS

: ${JAVA_OPTS:=}

JAVA_OPTS="${JAVA_OPTS} ${CATALINA_OPTS}"

ARGS="$@"


# Start Bitbucket without Elasticsearch

if [ "${ELASTICSEARCH_ENABLED}" == "false" ] || [ "${APPLICATION_MODE}" == "mirror" ]; then
    ARGS="--no-search ${ARGS}"
fi

# Start Bitbucket Server as the correct user.
if [ "${UID}" -eq 0 ]; then
    echo "User is currently root. Will change directory ownership to ${RUN_USER}:${RUN_GROUP}, then downgrade permission to ${RUN_USER}"
    PERMISSIONS_SIGNATURE=$(stat -c "%u:%U:%a" "${BITBUCKET_HOME}")
    EXPECTED_PERMISSIONS=$(id -u ${RUN_USER}):${RUN_USER}:700
    if [ "${PERMISSIONS_SIGNATURE}" != "${EXPECTED_PERMISSIONS}" ]; then
        echo "Updating permissions for BITBUCKET_HOME"
        chmod -R 700 "${BITBUCKET_HOME}" &&
        chown -R "${RUN_USER}:${RUN_GROUP}" "${BITBUCKET_HOME}"
    fi
    # Now drop privileges
    exec su -s /bin/bash "${RUN_USER}" -c "${BITBUCKET_INSTALL_DIR}/bin/start-bitbucket.sh ${ARGS}"
else
    exec "${BITBUCKET_INSTALL_DIR}/bin/start-bitbucket.sh ${ARGS}"
fi
