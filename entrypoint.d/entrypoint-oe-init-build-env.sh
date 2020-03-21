#!/bin/bash
OEROOT="${OEROOT-/var/build/poky}"
if [ -f "${OEROOT}/oe-init-build-env" ]; then
    # shellcheck disable=SC1090
    source "${OEROOT}/oe-init-build-env"
fi

exec "$@"
