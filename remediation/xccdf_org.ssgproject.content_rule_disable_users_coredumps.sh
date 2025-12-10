#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_disable_users_coredumps"
echo "[*] Remediating: $RULE_ID"

# Rule applies only if libpam-runtime exists
if ! dpkg-query --show --showformat='${db:Status-Status}' libpam-runtime 2>/dev/null | grep -q '^installed$'; then
    echo "[*] libpam-runtime not installed → remediation skipped."
    exit 0
fi

SECURITY_LIMITS_FILE="/etc/security/limits.conf"
DROPIN_DIR="/etc/security/limits.d"
DROPIN_FILE="$DROPIN_DIR/10-ssg-hardening.conf"
CORRECT_REGEX="^\s*\*\s+hard\s+core\s+0\s*$"

# --------------------------------------------------------------------
# 1. Comment out incorrect or conflicting definitions in drop-ins
# --------------------------------------------------------------------
if [ -d "$DROPIN_DIR" ]; then
    for f in "$DROPIN_DIR"/*.conf; do
        if [ -f "$f" ] && ! grep -qE "$CORRECT_REGEX" "$f"; then
            sed -i -r '/^[[:space:]]*\*[[:space:]]+hard[[:space:]]+core[[:space:]]+/ s/^/#/' "$f"
        fi
    done
fi

# If correct setting exists already in drop-ins OR in limits.conf → exit OK
if [ -d "$DROPIN_DIR" ] && grep -qEr "$CORRECT_REGEX" "$DROPIN_DIR"; then
    echo "[+] Correct entry already exists in drop-in."
    exit 0
elif [ ! -d "$DROPIN_DIR" ] && grep -qE "$CORRECT_REGEX" "$SECURITY_LIMITS_FILE"; then
    echo "[+] Correct entry exists in limits.conf."
    exit 0
fi

# --------------------------------------------------------------------
# 2. Create drop-in directory and correct config if missing
# --------------------------------------------------------------------
mkdir -p "$DROPIN_DIR"

echo "*     hard   core    0" >> "$DROPIN_FILE"

echo "[+] Added '* hard core 0' to $DROPIN_FILE"
echo "[+] Remediation completed: $RULE_ID"
