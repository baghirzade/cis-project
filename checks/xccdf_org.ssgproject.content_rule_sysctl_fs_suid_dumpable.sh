#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_fs_suid_dumpable"

run() {

    # Check runtime value
    RUNTIME_VALUE="$(sysctl -n fs.suid_dumpable 2>/dev/null || echo "")"
    if [[ "$RUNTIME_VALUE" != "0" ]]; then
        echo "WARN|$RULE_ID|Runtime sysctl fs.suid_dumpable != 0"
        exit 1
    fi

    # Check configuration in /etc/sysctl.conf or drop-ins
    CONFIG_FOUND=0

    for f in /etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf; do
        [[ -f "$f" ]] || continue
        # ignore commented lines
        if grep -Eq '^\s*fs.suid_dumpable\s*=\s*0\s*$' "$f"; then
            CONFIG_FOUND=1
            break
        fi
    done

    if [[ $CONFIG_FOUND -eq 1 ]]; then
        echo "OK|$RULE_ID|fs.suid_dumpable configured to 0"
        exit 0
    else
        echo "WARN|$RULE_ID|fs.suid_dumpable not configured"
        exit 1
    fi
}

run
