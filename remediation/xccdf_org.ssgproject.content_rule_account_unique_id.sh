#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_account_unique_id"
(>&2 echo "Remediating: ${RULE_ID}")

PASSWD_FILE="/etc/passwd"

if [ ! -f "$PASSWD_FILE" ]; then
    (>&2 echo "Cannot remediate: $PASSWD_FILE does not exist")
    exit 1
fi

# Find duplicate UIDs
mapfile -t dup_uids < <(cut -d: -f3 "$PASSWD_FILE" | sort -n | uniq -d || true)

if [ "${#dup_uids[@]}" -eq 0 ]; then
    (>&2 echo "No duplicate UIDs found; nothing to remediate")
    exit 0
fi

(>&2 echo "Duplicate UIDs detected. Automatic remediation is intentionally NOT performed because it is unsafe to change UIDs without manual review.")
(>&2 echo "Summary of duplicate UIDs:")

for uid in "${dup_uids[@]}"; do
    mapfile -t users_for_uid < <(awk -F: -v id="$uid" '$3 == id {print $1}' "$PASSWD_FILE")
    if [ "${#users_for_uid[@]}" -gt 0 ]; then
        (>&2 echo "  UID ${uid}: ${users_for_uid[*]}")
    fi
done

(>&2 echo)
(>&2 echo "Recommended manual steps:")
(>&2 echo "  1) Decide which account should keep each duplicated UID.")
(>&2 echo "  2) For the others, assign a new unique UID (e.g. with 'usermod -u NEWUID USER').")
(>&2 echo "  3) Carefully adjust file ownerships if needed (find / -uid OLDUID -exec chown NEWUID {} +).")
(>&2 echo "  4) Verify that services and logins still work as expected.")

exit 0
