#!/usr/bin/env sh
set -e

DEVOPS_USER="devops"
CURRENT_UID=$(id -u "${DEVOPS_USER}")
CURRENT_GID=$(id -g "${DEVOPS_USER}")
TARGET_UID="${PUID:-${CURRENT_UID}}"
TARGET_GID="${PGID:-${CURRENT_GID}}"

# Remap GID if needed
if [ "${TARGET_GID}" != "${CURRENT_GID}" ]; then
    groupmod -g "${TARGET_GID}" "${DEVOPS_USER}"
fi

# Remap UID if needed
if [ "${TARGET_UID}" != "${CURRENT_UID}" ]; then
    usermod -u "${TARGET_UID}" "${DEVOPS_USER}"
fi

# Fix ownership of home directory and mounted volumes
chown -R "${DEVOPS_USER}:${DEVOPS_USER}" "/home/${DEVOPS_USER}"

# Clean up stale ssh-agent sockets from previous runs
rm -rf /tmp/ssh-*

# Start ssh-agent in the background and export its environment variables
# so the login shell launched by gosu inherits them
eval "$(ssh-agent -s)" > /dev/null

# Hand off to a login shell as the target user, with ssh-agent env exported
exec gosu "${DEVOPS_USER}" /bin/bash -l
