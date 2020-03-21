# See https://github.com/phusion/baseimage-docker
FROM phusion/baseimage:0.9.22

MAINTAINER Derek Straka <derek@asterius.io>

# Using "ARG" influences the behavior of apt only while building container.
# No Debian that's a bad Debian! We don't have an interactive prompt don't fail
ARG DEBIAN_FRONTEND=noninteractive
# ensure our rebuilds remain stable
ARG APT_GET_UPDATE=2018-07-24

# Yocto's depends
# plus some debugging utils
# We don't use phusion's "install_clean" because we want portability.
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
