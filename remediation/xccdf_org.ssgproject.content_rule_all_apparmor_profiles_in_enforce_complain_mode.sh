#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_all_apparmor_profiles_in_enforce_complain_mode"
TITLE="Ensure all AppArmor profiles are in enforce or complain mode"

# Not applicable inside containers
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "Remediation not applicable: running inside a container." >&2
    exit 0
fi

# Ensure apparmor is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'apparmor' 2>/dev/null | grep -q '^installed$'; then
    echo "Installing 'apparmor' package..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y "apparmor"
fi

# If still not installed, abort
if ! dpkg-query --show --showformat='${db:Status-Status}' 'apparmor' 2>/dev/null | grep -q '^installed$'; then
    echo "Failed to ensure 'apparmor' is installed. Aborting remediation." >&2
    exit 1
fi

# Ensure apparmor-utils is installed (for aa-enforce / aa-complain / aa-status)
if ! dpkg-query --show --showformat='${db:Status-Status}' 'apparmor-utils' 2>/dev/null | grep -q '^installed$'; then
    echo "Installing 'apparmor-utils' package..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y "apparmor-utils"
fi

# Reload all AppArmor profiles
if [ -d /etc/apparmor.d ]; then
    echo "Reloading AppArmor profiles from /etc/apparmor.d/..."
    apparmor_parser -q -r /etc/apparmor.d/ 2>/dev/null || true
fi

# Choose mode for profiles: "enforce" or "complain"
# Default: enforce
APPARMOR_MODE="enforce"

echo "Setting AppArmor profiles to '$APPARMOR_MODE' mode (except disabled profiles)..."

if [ "$APPARMOR_MODE" = "enforce" ]; then
    # Set all profiles to enforce mode except those explicitly disabled
    find /etc/apparmor.d -maxdepth 1 ! -type d -exec bash -c '
        prof="$1"
        base=$(basename "$prof")
        # Skip if profile is disabled via symlink in /etc/apparmor.d/disable
        if [ ! -e "/etc/apparmor.d/disable/$base" ]; then
            aa-enforce "$prof" >/dev/null 2>&1 || true
        fi
    ' _ {} \;
elif [ "$APPARMOR_MODE" = "complain" ]; then
    # Set all profiles to complain mode (does not downgrade existing enforce in upstream, but we keep it simple here)
    find /etc/apparmor.d -maxdepth 1 ! -type d -exec aa-complain {} \; >/dev/null 2>&1 || true
fi

# Show warning about unconfined processes (informational)
if command -v aa-status >/dev/null 2>&1; then
    UNCONFINED_COUNT=$(aa-status 2>/dev/null | awk '/processes are unconfined/ {print $1}')
    if [ -n "$UNCONFINED_COUNT" ] && [ "$UNCONFINED_COUNT" -ne 0 ]; then
        echo "***WARNING***: There are $UNCONFINED_COUNT unconfined processes."
        echo "They may need a profile created or enabled and then be restarted."
    fi
fi

echo "Remediation for $RULE_ID completed."
exit 0
