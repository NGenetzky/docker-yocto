# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
#
# https://github.com/phusion/baseimage-docker/releases
#
# Choose the latest LTS for the version of yocto that you would like to use.
# https://yoctoproject.org/docs/2.5/ref-manual/ref-manual.html#detailed-supported-distros
#
# ___________________________________________________________
# | Yocto | Ubuntu LTS | Phusion | Notes from Phusion       |
# |-------|------------|---------|--------------------------|
# |  3.1  |   18.04    |  0.11   | released on Aug 16, 2018 |
# |  3.0  |   18.04    |  0.11   | released on Aug 16, 2018 |
# |  2.7  |   16.04    | 0.9.22  | released on May 17, 2017 |
# |  2.6  |   16.04    | 0.9.22  | released on May 17, 2017 |
# |  2.5  |   16.04    | 0.9.22  | released on May 17, 2017 |
# |  2.4  |   14.04    | 0.9.18  | released on Mar 21, 2017 |
# |  1.8  |   14.04    | 0.9.18  | released on Mar 21, 2017 |
#
#
FROM phusion/baseimage:0.9.22

# Using "ARG" influences the behavior of apt only while building container.
# No Debian that's a bad Debian! We don't have an interactive prompt don't fail
ARG DEBIAN_FRONTEND=noninteractive
# ensure our rebuilds remain stable
ARG APT_GET_UPDATE=2018-07-24

# Yocto's depends
# plus some debugging utils
# We don't use phusion's "install_clean" because we want portability.
# Package list should be super set of the following:
# https://yoctoproject.org/docs/2.5/ref-manual/ref-manual.html#required-packages-for-the-build-host
RUN apt-get --quiet --yes update \
    # We first install these packages, to avoid skipping package configuration
    && apt-get -y install --no-install-recommends \
        apt-utils \
        dialog \
    # Then we install Minimum requirements for yocto
    # plus some debugging utils
    && apt-get --quiet --yes install \
        build-essential \
        chrpath \
        cpio \
        curl \
        debianutils \
        diffstat \
        gawk \
        gcc-multilib \
        git-core \
        iputils-ping \
        libsdl1.2-dev \
        libssl-dev \
        ltrace\
        python \
        python3-pexpect \
        python3-pip \
        socat \
        strace \
        sudo \
        texinfo \
        tmux \
        unzip \
        wget \
        xterm \
        xz-utils \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set the default shell to bash instead of dash
RUN echo "dash dash/sh boolean false" | debconf-set-selections && dpkg-reconfigure dash


ARG WORKDIR_AND_HOME='/var/build'
RUN install -d \
    "${WORKDIR_AND_HOME}" \
    '/etc/entrypoint.d/' \
    '/etc/my_init.d/'

# phusion specific magic starts here. Must use FROM 'phusion/*'.
#
# - init scripts (/etc/my_init.d/)
# - init process (/sbin/my_init)

# workaround HOME ignore. see https://github.com/phusion/baseimage-docker/issues/119
RUN echo "${WORKDIR_AND_HOME}" > /etc/container_environment/HOME

# utilize my_init from the baseimage to create the user for us
# the reason this is dynamic is so that the caller of the container
# gets the UID:GID they need/want made for them
ADD create-user.sh /etc/my_init.d/create-user.sh

# Use baseimage-docker's init to execute our custom entrypoint.
# Our custom entrypoint allows "CMD" to be executed by the "BUILDUSER".
# Additionally, the "plugin" nature allows us to utilze 'oe-init-build-env'.
# The post below describes the motivation of 'my_init'
# https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
COPY entrypoint.sh /sbin/entrypoint
COPY entrypoint.d/ /etc/entrypoint.d/
ENTRYPOINT ["/sbin/my_init", "--", "/sbin/entrypoint"]

# phusion specific magic ends here.

# If you need to add more packages, just do additional RUN commands here
# this is so that layers above to not have to be regenerated.

# Where we build
WORKDIR "${WORKDIR_AND_HOME}"

# docker-hub environment-variables
# https://docs.docker.com/docker-hub/builds/advanced/#environment-variables-for-building-and-testing
#
# SOURCE_BRANCH: the name of the branch or the tag that is currently being tested.
# SOURCE_COMMIT: the SHA1 hash of the commit being tested.
# COMMIT_MSG: the message from the commit being tested and built.
# DOCKER_REPO: the name of the Docker repository being built.
# DOCKERFILE_PATH: the dockerfile currently being built.
# DOCKER_TAG: the Docker repository tag being built.
# IMAGE_NAME: the name and tag of the Docker repository being built. (This variable is a combination of DOCKER_REPO:DOCKER_TAG.)
ARG SOURCE_BRANCH='unknown-branch'
ARG SOURCE_COMMIT='unknown-commit'
ARG DOCKER_REPO='ngenetzky/yocto'
ARG DOCKERFILE_PATH='Dockerfile'
ARG DOCKER_TAG='latest'
ARG IMAGE_NAME="${DOCKER_REPO}:${DOCKER_TAG}"

# Programatic Metadata
# TODO: BUILD_DATE
ARG BUILD_DATE='unknown-date'

# Hardcoded Metadata
ARG META_VCS_URL='https://github.com/ngenetzky/docker-yocto'
ARG META_SUMMARY='Docker environment to be able to build Yocto'
ARG META_AUTHORS='\
Nathan Genetzky <n@genetzky.us>\
,Derek Straka <derek@asterius.io>\
,Doug Goldstein <cardoe@cardoe.com>\
'

# Yocto Metadata
# https://wiki.yoctoproject.org/wiki/Releases

# Build-time metadata as defined at http://label-schema.org
LABEL \
    maintainer="Nathan Genetzky <n@genetzky.us>" \
    summary="${META_SUMMARY}" \
    description="${META_SUMMARY}" \
    authors="$META_AUTHORS" \
    url="$META_VCS_URL" \
    \
    org.label-schema.build-date="$BUILD_DATE" \
    org.label-schema.name="$IMAGE_NAME" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-ref="$SOURCE_COMMIT" \
    org.label-schema.vcs-url="$META_VCS_URL" \
    org.label-schema.version="$SOURCE_COMMIT" \
