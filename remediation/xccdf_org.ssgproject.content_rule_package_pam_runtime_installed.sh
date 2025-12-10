#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_pam_runtime_installed"

echo "[*] Applying remediation for: $RULE_ID (ensure libpam-runtime is installed)"

(>&2 echo "Remediating rule 36/405: 'xccdf_org.ssgproject.content_rule_package_pam_runtime_installed'")

DEBIAN_FRONTEND=noninteractive apt-get install -y "libpam-runtime"
