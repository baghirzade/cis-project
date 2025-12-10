#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_no_rsh_trust_files"

echo "[*] Applying remediation for: $RULE_ID (Remove RSH trust files)"

# The check for rsh-server is included here to match the remediation logic, 
# although RSH trust files should be removed even if the server package is not present 
# (as the logic only *echoes* "not applicable" if the package isn't there, 
# but CIS is about reducing the attack surface).

# Only run if rsh-server is installed OR if we want to unconditionally remove the files (recommended practice)
# Sticking to the provided remediation logic:
if dpkg-query --show --showformat='${db:Status-Status}' 'rsh-server' 2>/dev/null | grep -q '^installed$'; then

echo "    -> Removing /etc/hosts.equiv if it exists."
rm -f /etc/hosts.equiv || true

echo "    -> Removing .rhosts files from /root and user home directories."
# Remove .rhosts from /root (filesystems on same device)
find /root -xdev -type f -name ".rhosts" -exec rm -f {} \; || true

# Remove .rhosts from /home directories (maxdepth 2)
find /home -maxdepth 2 -xdev -type f -name ".rhosts" -exec rm -f {} \; || true

echo "[+] Remediation complete. RSH trust files removed."

else
    >&2 echo 'Remediation is not applicable, rsh-server package is not installed (no action taken as per provided logic).'
fi
