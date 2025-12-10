#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_timesyncd_configured"

echo "[*] Applying remediation for: $RULE_ID (Configure systemd-timesyncd with multiple time servers)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' && { dpkg-query --show --showformat='${db:Status-Status}' 'systemd' 2>/dev/null | grep -q '^installed$'; }; then

# Define the list of servers from the remediation source
var_multiple_time_servers='0.ubuntu.pool.ntp.org,1.ubuntu.pool.ntp.org,2.ubuntu.pool.ntp.org,3.ubuntu.pool.ntp.org'

IFS=',' read -r -a time_servers_array <<< "$var_multiple_time_servers"

# First two servers are preferred
preferred_ntp_servers_array=("${time_servers_array[@]:0:2}")
preferred_ntp_servers=$( echo "${preferred_ntp_servers_array[@]}"|sed -e 's/\s\+/,/g' )

# Remaining servers are fallback
fallback_ntp_servers_array=("${time_servers_array[@]:2}")
fallback_ntp_servers=$( echo "${fallback_ntp_servers_array[@]}"|sed -e 's/\s\+/,/g' )

# Get a list of all potential configuration files
IFS=" " mapfile -t current_cfg_arr < <(ls -1 /etc/systemd/timesyncd.d/* /etc/systemd/timesyncd.conf.d/* 2>/dev/null)

config_file="/etc/systemd/timesyncd.conf.d/oscap-remedy.conf"

# Include the main config file for commenting
current_cfg_arr+=( "/etc/systemd/timesyncd.conf" )

# Comment existing NTP and FallbackNTP settings in all config files
echo "    -> Commenting out existing NTP and FallbackNTP settings in configuration files."
for current_cfg in "${current_cfg_arr[@]}"
do
    # Use grep -q to check if the line exists before attempting to sed
    if grep -qE '^(NTP|FallbackNTP)=' "$current_cfg"; then
        sed -i 's/^NTP/#&/g' "$current_cfg" || true
        sed -i 's/^FallbackNTP/#&/g' "$current_cfg" || true
    fi
done

# Create the drop-in directory if it doesn't exist
if [ ! -d "/etc/systemd/timesyncd.conf.d" ]
then 
    echo "    -> Creating directory /etc/systemd/timesyncd.conf.d"
    mkdir /etc/systemd/timesyncd.conf.d
fi

# Clear and set new configuration in the drop-in file
echo "    -> Setting NTP and FallbackNTP in $config_file"
echo "[Time]" > "$config_file"
echo "NTP=$preferred_ntp_servers" >> "$config_file"
echo "FallbackNTP=$fallback_ntp_servers" >> "$config_file"

# Restart the service to apply changes
if command -v systemctl &> /dev/null; then
    echo "    -> Restarting systemd-timesyncd.service to apply changes."
    systemctl restart systemd-timesyncd.service || true
fi

echo "[+] Remediation complete. systemd-timesyncd configured."

else
    >&2 echo 'Remediation is not applicable, linux-base or systemd package is not installed.'
fi
