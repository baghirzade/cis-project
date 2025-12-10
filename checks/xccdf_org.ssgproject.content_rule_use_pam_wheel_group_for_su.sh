#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_use_pam_wheel_group_for_su"
PAM_CONF="/etc/pam.d/su"
var_pam_wheel_group_for_su='sugroup'

# libpam-runtime yoxdursa — qayda tətbiq olunmur
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|${RULE_ID}|Package 'libpam-runtime' is not installed"
    exit 0
fi

# /etc/pam.d/su yoxdursa — NOTAPPL
if [ ! -f "$PAM_CONF" ]; then
    echo "NOTAPPL|${RULE_ID}|${PAM_CONF} not found"
    exit 0
fi

# Yalnız uncomment sətirləri nəzərə alaq
pam_line=$(grep -P '^\s*auth\s+required\s+pam_wheel\.so\b' "$PAM_CONF" | grep -v '^\s*#' | head -n1)

if [ -n "$pam_line" ] && \
   echo "$pam_line" | grep -q '\buse_uid\b' && \
   echo "$pam_line" | grep -q "group=${var_pam_wheel_group_for_su}"; then
    echo "OK|${RULE_ID}|su is configured to require pam_wheel.so with use_uid and group=${var_pam_wheel_group_for_su}"
else
    echo "WARN|${RULE_ID}|pam_wheel.so line for su is missing or not using use_uid group=${var_pam_wheel_group_for_su}"
fi

exit 0
