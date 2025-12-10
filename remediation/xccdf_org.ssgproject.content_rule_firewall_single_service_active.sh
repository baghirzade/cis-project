#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_firewall_single_service_active"

echo "[*] Applying remediation for: $RULE_ID (Ensure only a single firewall service is active)"

# Check platform applicability (e.g., Debian/Ubuntu)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not available. Remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# List of common firewall services
FIREWALL_SERVICES=(
    "firewalld"
    "ufw"
    "iptables"
    "ip6tables"
)

# Services to be disabled/stopped
SERVICES_TO_DISABLE=()

# Determine the preferred firewall to keep active (firewalld > ufw)
PREFERRED_FIREWALL=""

if dpkg-query --show --showformat='${db:Status-Status}' "firewalld" 2>/dev/null | grep -q '^installed$'; then
    PREFERRED_FIREWALL="firewalld"
elif dpkg-query --show --showformat='${db:Status-Status}' "ufw" 2>/dev/null | grep -q '^installed$'; then
    PREFERRED_FIREWALL="ufw"
else
    echo "[!] Neither firewalld nor ufw is installed. No action taken to disable other services."
    exit 0
fi

echo "[*] Preferred firewall to keep active: $PREFERRED_FIREWALL"

# Identify services to disable (all except the preferred one)
for service in "${FIREWALL_SERVICES[@]}"; do
    if [ "$service" != "$PREFERRED_FIREWALL" ]; then
        # Check if the service package is installed or the service is active
        if dpkg-query --show --showformat='${db:Status-Status}' "$service" 2>/dev/null | grep -q '^installed$' || systemctl is-active "$service" &>/dev/null; then
            SERVICES_TO_DISABLE+=("$service")
        fi
    fi
done

config_changed=false

# Disable and stop unwanted firewall services
if [ "${#SERVICES_TO_DISABLE[@]}" -gt 0 ]; then
    echo "[*] Services to disable/stop: ${SERVICES_TO_DISABLE[*]}"
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        # Stop and disable the service
        if systemctl is-active "$service" &>/dev/null; then
            echo "[*] Stopping $service..."
            systemctl stop "$service" || true
            config_changed=true
        fi
        
        if systemctl is-enabled "$service" &>/dev/null; then
            echo "[*] Disabling $service..."
            systemctl disable "$service" || true
            config_changed=true
        fi
    done
fi

# Ensure the preferred firewall is enabled and running
if [ "$PREFERRED_FIREWALL" != "" ]; then
    if ! systemctl is-enabled "$PREFERRED_FIREWALL" &>/dev/null; then
        echo "[*] Enabling $PREFERRED_FIREWALL..."
        systemctl enable "$PREFERRED_FIREWALL" || true
        config_changed=true
    fi
    
    if ! systemctl is-active "$PREFERRED_FIREWALL" &>/dev/null; then
        echo "[*] Starting $PREFERRED_FIREWALL..."
        systemctl start "$PREFERRED_FIREWALL" || true
        config_changed=true
    fi
fi

if $config_changed; then
    echo "[+] Remediation complete: Only $PREFERRED_FIREWALL should be active."
else
    echo "[+] No conflicting firewall services were found or changes were required."
fi

