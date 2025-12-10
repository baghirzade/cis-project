#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_default_accept_source_route"

echo "[*] Applying remediation for: $RULE_ID (Disable IPv6 source routing by default)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

# Target files for commenting out existing settings
CONFIG_FILES="/etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

echo "[*] Commenting out existing '${SYSCTL_KEY}' occurrences in ${CONFIG_FILES}"

# Comment out any occurrences of net.ipv6.conf.default.accept_source_route from relevant config files
for f in $CONFIG_FILES; do
    # skip systemd-sysctl symlink (/etc/sysctl.d/99-sysctl.conf -> /etc/sysctl.conf)
    if [[ "$(readlink -f "$f")" == "/etc/sysctl.conf" ]]; then continue; fi

    matching_list=$(grep -P '^(?!#).*[\s]*net.ipv6.conf.default.accept_source_route.*$' $f | uniq )
    if ! test -z "$matching_list"; then
        while IFS= read -r entry; do
            escaped_entry=$(sed -e 's|/|\\/|g' <<< "$entry")
            # comment out "net.ipv6.conf.default.accept_source_route" matches to preserve user data
            sed -i --follow-symlinks "s/^${escaped_entry}$/# &/g" "$f"
        done <<< "$matching_list"
    fi
done

#
# Set sysctl config file which to save the desired value
#

SYSCONFIG_FILE="/etc/sysctl.conf"
SYSCTL_KEY='net.ipv6.conf.default.accept_source_route'
sysctl_net_ipv6_conf_default_accept_source_route_value='0'


#
# Set runtime for net.ipv6.conf.default.accept_source_route
#
echo "[*] Setting runtime value to $sysctl_net_ipv6_conf_default_accept_source_route_value"
if ! /bin/false ; then
    /sbin/sysctl -q -n -w "$SYSCTL_KEY"="$sysctl_net_ipv6_conf_default_accept_source_route_value"
fi

#
# If net.ipv6.conf.default.accept_source_route present in /etc/sysctl.conf, change value to appropriate value
# else, add "net.ipv6.conf.default.accept_source_route = value" to /etc/sysctl.conf
#

# Strip any search characters in the key arg so that the key can be replaced without
# adding any search characters to the config file.
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "$SYSCTL_KEY")

# shellcheck disable=SC2059
printf -v formatted_output "%s = %s" "$stripped_key" "$sysctl_net_ipv6_conf_default_accept_source_route_value"

# If the key exists, change it. Otherwise, add it to the config_file.
# We search for the key string followed by a word boundary (matched by \>),
# so if we search for 'setting', 'setting2' won't match.
if LC_ALL=C grep -q -m 1 -i -e "^$SYSCTL_KEY\\>" "${SYSCONFIG_FILE}"; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^$SYSCTL_KEY\\>.*/$escaped_formatted_output/gi" "${SYSCONFIG_FILE}"
else
    if [[ -s "${SYSCONFIG_FILE}" ]] && [[ -n "$(tail -c 1 -- "${SYSCONFIG_FILE}" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "${SYSCONFIG_FILE}"
    fi
    printf '\n%s\n' "$formatted_output" >> "${SYSCONFIG_FILE}"
fi

echo "[+] Remediation complete: $SYSCTL_KEY is set to $sysctl_net_ipv6_conf_default_accept_source_route_value (runtime and persistent)."

else
    echo "[!] Remediation is not applicable, 'linux-base' package is not installed. Nothing was done."
fi
