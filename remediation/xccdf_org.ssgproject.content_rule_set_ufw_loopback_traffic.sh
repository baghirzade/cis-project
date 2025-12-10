#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_ufw_loopback_traffic"

echo "[*] Applying remediation for: $RULE_ID (Configure ufw loopback traffic)"

# Remediation is applicable only if ufw and linux-base packages are installed
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' && { dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; }; then

# Check if ufw is active. If not, activating rules may not take effect immediately or may require ufw enable.
if [ "$(ufw status | head -n 1 | awk '{print $2}')" != "active" ]; then
    echo "[!] WARNING: ufw is not active. Rules will be added but may not take effect until 'ufw enable' is run."
fi

# 1. Allow inbound traffic on lo
echo "    -> Allowing inbound traffic on lo"
ufw allow in on lo

# 2. Allow outbound traffic on lo
echo "    -> Allowing outbound traffic on lo"
ufw allow out on lo

# 3. Deny inbound traffic from 127.0.0.0/8 (IPv4 spoofing)
# Note: The 'delete' attempts are to prevent accumulating duplicate rules, especially if the policy changes.
if ufw status | grep -q "deny in from 127.0.0.0/8"; then
    echo "    -> IPv4 Loopback Deny rule already exists (skipping add)."
else
    echo "    -> Denying inbound from 127.0.0.0/8"
    ufw deny in from 127.0.0.0/8
fi

# 4. Deny inbound traffic from ::1 (IPv6 spoofing)
if ufw status | grep -q "deny in from ::1"; then
    echo "    -> IPv6 Loopback Deny rule already exists (skipping add)."
else
    echo "    -> Denying inbound from ::1"
    ufw deny in from ::1
fi

echo "[+] Remediation complete: ufw loopback traffic configured."

else
    >&2 echo 'Remediation is not applicable, ufw is not installed or platform check failed.'
fi
