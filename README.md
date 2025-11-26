# Ubuntu CIS Automation Framework

## Professional CIS Level-1 Hardening & Audit Toolkit for Ubuntu

A modular, transparent, and script-driven framework to **audit and harden Ubuntu systems** according to **CIS Level-1 security principles**. This project is educational and operational in nature, designed for security engineers, SOC teams, and system administrators who want fine-grained visibility and control over Linux hardening tasks.

---

## ⚠️ CRITICAL SAFETY NOTICE

> ### ❗ DO NOT USE DIRECTLY IN PRODUCTION ENVIRONMENTS
>
> This framework modifies sensitive system configurations including:
>
> * SSH daemon settings
> * PAM authentication modules
> * Firewall rules (UFW)
> * Kernel parameters
> * Audit and integrity monitoring subsystems
>
> Before running ANY remediation scripts on a real environment:
>
> * ✅ Take a **full system backup** or **VM snapshot**
> * ✅ Test in a **staging or lab environment**
> * ✅ Review each script manually
> * ✅ Ensure console-level access exists

Running remediation without preparation may result in:

* SSH lockout
* User authentication failure
* Service disruption
* Kernel misconfiguration

---

## 🎯 Project Goals

* Provide a **CIS Level-1-like hardening solution** using pure Bash
* Maintain **full transparency** and script readability
* Allow selective control execution & bypassing
* Produce professional audit logs & summaries
* Enable easy Git version control and CI/CD integration

This is NOT an official CIS implementation but follows CIS-aligned logic and structure.

---

## 📁 Project Structure

```
ubuntu-cis-automation/
├── checks/                 # Audit-only scripts (READ-ONLY checks)
├── remediation/            # Remediation scripts (MAKE CHANGES)
├── config/
│   └── skip-controls.conf  # Controls to bypass
├── lib/
│   └── common.sh           # Shared functions (logging/helpers)
├── reports/                # Audit reports & logs
├── docs/                   # Documentation
├── cis-audit.sh            # Main audit runner
├── cis-remediate.sh        # Main remediation runner
└── cis-report.sh           # Report summarizer
```

Each control consists of:

* ✅ Audit script in `checks/`
* 🛠 Remediation script in `remediation/`

Naming convention example:

```
1.5-inactive-lock.sh
→ checks/1.5-inactive-lock.sh
→ remediation/1.5-inactive-lock.sh
```

---

## 🚀 Quick Start

### 1️⃣ Run audit (safe, read-only)

```bash
sudo ./cis-audit.sh
```

### 2️⃣ View summary

```bash
./cis-report.sh
```

### 3️⃣ Apply hardening (DANGEROUS)

```bash
sudo ./cis-remediate.sh
```

---

## 🧩 Skip (Bypass) Controls

To bypass problematic or environment-specific controls, edit:

```
config/skip-controls.conf
```

Example:

```
15.1-aide-fim.sh
16.1-pam-faillock.sh
```

Result in output:

```
[INFO]  SKIPPED: 15.1-aide-fim.sh
[INFO]  SKIPPED: 16.1-pam-faillock.sh
```

---

## 📊 Reporting System

The `cis-report.sh` script provides:

* ✅ Control-level status
* ✅ Assertion-level details
* ✅ WARN / FAIL listings
* ✅ SKIPPED logic visibility

Example output:

```
Control-level totals:
  CONTROLS OK       : 26
  CONTROLS WARN     : 0
  CONTROLS FAIL     : 0
  CONTROLS SKIPPED  : 2
```

---

## ✅ Implemented CIS Controls (Overview)

### System Policy

* Password aging limits
* Inactive account lock
* SHA512 encryption

### Authentication & Access

* sudo security
* PAM pwquality
* faillock protection

### SSH Hardening

* Root login disabled
* PasswordAuthentication disabled
* Idle timeout enforced

### Filesystem Security

* Secure permissions for passwd/shadow/group
* World-writable file detection
* SUID/SGID audits

### Network Hardening

* sysctl IPv4 protection
* Disable IP forwarding
* Source routing disabled

### Firewall

* UFW deny incoming, allow outgoing

### Logging and Auditing

* auditd installation & rules
* sudo logging

### Brute-force Protection

* fail2ban SSH jail

### File Integrity

* AIDE baseline (optional)

### Kernel Modules

* Disable squashfs, udf, cramfs

---

## 🔐 Security Philosophy

* Atomic scripts
* Granular control execution
* Human-readable logs
* Predictable remediation flow
* Audit-first approach

---

## 🛡 Disclaimer

This project may:

* Break system access
* Modify critical authentication paths
* Lock users
* Interfere with existing software

You use this tool at your own risk.

Always validate in:

✅ Virtual Machines
✅ Lab Environments
✅ Snapshot-enabled systems

---

## 👨‍💻 Author & Lab Project Scope

Developed as part of advanced Linux hardening and SOC engineering practice.

Aimed at:

* Cybersecurity engineers
* SOC analysts
* Infrastructure security teams
* DevSecOps pipelines

---

## 📌 Recommended Use

* Test Environments
* Hardening Labs
* CIS Training
* Security Baseline Development

NOT recommended for:

* Unreviewed production automation
* Shared hosting environments
* Mission-critical live servers

---

## ✅ Suggested GitHub Tags

```
#ubuntu
#cis
#linux-hardening
#security-automation
#bash
#sysadmin
#infosec
```

---

If you'd like, I can also provide:

* ✔ GitHub project description
* ✔ Professional badge set
* ✔ Usage screenshots
* ✔ Wiki documentation layout
* ✔ CI/CD integration pipeline
