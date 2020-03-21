#!/bin/bash
_DEFAULT_OE_INIT_BUILD_ENV="/var/build/poky/oe-init-build-env"
OE_INIT_BUILD_ENV="${OE_INIT_BUILD_ENV-${_DEFAULT_OE_INIT_BUILD_ENV}}"
if [ -f "${OE_INIT_BUILD_ENV}" ]; then
    # shellcheck disable=SC1090
    source "${OE_INIT_BUILD_ENV}"
fi

exec "$@"
