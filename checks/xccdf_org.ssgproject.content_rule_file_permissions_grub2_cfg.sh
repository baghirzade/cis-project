#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_grub2_cfg"

CFG="/boot/grub/grub.cfg"

# --- Applicability checks ---
if ! dpkg-query -W -f='${Status}' grub2-common 2>/dev/null | grep -q "installed"; then
    echo "NOTAPPL|$RULE_ID|grub2-common not installed"
    exit 0
fi

if ! dpkg-query -W -f='${Status}' linux-base 2>/dev/null | grep -q "installed"; then
    echo "NOTAPPL|$RULE_ID|linux-base not installed"
    exit 0
fi

if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "NOTAPPL|$RULE_ID|Container environment"
    exit 0
fi

# --- File existence check ---
if [ ! -f "$CFG" ]; then
    echo "WARN|$RULE_ID|$CFG missing"
    exit 1
fi

# --- Permission check ---
MODE=$(stat -c "%a" "$CFG" 2>/dev/null)

if [ "$MODE" = "600" ]; then
    echo "OK|$RULE_ID|Permissions correct (600)"
    exit 0
else
    echo "WARN|$RULE_ID|Permissions are $MODE, expected 600"
    exit 1
fi