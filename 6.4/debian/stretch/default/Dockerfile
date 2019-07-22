FROM nicoherbigio/adoptopenjdk-openjdk:8u212

LABEL maintainer="Nico Herbig <nico@nicoherbig.io>"


# Install additional required software packages

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl fontconfig git openssh-server openssl perl procps wget \
    && rm -rf /var/lib/apt/lists/*


# Install Tini

ARG TINI_VERSION=0.18.0
ARG TINI_DOWNLOAD_URL=https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini

RUN set -ex \
    && curl -fSL ${TINI_DOWNLOAD_URL} -o /sbin/tini \
    && chmod +x /sbin/tini


# Add Atlassian Bitbucket Server user and group to ensure that the IDs (UID and GID)
# are consistently assigned regardless of which additional dependencies are added.

ENV RUN_USER_ID=901 RUN_USER=bitbucket
ENV RUN_GROUP_ID=901 RUN_GROUP=bitbucket

RUN groupadd -r -g ${RUN_GROUP_ID} ${RUN_GROUP} && useradd -r -g ${RUN_GROUP} -u ${RUN_USER_ID} ${RUN_USER}


# Install Atlassian Bitbucket Server

ARG BITBUCKET_VERSION=6.4.1
ARG BITBUCKET_DOWNLOAD_URL=https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz

ENV BITBUCKET_INSTALL_DIR=/opt/atlassian/bitbucket
ENV BITBUCKET_HOME=/var/atlassian/bitbucket

# Actions to perform:
#   - Create installation directory
#   - Create home directory
#   - Download and unpack Atlassian Bitbucket Server
#   - Set permissions for the Bitbucket installation directory
#   - Set permissions for the Bitbucket home directory
RUN set -ex \
    && mkdir -p ${BITBUCKET_INSTALL_DIR} \
    && mkdir -p ${BITBUCKET_HOME} \
    && curl -fSL ${BITBUCKET_DOWNLOAD_URL} | tar -xz --no-same-owner --strip-components=1 -C ${BITBUCKET_INSTALL_DIR} \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR} \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_HOME}


# Configure Atlassian Bitbucket Server

VOLUME ${BITBUCKET_HOME}

COPY assets/docker-entrypoint.sh /usr/local/bin/

RUN set -ex \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && ln -s usr/local/bin/docker-entrypoint.sh /

EXPOSE 7990
EXPOSE 7999

WORKDIR ${BITBUCKET_HOME}

CMD ["/docker-entrypoint.sh", "-fg"]
ENTRYPOINT ["/sbin/tini", "--"]
