#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_kernel_randomize_va_space"

run() {

    # Check runtime value
    RUNTIME_VALUE="$(sysctl -n kernel.randomize_va_space 2>/dev/null || echo "")"
    if [[ "$RUNTIME_VALUE" != "2" ]]; then
        echo "WARN|$RULE_ID|Runtime sysctl kernel.randomize_va_space != 2"
        exit 1
    fi

    # Check config presence
    CONFIG_FOUND=0

    for f in /etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
        [[ -f "$f" ]] || continue
        if grep -Eq '^\s*kernel.randomize_va_space\s*=\s*2\s*$' "$f"; then
            CONFIG_FOUND=1
            break
        fi
    done

    if [[ "$CONFIG_FOUND" -eq 1 ]]; then
        echo "OK|$RULE_ID|kernel.randomize_va_space configured to 2"
        exit 0
    else
        echo "WARN|$RULE_ID|kernel.randomize_va_space not configured"
        exit 1
    fi
}

run
