#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_nftables_ensure_default_deny_policy"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure nftables is installed
if ! command -v nft >/dev/null 2>&1; then
    echo "[!] nftables not installed — cannot enforce policy"
    exit 0
fi

NFT_CONF="/etc/nftables.conf"

echo "[*] Enforcing default deny (drop) policy for nftables..."

# Create secure nftables configuration
cat << 'EOF2' > "$NFT_CONF"
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;
    }

    chain output {
        type filter hook output priority 0;
        policy drop;
    }
}
EOF2

# Apply ruleset
echo "[*] Loading updated ruleset..."
nft -f "$NFT_CONF"

# Enable service if needed (default deny must persist)
if systemctl list-unit-files | grep -q "^nftables.service"; then
    systemctl enable nftables.service
    systemctl restart nftables.service
fi

echo "[+] Remediation complete: nftables default policy set to DROP"
