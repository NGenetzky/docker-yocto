#!/bin/bash
# the fallback is 580/580 which happily mapped properly under Docker
# for Mac back to my real uid/gid.
_DEFAULT_BUILD_UID=580
_DEFAULT_BUILD_GID=580
_DEFAULT_BUILD_HOME=/var/build
_DEFAULT_BUILD_UNAME='builduser'
_DEFAULT_BUILD_GNAME='buildgroup'
_DEFAULT_BUILD_SHELL='/bin/bash'

BUILD_HOME="${BUILD_HOME:-${_DEFAULT_BUILD_HOME}}"

# If not explcitly given then programatically use owner of BUILD_HOME.
# figure out the uid/gid we need to use by integrating the path that has
# been bind mounted in. this is then used for the builduser.
if [ -z "${BUILD_UID}" ]; then
	BUILD_UID=$(stat --printf=%u "${BUILD_HOME}" 2> /dev/null)
fi
if [ -z "${BUILD_GID}" ]; then
	BUILD_GID=$(stat --printf=%g "${BUILD_HOME}" 2> /dev/null)
fi

BUILD_UID=${BUILD_UID:-${_DEFAULT_BUILD_UID}}
BUILD_GID=${BUILD_GID:-${_DEFAULT_BUILD_GID}}
BUILD_UID=${BUILD_UID/#0/580}
BUILD_GID=${BUILD_GID/#0/580}

# create a group
groupadd --gid "${BUILD_GID}" --non-unique "${_DEFAULT_BUILD_GNAME}"

# create a non-root user
useradd --no-create-home --home-dir "${BUILD_HOME}" -s "${_DEFAULT_BUILD_SHELL}" \
	--non-unique --uid "${BUILD_UID}" --gid "${BUILD_GID}" --groups sudo \
	"${_DEFAULT_BUILD_UNAME}"

# give users in the sudo group sudo access without password in the container
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
