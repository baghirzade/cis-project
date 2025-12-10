#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_default_secure_redirects"

echo "[*] Applying remediation for: $RULE_ID (Disable IPv4 secure ICMP redirects by default)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

# Target files for commenting out existing settings
CONFIG_FILES="/etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"
SYSCTL_KEY='net.ipv4.conf.default.secure_redirects'

echo "[*] Commenting out existing '${SYSCTL_KEY}' occurrences in config files..."

# Comment out any occurrences of net.ipv4.conf.default.secure_redirects from relevant config files
for f in $CONFIG_FILES; do
    # skip systemd-sysctl symlink (/etc/sysctl.d/99-sysctl.conf -> /etc/sysctl.conf)
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    matching_list=$(grep -P '^(?!#).*[\s]*net.ipv4.conf.default.secure_redirects.*$' $f | uniq )
    if ! test -z "$matching_list"; then
        while IFS= read -r entry; do
            escaped_entry=$(sed -e 's|/|\\/|g' <<< "$entry")
            # comment out "net.ipv4.conf.default.secure_redirects" matches to preserve user data
            sed -i --follow-symlinks "s/^${escaped_entry}$/# &/g" "$f"
        done <<< "$matching_list"
    fi
done

#
# Set sysctl config file which to save the desired value
#

SYSCONFIG_FILE="/etc/sysctl.conf"

sysctl_net_ipv4_conf_default_secure_redirects_value='0'


#
# Set runtime for net.ipv4.conf.default.secure_redirects
#
echo "[*] Setting runtime value to $sysctl_net_ipv4_conf_default_secure_redirects_value"
if ! /bin/false ; then
    /sbin/sysctl -q -n -w net.ipv4.conf.default.secure_redirects="$sysctl_net_ipv4_conf_default_secure_redirects_value"
fi

#
# If net.ipv4.conf.default.secure_redirects present in /etc/sysctl.conf, change value to appropriate value
# else, add "net.ipv4.conf.default.secure_redirects = value" to /etc/sysctl.conf
#

# Strip any search characters in the key arg so that the key can be replaced without
# adding any search characters to the config file.
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^net.ipv4.conf.default.secure_redirects")

# shellcheck disable=SC2059
printf -v formatted_output "%s = %s" "$stripped_key" "$sysctl_net_ipv4_conf_default_secure_redirects_value"

# If the key exists, change it. Otherwise, add it to the config_file.
# We search for the key string followed by a word boundary (matched by \>),
# so if we search for 'setting', 'setting2' won't match.
if LC_ALL=C grep -q -m 1 -i -e "^net.ipv4.conf.default.secure_redirects\\>" "${SYSCONFIG_FILE}"; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^net.ipv4.conf.default.secure_redirects\\>.*/$escaped_formatted_output/gi" "${SYSCONFIG_FILE}"
else
    if [[ -s "${SYSCONFIG_FILE}" ]] && [[ -n "$(tail -c 1 -- "${SYSCONFIG_FILE}" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "${SYSCONFIG_FILE}"
    fi
    printf '\n%s\n' "$formatted_output" >> "${SYSCONFIG_FILE}"
fi

echo "[+] Remediation complete: $SYSCTL_KEY is set to $sysctl_net_ipv4_conf_default_secure_redirects_value (runtime and persistent)."

else
    echo "[!] Remediation is not applicable, 'linux-base' package is not installed. Nothing was done."
fi
