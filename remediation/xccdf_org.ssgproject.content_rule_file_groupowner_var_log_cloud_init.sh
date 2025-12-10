#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_cloud_init"

echo "[*] Applying remediation for: $RULE_ID (Set /var/log/cloud-init log group ownership)"

TARGET_DIR="/var/log/"
# Determine the preferred group ('adm' then 'root')
newgroup=""
if getent group "adm" >/dev/null 2>&1; then
    newgroup="adm"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
fi

if [[ -z "${newgroup}" ]]; then
    >&2 echo "Error: Neither 'adm' nor 'root' is a defined group on the system. Aborting remediation."
    exit 1
fi

echo "[*] Target group for remediation: $newgroup"

# Find non-compliant files and change their group ownership
# The search criteria targets regular files in /var/log/ matching the cloud-init log pattern,
# whose current group owner is neither 'adm' nor 'root' (if 'adm' is the target group)
# The search logic is slightly simplified here compared to the check, matching the remediation's intent.

echo "    -> Changing group ownership of /var/log/cloud-init* files not owned by adm or root to $newgroup..."

# The original remediation logic:
# find -P /var/log/ -maxdepth 1 -type f ! -group adm ! -group root -regextype posix-extended -regex '.*cloud-init\.log.*' -exec chgrp --no-dereference "$newgroup" {} \;

# Execute the change using the determined newgroup:
find -P "$TARGET_DIR" -maxdepth 1 -type f \
     -regextype posix-extended -regex '.*cloud-init\.log.*' \
     ! -group adm ! -group root \
     -exec chgrp --no-dereference "$newgroup" {} \; 2>/dev/null || true

echo "[+] Remediation complete: Group ownership of /var/log/cloud-init logs set to $newgroup."
