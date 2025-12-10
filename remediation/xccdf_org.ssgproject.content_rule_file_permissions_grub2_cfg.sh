#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_grub2_cfg"
TITLE="Set secure permissions on /boot/grub/grub.cfg"

# Remediation applicable only if grub2-common and linux-base are installed and not in a container
if ! ( dpkg-query --show --showformat='${db:Status-Status}' 'grub2-common' 2>/dev/null | grep -q '^installed$' \
   && dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' ); then
    echo "Remediation not applicable: required packages not installed." >&2
    exit 0
fi

if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "Remediation not applicable: running inside a container." >&2
    exit 0
fi

CFG="/boot/grub/grub.cfg"

if [ ! -f "$CFG" ]; then
    echo "Warning: $CFG does not exist, nothing to remediate." >&2
    exit 1
fi

# Apply CIS-style restrictive permissions
chmod u-xs,g-xwrs,o-xwrt "$CFG"

echo "Remediation for $RULE_ID completed: permissions on $CFG hardened."
