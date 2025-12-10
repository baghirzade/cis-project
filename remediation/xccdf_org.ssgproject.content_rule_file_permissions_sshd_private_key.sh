#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_sshd_private_key"

echo "[*] Applying remediation for: $RULE_ID (Secure SSHD Private Key Files)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

echo "    -> Iterating through SSH private key files in /etc/ssh/ to check ownership and set permissions."

# Iterate through all files ending with '_key' in /etc/ssh/ (excluding pub keys)
for keyfile in /etc/ssh/*_key; do
    # Skip if not a regular file or is a public key file
    test -f "$keyfile" || continue
    if [[ "$keyfile" == *.pub ]]; then
        continue
    fi

    # Check Ownership
    if test root:root = "$(stat -c "%U:%G" "$keyfile")"; then
        echo "    -> Securing permissions for key file: $keyfile"
        
        # Set permissions: Remove setuid (u-xs), setgid (g-xws), sticky (o-xwrt).
        # This typically results in 600 or 400, ensuring only root can access.
        chmod u-xs,g-xwrs,o-xwrt "$keyfile"
        
        # Explicitly set permissions to 600 (root read/write only) for best practice,
        # although the remediation block above uses relative permissions. We'll stick 
        # to the logic of the remediation block for consistency.
        # As an extra safety net, we ensure read is disabled for group/other:
        chmod g-r,o-r "$keyfile"
    else
        echo "WARN|Key-like file '$keyfile' is owned by an unexpected user:group combination ($keyfile). Skipping chmod."
    fi
done

echo "[+] Remediation complete. SSHD private key file permissions secured."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
