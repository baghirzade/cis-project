#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_use_pam_wheel_group_for_su"
PAM_CONF="/etc/pam.d/su"
var_pam_wheel_group_for_su='sugroup'

# libpam-runtime yoxdursa — heç nə etmirik
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    exit 0
fi

# /etc/pam.d/su yoxdursa — heç nə etmirik
if [ ! -f "$PAM_CONF" ]; then
    exit 0
fi

# Group mövcuddursa keç, yoxdursa yarat
if ! getent group "${var_pam_wheel_group_for_su}" >/dev/null 2>&1; then
    /usr/sbin/groupadd "${var_pam_wheel_group_for_su}" 2>/dev/null || true
fi

# Mövcud, uncomment pam_wheel.so sətrlərini sil
sed -Ei '/^\s*auth\s+.*pam_wheel\.so\b/ s/^/#&/' "$PAM_CONF"
sed -Ei '/^\s*auth\s+required\s+pam_wheel\.so\b/ d' "$PAM_CONF"

# pam_rootok.so sətrindən sonra düzgün pam_wheel.so sətrini əlavə et
if grep -Pq '^\s*auth\s+sufficient\s+pam_rootok\.so\b' "$PAM_CONF"; then
    sed -Ei "/^\s*auth\s+sufficient\s+pam_rootok\.so\b/a auth             required        pam_wheel.so use_uid group=${var_pam_wheel_group_for_su}" "$PAM_CONF"
else
    # Əgər pam_rootok yoxdur, faylın əvvəlinə əlavə edək ki, işlək olsun
    sed -i "1i auth             required        pam_wheel.so use_uid group=${var_pam_wheel_group_for_su}" "$PAM_CONF"
fi

exit 0
