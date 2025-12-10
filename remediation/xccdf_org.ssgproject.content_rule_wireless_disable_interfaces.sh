#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_wireless_disable_interfaces"
echo "[*] Applying remediation for: $RULE_ID"

# Containers are excluded
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[!] Container environment detected — skipping"
    exit 0
fi

wireless_dirs=$(find /sys/class/net/*/ -type d -name wireless 2>/dev/null)

if [[ -z "$wireless_dirs" ]]; then
    echo "[*] No wireless interfaces found — nothing to disable"
    exit 0
fi

MODPROBE_CONF="/etc/modprobe.d/disable_wireless.conf"
touch "$MODPROBE_CONF"

for wdir in $wireless_dirs; do
    iface=$(basename "$(dirname "$wdir")")

    echo "[*] Disabling wireless interface: $iface"
    ip link set dev "$iface" down || true

    driver=$(basename "$(readlink -f /sys/class/net/$iface/device/driver)" || true)

    if [[ -n "$driver" ]]; then
        echo "[*] Blocking driver: $driver"
        if ! grep -q "^install $driver /bin/false" "$MODPROBE_CONF"; then
            echo "install $driver /bin/false" >> "$MODPROBE_CONF"
        fi

        modprobe -r "$driver" 2>/dev/null || true
    fi
done

echo "[+] Remediation complete: Wireless interfaces disabled and drivers blocked"
