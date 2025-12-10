#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_tmout"
var_accounts_tmout='900'

# linux-base paketi yoxdursa - qayda tətbiq olunmur
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|${RULE_ID}|Package 'linux-base' is not installed"
    exit 0
fi

files=(/etc/bash.bashrc /etc/profile /etc/profile.d/*.sh)

tmout_any_found=0
min_tmout_value=""
readonly_ok=1
export_ok=1

for f in "${files[@]}"; do
    [ -f "$f" ] || continue

    # TMOUT dəyərini tap
    line=$(grep -E '^[[:space:]]*TMOUT[[:space:]]*=[[:space:]]*[0-9]+' "$f" 2>/dev/null | head -n1)
    if [ -n "$line" ]; then
        tmout_any_found=1
        value=$(echo "$line" | sed -E 's/^[[:space:]]*TMOUT[[:space:]]*=[[:space:]]*([0-9]+).*/\1/')
        if [ -z "$min_tmout_value" ] || [ "$value" -lt "$min_tmout_value" ]; then
            min_tmout_value="$value"
        fi

        # Həmin faylda readonly TMOUT varmı
        if ! grep -Eq '^[[:space:]]*readonly[[:space:]]+TMOUT\b' "$f"; then
            readonly_ok=0
        fi

        # Həmin faylda export TMOUT varmı
        if ! grep -Eq '^[[:space:]]*export[[:space:]]+TMOUT\b' "$f"; then
            export_ok=0
        fi
    fi
done

if [ "$tmout_any_found" -eq 0 ]; then
    echo "WARN|${RULE_ID}|TMOUT is not set in any of /etc/bash.bashrc, /etc/profile or /etc/profile.d/*.sh"
    exit 0
fi

if [ "$min_tmout_value" -le "$var_accounts_tmout" ] && [ "$readonly_ok" -eq 1 ] && [ "$export_ok" -eq 1 ]; then
    echo "OK|${RULE_ID}|TMOUT is set (<= ${var_accounts_tmout}) and marked readonly+export in shell init files"
else
    msg="TMOUT configuration is not compliant: "
    msg+="min(TMOUT)=${min_tmout_value}, required<=${var_accounts_tmout}; "
    [ "$readonly_ok" -eq 1 ] || msg+="missing 'readonly TMOUT'; "
    [ "$export_ok" -eq 1 ] || msg+="missing 'export TMOUT'; "
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
