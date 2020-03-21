#!/bin/bash
BUILDUSER='builduser'

if [ $# -eq 0 ]; then
    /sbin/setuser "${BUILDUSER}" \
        bash -l
    exit $?
elif [ -f "/etc/entrypoint.d/$1" ]; then
    # Intentionally not calling 'shift'
    /sbin/setuser "${BUILDUSER}" \
        "/etc/entrypoint.d/$1" \
        "$@"
else
    /sbin/setuser "${BUILDUSER}" \
        "$@"
fi
exit $?
