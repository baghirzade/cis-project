#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_account_unique_name"

(>&2 echo "Remediating: ${RULE_ID}")
(>&2 echo "Automatic remediation is not implemented for this rule.")
(>&2 echo "Please review duplicate user account names in /etc/passwd and correct them manually (e.g. via usermod/userdel).")

exit 0
