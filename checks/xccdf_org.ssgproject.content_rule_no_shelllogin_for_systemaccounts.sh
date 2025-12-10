#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_shelllogin_for_systemaccounts"

# /etc/passwd yoxdursa, qayda tətbiq olunmur
if [ ! -f /etc/passwd ]; then
    echo "NOTAPPL|${RULE_ID}|/etc/passwd not found (cannot evaluate system accounts)"
    exit 0
fi

# System account: UID < 1000, root deyil
# İcazə verilən login olmayan shell-lər:
#   /sbin/nologin, /usr/sbin/nologin, /bin/false, /sbin/shutdown, /sbin/halt, /bin/sync

mapfile -t bad_accounts < <(
    awk -F: '
        ($3 < 1000 && $1 != "root" &&
         $7 !~ /^(\/sbin\/nologin|\/usr\/sbin\/nologin|\/bin\/false|\/sbin\/shutdown|\/sbin\/halt|\/bin\/sync)$/) {
            print $1 ":" $7
        }' /etc/passwd
)

if [ "${#bad_accounts[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All system accounts (UID < 1000, except root) have non-login shells"
else
    echo "WARN|${RULE_ID}|System accounts with interactive shells found: ${bad_accounts[*]}"
fi

exit 0
