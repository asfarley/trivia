#!/usr/bin/env bash
# Wrapper that works around two WSL/Windows-filesystem limitations:
#
#  1. ansible.cfg is ignored when the directory is world-writable (/mnt/d/...).
#     Fix: export ANSIBLE_CONFIG explicitly.
#
#  2. SSH rejects private keys on the Windows filesystem because chmod has no
#     effect there — permissions are always reported as too open (0555).
#     Fix: copy the key to a Linux tmpfs, chmod 400, and delete it on exit.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_SRC="${SCRIPT_DIR}/../.credentials/trivia.pem"

# Run from the ansible/ directory so relative paths in ansible.cfg
# (inventory, roles) resolve correctly regardless of where the script
# was invoked from.
cd "${SCRIPT_DIR}"

# Stage key on the Linux filesystem with correct permissions.
TMPKEY="$(mktemp /tmp/trivia-deploy-key.XXXXXX)"
trap 'rm -f "${TMPKEY}"' EXIT
cp "${KEY_SRC}" "${TMPKEY}"
chmod 400 "${TMPKEY}"

export ANSIBLE_CONFIG="${SCRIPT_DIR}/ansible.cfg"

exec ansible-playbook "${SCRIPT_DIR}/playbook.yml" \
  --private-key "${TMPKEY}" \
  "$@"
