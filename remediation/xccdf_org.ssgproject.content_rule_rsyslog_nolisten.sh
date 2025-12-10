#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_rsyslog_nolisten"

echo "[*] Applying remediation for: $RULE_ID (Disable rsyslog network listening)"

# Remediation is applicable only in certain platforms and if rsyslog is active
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' && { systemctl is-active rsyslog &>/dev/null; }; then

# Regex for legacy format (e.g., $ModLoad imtcp, $InputTCPServerRun)
legacy_regex='^\s*\$(((Input(TCP|RELP)|UDP)ServerRun)|ModLoad\s+(imtcp|imudp|imrelp))'
# Regex for Rainer format (e.g., module(load="imtcp"), input(type="imudp"))
rainer_regex='^\s*(module|input)\((load|type)="(imtcp|imudp|imrelp)".*$'

# Find configuration files containing active listening directives
readarray -t legacy_targets < <(grep -l -E -r -v '^\s*#' "${legacy_regex[@]}" /etc/rsyslog.conf /etc/rsyslog.d/ 2>/dev/null)
readarray -t rainer_targets < <(grep -l -E -r -v '^\s*#' "${rainer_regex[@]}" /etc/rsyslog.conf /etc/rsyslog.d/ 2>/dev/null)

config_changed=false

# 1. Comment out legacy format directives
if [ ${#legacy_targets[@]} -gt 0 ]; then
    echo "[*] Commenting out legacy rsyslog network directives in: ${legacy_targets[*]}"
    for target in "${legacy_targets[@]}"; do
        # Use sed to prepend '#' to matching lines
        sed -E -i "/$legacy_regex/ s/^/# /" "$target"
    done
    config_changed=true
fi

# 2. Comment out Rainer format directives
if [ ${#rainer_targets[@]} -gt 0 ]; then
    echo "[*] Commenting out Rainer rsyslog network directives in: ${rainer_targets[*]}"
    for target in "${rainer_targets[@]}"; do
        # Use sed to prepend '#' to matching lines
        sed -E -i "/$rainer_regex/ s/^/# /" "$target"
    done
    config_changed=true
fi

# Restart rsyslog service if any configuration change was made
if $config_changed; then
    echo "[+] rsyslog configuration changed. Restarting rsyslog.service..."
    systemctl restart rsyslog.service
    echo "[+] rsyslog.service restarted."
else
    echo "[+] No active rsyslog network listening directives found. No changes made."
fi

else
    echo "[!] Remediation is not applicable (Check: 'linux-base' installed and rsyslog inactive). No changes applied."
fi
