#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_partition_for_tmp"

echo "[*] Remediation requested for: $RULE_ID"
/bin/echo "[!] No automated remediation is implemented for this control."
/bin/echo "[!] Creating or modifying a dedicated /tmp partition requires manual review, backup, and planning."
/bin/echo "[!] Please configure a separate entry for /tmp in /etc/fstab (and underlying partition or tmpfs) according to your environment."