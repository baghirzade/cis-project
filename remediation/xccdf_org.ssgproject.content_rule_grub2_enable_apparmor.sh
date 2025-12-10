#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_grub2_enable_apparmor"
TITLE="Ensure GRUB enables AppArmor via kernel parameters"

# Remediation is applicable only on bare metal / non-container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "Remediation not applicable: running inside a container." >&2
    exit 0
fi

GRUB_DEFAULT="/etc/default/grub"

# Ensure file exists
if [ ! -f "$GRUB_DEFAULT" ]; then
    touch "$GRUB_DEFAULT"
fi

# Enable apparmor=1 in GRUB_CMDLINE_LINUX
if grep -q '^\s*GRUB_CMDLINE_LINUX=.*apparmor=.*"' "$GRUB_DEFAULT" ; then
    # modify the GRUB command-line if an apparmor= arg already exists
    sed -i 's/\(^\s*GRUB_CMDLINE_LINUX=".*\)apparmor=[^[:space:]]\+\(.*"\)/\1apparmor=1\2/' "$GRUB_DEFAULT"
elif grep -q '^\s*GRUB_CMDLINE_LINUX=' "$GRUB_DEFAULT" ; then
    # no apparmor=arg is present, append it
    sed -i 's/\(^\s*GRUB_CMDLINE_LINUX=".*\)"/\1 apparmor=1"/' "$GRUB_DEFAULT"
else
    # Add GRUB_CMDLINE_LINUX parameters line
    echo 'GRUB_CMDLINE_LINUX="apparmor=1"' >> "$GRUB_DEFAULT"
fi

# Ensure security=apparmor in GRUB_CMDLINE_LINUX
if grep -q '^\s*GRUB_CMDLINE_LINUX=.*security=.*"' "$GRUB_DEFAULT" ; then
    # modify the GRUB command-line if a security= arg already exists
    sed -i 's/\(^\s*GRUB_CMDLINE_LINUX=".*\)security=[^[:space:]]\+\(.*"\)/\1security=apparmor\2/' "$GRUB_DEFAULT"
elif grep -q '^\s*GRUB_CMDLINE_LINUX=' "$GRUB_DEFAULT" ; then
    # no security=arg is present, append it
    sed -i 's/\(^\s*GRUB_CMDLINE_LINUX=".*\)"/\1 security=apparmor"/' "$GRUB_DEFAULT"
else
    # Add GRUB_CMDLINE_LINUX parameters line if missing entirely
    echo 'GRUB_CMDLINE_LINUX="security=apparmor"' >> "$GRUB_DEFAULT"
fi

# Regenerate GRUB configuration
if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    echo "Warning: update-grub command not found; please regenerate GRUB config manually." >&2
fi

echo "Remediation for $RULE_ID completed."
