#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_password_hashing_algorithm_systemauth"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1) libpam-runtime paketi quraşdırılıb?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

PAM_FILE="/etc/pam.d/common-password"

# 2) PAM faylı mövcuddur?
if [ ! -f "$PAM_FILE" ]; then
    print_result "WARN" "$PAM_FILE does not exist; pam_unix.so hashing algorithm is not configured"
    exit 0
fi

# 3) pam_unix.so sətrini tap
mapfile -t pam_unix_lines < <(grep -E '^[[:space:]]*password[[:space:]].*pam_unix\.so' "$PAM_FILE" || true)

if [ "${#pam_unix_lines[@]}" -eq 0 ]; then
    print_result "WARN" "No pam_unix.so password lines found in $PAM_FILE"
    exit 0
fi

joined_lines=$(printf "%s\n" "${pam_unix_lines[@]}")

# 4) yescrypt istifadə olunur?
if ! grep -qE '\byescrypt\b' <<< "$joined_lines"; then
    print_result "WARN" "pam_unix.so in $PAM_FILE does not use yescrypt (expected yescrypt hashing algorithm)"
    exit 0
fi

# 5) Digər hash algoritmləri də qoşulubsa, xəbərdarlıq et
if grep -qE '\b(sha512|sha256|md5|blowfish|bigcrypt|gost_yescrypt)\b' <<< "$joined_lines"; then
    print_result "WARN" "pam_unix.so in $PAM_FILE uses yescrypt together with other hashing options (expected only yescrypt)"
    exit 0
fi

print_result "OK" "pam_unix.so in $PAM_FILE uses yescrypt as the password hashing algorithm"
