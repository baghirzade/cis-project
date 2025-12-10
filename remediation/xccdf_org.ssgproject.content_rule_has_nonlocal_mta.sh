#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_has_nonlocal_mta"

echo "[*] Remediation for $RULE_ID"

# No automated remediation exists for this rule.
# Administrator must install and configure a non-local MTA manually.

echo "[!] No automated fix available. Please install a non-local MTA (e.g., postfix, exim4, sendmail)."

exit 0
