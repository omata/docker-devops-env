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

# Fix ownership of home directory only, without crossing into bind-mounted
# volumes (src, tmp, .ssh subdirectories) to avoid slow chown on large trees.
find "/home/${DEVOPS_USER}" -mount -maxdepth 3 \
    ! -user "${TARGET_UID}" -exec chown "${TARGET_UID}:${TARGET_GID}" {} +

# Clean up stale ssh-agent sockets from previous runs
rm -f /tmp/ssh-agent.sock

# Start ssh-agent as the target user with a fixed socket path so that
# .bashrc can set SSH_AUTH_SOCK reliably and the socket is owned by devops.
gosu "${DEVOPS_USER}" ssh-agent -a /tmp/ssh-agent.sock > /dev/null

# Hand off to a login shell as the target user
exec gosu "${DEVOPS_USER}" /bin/bash -l
