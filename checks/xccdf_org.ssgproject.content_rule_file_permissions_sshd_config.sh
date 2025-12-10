#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_sshd_config"
TITLE="Ensure SSHD configuration file permissions are secure"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    TARGET_FILE="/etc/ssh/sshd_config"
    
    if [ ! -f "$TARGET_FILE" ]; then
        echo "WARN|$RULE_ID|SSHD configuration file ($TARGET_FILE) not found."
        return 1
    fi

    # The ideal permissions are 0600 (owner read/write only).
    # We check for dangerous permissions: Group Write (g+w), Other Write (o+w),
    # and any special bits (setuid/setgid/sticky).
    
    # 1. Check for dangerous permissions (u+xs,g+xws,o+xwt) as defined in the remediation
    DANGEROUS_PERMS="/u+xs,g+xws,o+xwt"
    if find -P "$TARGET_FILE" -perm $DANGEROUS_PERMS -type f 2>/dev/null | grep -q "$TARGET_FILE"; then
        echo "WARN|$RULE_ID|SSHD config file has dangerous special permissions set."
        return 1
    fi
    
    # 2. Check for Group or Other Write permissions (CIS requirement)
    # Check if Group Write (020) or Other Write (002) is set
    INSECURE_WRITE_PERMS="022" # Group Write OR Other Write
    
    # Get current permissions and check if any of the insecure write bits are set
    CURRENT_PERMS=$(stat -c "%a" "$TARGET_FILE")
    
    # Check for Group Write (4xx) or Other Write (x4x) or Other Read (xx4)
    # CIS typically requires 600 or 644/400. We focus on not allowing unauthorized write.
    # Group and Other write bits must NOT be set.
    
    # Get the numeric permission value (octal)
    OCTAL_PERMS=$(printf "%o\n" "$CURRENT_PERMS")
    
    # Check if the file is secure (permissions 600, 400, 640, 644, 444, etc. are fine for read, but NOT 666, 777, or anything allowing group/other write)
    # Specifically check if group write (bit 2) or other write (bit 1) is set in the file mode.
    # We allow read (4) but not write (2) or execute (1) for group/other.
    
    # Extract Group and Other permissions (last two digits)
    GROUP_PERM=${OCTAL_PERMS: -2:1}
    OTHER_PERM=${OCTAL_PERMS: -1}

    # If Group or Other permission includes write (2 or 3, 6, 7)
    if (( $GROUP_PERM % 2 != 0 || $GROUP_PERM >= 2 )) || (( $OTHER_PERM % 2 != 0 || $OTHER_PERM >= 2 )); then
        echo "WARN|$RULE_ID|SSHD config file has insecure permissions ($CURRENT_PERMS). Group/Other must not have write access."
        return 1
    fi
    
    echo "OK|$RULE_ID|SSHD config file permissions ($CURRENT_PERMS) are secure (no group/other write, no special bits)."
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
