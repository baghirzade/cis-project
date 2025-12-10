#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_root_gid_zero"

if [[ ! -r /etc/passwd ]]; then
    >&2 echo "Remediation for ${RULE_ID} failed: /etc/passwd is not readable"
    exit 1
fi

if ! id root &>/dev/null; then
    >&2 echo "Remediation for ${RULE_ID} failed: root account does not exist"
    exit 1
fi

# Verify group with GID 0 exists
if ! getent group 0 >/dev/null 2>&1; then
    >&2 echo "Remediation for ${RULE_ID} failed: no group with GID 0 exists on the system"
    exit 1
fi

current_gid="$(getent passwd root | awk -F: '{print $4}')"

if [[ -z "${current_gid}" ]]; then
    >&2 echo "Remediation for ${RULE_ID} failed: unable to determine current root GID"
    exit 1
fi

# If already 0, nothing to change
if [[ "${current_gid}" == "0" ]]; then
    exit 0
fi

# Change root primary group to GID 0
if ! usermod -g 0 root; then
    >&2 echo "Remediation for ${RULE_ID} failed: could not change root primary GID to 0"
    exit 1
fi

exit 0
