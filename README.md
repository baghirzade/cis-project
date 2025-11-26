ubuntu-cis-automation

Custom shell-based automation to audit and harden Ubuntu servers in a CIS-like way – similar in spirit to Ubuntu Pro CIS profiles, but:

Fully transparent (pure Bash scripts)

Easy to read logs and reports

Each control has both audit and remediation logic

⚠️ CRITICAL WARNING – LAB / POC ONLY
This project is intended only for lab, PoC, and learning environments.
Do NOT run this blindly on production systems.
If you want to test it on a real server:

ALWAYS take a VM snapshot or full backup before running remediation

Review each script line by line

First run only cis-audit.sh and review the results

Only then carefully use cis-remediate.sh or individual remediation scripts

Overview

Target OS: Ubuntu Server (20.04 / 22.04+ style systems)

Tech stack: Pure Bash + system utilities (apt, sysctl, ufw, auditd, fail2ban, AIDE, etc.)

Scope: Core CIS Level-1–like controls:

Password policies

SSH hardening

UMASK & file permissions

Network sysctl

Legacy service cleanup

sudo, auditd, login banners

UFW, fail2ban, kernel modules

PAM faillock, AIDE (can be skipped via config)

This is not an official CIS benchmark implementation, but a learning-oriented, script-based approximation.

Project structure
ubuntu-cis-automation/
├── checks/                # Audit-only scripts for each control
│   ├── 1.1-pass-max-days.sh
│   ├── 1.2-pass-min-days.sh
│   ├── 1.3-pass-warn-age.sh
│   ├── 1.4-encrypt-method.sh
│   ├── 1.5-inactive-lock.sh
│   ├── 2.1-user-password-policy.sh
│   ├── 2.2-sudo-installed.sh
│   ├── 2.3-sudo-pty.sh
│   ├── 2.4-sudo-log.sh
│   ├── 3.1-ssh-hardening.sh
│   ├── 3.2-ssh-idle-timeout.sh
│   ├── 4.1-umask-defaults.sh
│   ├── 5.1-passwd-permissions.sh
│   ├── 5.2-shadow-permissions.sh
│   ├── 5.3-group-permissions.sh
│   ├── 5.4-world-writable.sh
│   ├── 5.5-suid-sgid.sh
│   ├── 6.1-sysctl-net-ipv4.sh
│   ├── 7.1-legacy-services.sh
│   ├── 7.2-pam-pwquality.sh
│   ├── 8.1-auditd-installed.sh
│   ├── 8.2-audit-rules-basic.sh
│   ├── 9.1-login-banner.sh
│   ├── 10.1-su-restriction.sh
│   ├── 11.1-unattended-upgrades.sh
│   ├── 12.1-kernel-modules.sh
│   ├── 13.1-ufw-basic.sh
│   ├── 14.1-fail2ban-ssh.sh
│   ├── 15.1-aide-fim.sh
│   └── 16.1-pam-faillock.sh
├── remediation/           # Remediation scripts for each control
│   └── (same names as in checks/)
├── lib/
│   └── common.sh          # Shared logging functions, paths, helpers
├── config/
│   └── skip-controls.conf # Controls to skip (bypass) for audit/remediate
├── reports/
│   └── cis-audit-*.log    # Audit run logs
├── docs/
│   └── password-policy.md # Example documentation for password controls
├── cis-audit.sh           # Runs all checks/*
├── cis-remediate.sh       # Runs all remediation/*
└── cis-report.sh          # Summarizes the latest audit run

Features
✅ Modular controls

Every control is split into:

checks/<ID>.sh → audit-only logic

remediation/<ID>.sh → configuration changes

Adding a new control = adding two scripts with the same ID.

✅ Centralized logging

Common helpers in lib/common.sh:

log_info, log_warn, log_fail, log_ok

Each run logs both to:

The console

A timestamped file under reports/, for example:
reports/cis-audit-20251123-171345.log

✅ Human-readable reporting

cis-report.sh parses the latest audit log and computes:

Control-level totals:

Control-level totals:
  CONTROLS OK       : 26
  CONTROLS WARN     : 0
  CONTROLS FAIL     : 0
  CONTROLS SKIPPED  : 2


Line-level totals: (assertions / log lines)

Detailed check totals:
  ASSERTIONS OK     : X
  ASSERTIONS WARN   : Y
  ASSERTIONS FAIL   : Z


Lists [WARN] and [FAIL] lines for quick review.

✅ Skip mechanism (bypass certain controls)

The file config/skip-controls.conf allows you to skip controls globally for both audit and remediation.

Example:

# config/skip-controls.conf
15.1-aide-fim.sh
16.1-pam-faillock.sh


Any ID listed here will appear as SKIPPED in logs and reports.

Installation
# Clone the repository (example)
git clone https://github.com/<your-user>/ubuntu-cis-automation.git
cd ubuntu-cis-automation

# Make scripts executable
chmod +x cis-audit.sh cis-remediate.sh cis-report.sh
chmod +x checks/*.sh remediation/*.sh


⚠️ Production warning (again):
Before running anything that changes configuration (e.g. cis-remediate.sh) on a real system,
take a VM snapshot or full backup and verify you have a rollback plan.

Usage
1. Run an audit (read-only)
sudo ./cis-audit.sh


Runs every script in checks/ (except those in skip-controls.conf)

Creates a log file in reports/:

cis-audit-YYYYMMDD-HHMMSS.log

Then summarize the latest run:

./cis-report.sh


Example output:

=== CIS Audit Summary ===
Host: cis-project
Report file: /home/fazil/ubuntu-cis-automation/reports/cis-audit-20251123-171345.log

Control-level totals:
  CONTROLS OK       : 26
  CONTROLS WARN     : 0
  CONTROLS FAIL     : 0
  CONTROLS SKIPPED  : 2

Detailed check totals:
  ASSERTIONS OK     : 0
  ASSERTIONS WARN   : 0
  ASSERTIONS FAIL   : 0

--- WARN / FAIL Details (by line) ---
No WARN/FAIL entries.

End of report.

2. Run remediation (makes changes!)
sudo ./cis-remediate.sh


This will:

Run every script in remediation/ (except those in skip-controls.conf)

Take backups before modifying critical files, such as:

/etc/login.defs.cis.YYYYMMDD-HHMMSS.bak

/etc/shadow.cis.YYYYMMDD-HHMMSS.bak

/etc/ssh/sshd_config.cis.YYYYMMDD-HHMMSS.bak

/etc/audit/rules.d/cis-base.rules.cis.YYYYMMDD-HHMMSS.bak

etc.

❗ Important: SSH, PAM, firewall, AIDE, and auditd settings are especially sensitive.
Misconfiguration can lock you out or break services. Always test in a lab first and keep console access handy.

After remediation, you should run:

sudo ./cis-audit.sh
./cis-report.sh


to verify that controls are now compliant.

3. Skipping specific controls

To bypass a control globally (for both audit and remediation), add its script name to config/skip-controls.conf:

# Example: skip AIDE and PAM faillock
15.1-aide-fim.sh
16.1-pam-faillock.sh


Logs and reports will show:

[INFO]  SKIPPED: 15.1-aide-fim.sh (listed in config/skip-controls.conf)
[INFO]  SKIPPED: 16.1-pam-faillock.sh (listed in config/skip-controls.conf)


And in the summary:

CONTROLS SKIPPED  : 2

Implemented controls (high-level)
1.x – System-wide password policy

1.1 – PASS_MAX_DAYS
Ensures PASS_MAX_DAYS in /etc/login.defs is set to 365.

1.2 – PASS_MIN_DAYS
Ensures PASS_MIN_DAYS in /etc/login.defs is set to 1.

1.3 – PASS_WARN_AGE
Ensures PASS_WARN_AGE in /etc/login.defs is set to 7.

1.4 – ENCRYPT_METHOD
Ensures password hashing uses ENCRYPT_METHOD SHA512 (or equivalent).

1.5 – Inactive account lock
Ensures INACTIVE is set (e.g. 30 days) via chage / useradd defaults.

2.x – Users & sudo

2.1 – Per-user password policy
Uses chage to verify user-level MIN / MAX / WARN for real users (UID ≥ 1000).

2.2 – sudo installed
Confirms sudo package is present.

2.3 – sudo use_pty
Ensures Defaults use_pty is enforced.

2.4 – sudo logging
Ensures logfile="/var/log/sudo.log" or similar is configured.

3.x – SSH hardening

3.1 – Core SSH settings
Checks/remediates:

PermitRootLogin no

PasswordAuthentication no

MaxAuthTries 3

Protocol 2

X11Forwarding no

3.2 – SSH idle timeout
Configures:

ClientAliveInterval

ClientAliveCountMax

4.x – UMASK

4.1 – Default UMASK
Ensures:

/etc/login.defs → UMASK 027

/etc/profile → umask 027

5.x – Critical file permissions

5.1 – /etc/passwd
root:root, mode 644 or more restrictive.

5.2 – /etc/shadow
root:shadow (or equivalent), mode 640 or more restrictive.

5.3 – /etc/group
root:root, mode 644 or more restrictive.

5.4 – World-writable files
Scans for world-writable regular files (excluding pseudo-filesystems).

5.5 – SUID/SGID binaries
Enumerates SUID/SGID binaries for manual review (no automatic removal).

6.x – IPv4 sysctl hardening

6.1 – net.ipv4 settings
Ensures values like:

net.ipv4.ip_forward = 0

net.ipv4.conf.*.send_redirects = 0

net.ipv4.conf.*.accept_redirects = 0

net.ipv4.conf.*.accept_source_route = 0

net.ipv4.conf.*.rp_filter = 1

net.ipv4.tcp_syncookies = 1

7.x – Legacy services & pwquality

7.1 – Legacy services
Detects/removes/disables packages like telnet, rsh, tftp, xinetd, etc.

7.2 – PAM pwquality
Ensures pam_pwquality is configured with reasonable defaults (length, character classes, etc.).

8.x – auditd

8.1 – auditd installed and running
Verifies auditd package and service.

8.2 – Base audit rules
Ensures rules exist for:

/etc/passwd, /etc/shadow, /etc/group, /etc/gshadow

/etc/sudoers, /etc/sudoers.d/

/var/log/sudo.log

execve syscall (32-bit & 64-bit arch)

9.x – Login banners

9.1 – MOTD and issue banners
Verifies secure perms and presence of a warning banner on:

/etc/motd

/etc/issue

/etc/issue.net

10.x – su restriction

10.1 – Restrict su to a group
Enforces PAM configuration so that su is allowed only for a specific group (e.g. wheel).

11.x – Unattended security updates

11.1 – unattended-upgrades
Installs and configures unattended upgrades and related timer/service units.

12.x – Kernel modules

12.1 – Disable unused filesystems
Disables modules like cramfs, squashfs, udf via /etc/modprobe.d.

13.x – UFW firewall

13.1 – Basic UFW policy
Configures:

Default incoming: deny

Default outgoing: allow

Enables UFW

14.x – Fail2ban

14.1 – SSH jail
Installs and configures fail2ban SSH protection with sane defaults.

15.x – AIDE File Integrity Monitoring

15.1 – AIDE (optional)
Installs and initializes AIDE, configures a baseline.
⚠️ Can be skipped using skip-controls.conf if you don’t want long initialization or extra complexity.

16.x – PAM faillock

16.1 – PAM faillock (optional)
Configures pam_faillock (e.g. deny=5, unlock_time=900).
⚠️ Very environment-specific; can easily lock out users if misconfigured.
Recommended to skip if you’re not comfortable with PAM.

Disclaimer

This project:

Is not an official CIS Benchmark implementation

Is not supported by any vendor

Can break or lock down your system if misused, especially:

SSH configuration

PAM settings (faillock, pwquality)

Firewall rules (UFW)

AIDE & auditd

By using this project, you accept that:

You are fully responsible for any impact on your systems

You will test in lab environments first

You will always have a snapshot/backup and rollback plan before applying remediation on anything important