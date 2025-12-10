#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_grub2_cfg"
TITLE="Set /boot/grub/grub.cfg owner to root"

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

newown=""
if id "0" >/dev/null 2>&1; then
  newown="0"
fi

if [[ -z "$newown" ]]; then
  echo "0 is not a defined user on the system" >&2
  exit 1
fi

if ! stat -c "%u %U" "$CFG" | grep -E -w -q "0"; then
    chown --no-dereference "$newown" "$CFG"
fi

echo "Remediation for $RULE_ID completed: owner of $CFG set to root (uid 0)."
