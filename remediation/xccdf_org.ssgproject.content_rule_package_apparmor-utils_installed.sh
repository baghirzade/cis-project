#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_package_apparmor-utils_installed"
TITLE="Install apparmor-utils package"

# Remediation is applicable only when not running inside a container
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "Remediation not applicable: running inside a container, not installing 'apparmor-utils'." >&2
    exit 0
fi

echo "Installing 'apparmor-utils' package..."
DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
DEBIAN_FRONTEND=noninteractive apt-get install -y "apparmor-utils"

if dpkg-query --show --showformat='${db:Status-Status}' 'apparmor-utils' 2>/dev/null | grep -q '^installed$'; then
    echo "Remediation successful: 'apparmor-utils' is installed."
    exit 0
else
    echo "Remediation failed: could not install 'apparmor-utils'." >&2
    exit 1
fi
