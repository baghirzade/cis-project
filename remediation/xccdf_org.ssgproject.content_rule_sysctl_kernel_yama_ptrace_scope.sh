#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_kernel_yama_ptrace_scope"
echo "[*] Remediating: $RULE_ID"

# Rule applies only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] linux-base not installed → remediation skipped."
    exit 0
fi

TARGET_VALUE="1"
SYSCTL_FILE="/etc/sysctl.conf"

# -----------------------------------------------------------------------------
# 1. Comment out conflicting entries in sysctl.d directories
# -----------------------------------------------------------------------------
for f in /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do

    # Skip symlink to /etc/sysctl.conf
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then
        continue
    fi

    if [[ -f "$f" ]]; then
        matches=$(grep -P '^(?!#).*[\s]*kernel.yama.ptrace_scope.*$' "$f" || true)

        if [[ -n "$matches" ]]; then
            while IFS= read -r line; do
                esc=$(sed 's/[\/&]/\\&/g' <<< "$line")
                sed -i --follow-symlinks "s/^${esc}$/# &/g" "$f"
            done <<< "$matches"
        fi
    fi
done


# -----------------------------------------------------------------------------
# 2. Apply runtime value
# -----------------------------------------------------------------------------
sysctl -q -w kernel.yama.ptrace_scope="$TARGET_VALUE"


# -----------------------------------------------------------------------------
# 3. Persist change in /etc/sysctl.conf
# -----------------------------------------------------------------------------
if grep -qiE "^kernel.yama.ptrace_scope\\>" "$SYSCTL_FILE"; then
    sed -i --follow-symlinks \
        "s/^kernel.yama.ptrace_scope\\>.*/kernel.yama.ptrace_scope = ${TARGET_VALUE}/I" \
        "$SYSCTL_FILE"
else
    # Ensure final newline exists
    if [[ -s "$SYSCTL_FILE" ]] && [[ -n "$(tail -c 1 "$SYSCTL_FILE")" ]]; then
        echo "" >> "$SYSCTL_FILE"
    fi
    echo "kernel.yama.ptrace_scope = ${TARGET_VALUE}" >> "$SYSCTL_FILE"
fi

echo "[+] Remediation completed: $RULE_ID"
