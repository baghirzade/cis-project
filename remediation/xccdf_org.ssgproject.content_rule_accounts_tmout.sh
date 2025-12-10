#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_tmout"

# Remediation yalnız linux-base olduqda tətbiq olunur
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

    var_accounts_tmout='900'

    # 0 = TMOUT tapılmadı, 1 = ən azı bir faylda TMOUT var
    tmout_found=0

    for f in /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh; do
        [ -f "$f" ] || continue

        if grep --silent '^[[:space:]]*TMOUT' "$f"; then
            sed -i -E "s/^([[:space:]]*)TMOUT[[:space:]]*=[[:space:]]*([^[:space:]]*)(.*)$/\1TMOUT=${var_accounts_tmout}\3/g" "$f"
            tmout_found=1
            if ! grep --silent '^[[:space:]]*readonly[[:space:]]+TMOUT\b' "$f" ; then
                echo "readonly TMOUT" >> "$f"
            fi
            if ! grep --silent '^[[:space:]]*export[[:space:]]+TMOUT\b' "$f" ; then
                echo "export TMOUT" >> "$f"
            fi
        fi
    done

    OLD_UMASK=$(umask)
    umask u=rw,go=r

    if [ "$tmout_found" -eq 0 ]; then
        mkdir -p /etc/profile.d
        {
            echo ""
            echo "# Set TMOUT to ${var_accounts_tmout} per security requirements"
            echo "TMOUT=${var_accounts_tmout}"
            echo "readonly TMOUT"
            echo "export TMOUT"
        } >> /etc/profile.d/tmout.sh
    fi

    umask "$OLD_UMASK"

fi

exit 0
