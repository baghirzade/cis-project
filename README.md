🔒 CIS Benchmark Automation for Ubuntu 24.04 — Level 1

Automated Check & Remediation Framework | 405 Controls Coverage

This project provides a fully automated solution to audit and remediate CIS Benchmark Level 1 requirements for Ubuntu 24.04 (Noble Numbat).
It includes a modular architecture with individual check and remediation scripts for all 405 CIS rules, producing a detailed compliance report with color-coded status indicators.

Whether you're securing a single server or managing enterprise-scale infrastructure, this framework delivers clarity, repeatability, and reliability.

✨ Features

✅ Full CIS Level 1 coverage for Ubuntu 24.04

🧩 Modular structure — each rule has dedicated check and remediation logic

📊 Human-readable and machine-parsable reports

🎨 Color-coded output (PASS/WARN/FAIL/SKIP/NOT APPLICABLE)

🔁 Safe remediation workflow with backups and idempotent operations

🧪 Designed for CI/CD, configuration management, and security pipelines

📁 Structured layout:

cis-project/
├─ checks/
├─ remediation/
├─ lib/
├─ reports/
└─ cis-audit.sh


🛡️ Suitable for servers, cloud images, virtual machines and containers

🚀 Getting Started
1. Clone the repository
git clone https://github.com/<yourusername>/cis-project.git
cd cis-project

2. Run CIS Audit (Check Only)
sudo ./cis-audit.sh

3. Run CIS Remediation for a Specific Rule
sudo ./remediation/<rule_id>.sh

4. Review Reports

All logs are stored under ./reports/ with timestamps:

reports/cis-audit-YYYYMMDD-HHMMSS.log

📦 Requirements

Ubuntu 24.04 LTS

Bash 5.x

Root privileges

Optional: sysctl, apt, auditd, systemd tools depending on rule

🛠️ Architecture Overview
✔ Check Scripts

Each check script returns structured output:

PASS|rule_id|description
WARN|rule_id|description
FAIL|rule_id|details
NOTAPPL|rule_id|reason
SKIP|rule_id|reason

✔ Remediation Scripts

Each remediation script is safe, isolated, and can be executed independently:

Backs up configs before changes

Validates post-remediation

Avoids breaking system defaults

🔐 Why This Project?

CIS hardening is essential but time-consuming.
This framework brings:

Consistency across systems

Automation for compliance teams

Transparency with clear logs

Extensibility for additional benchmarks

It is ideal for SOC teams, DevSecOps pipelines, auditors, and enterprise security environments.

📧 Need CIS Level 2 or Support for Other Linux Distributions?

If you want CIS Level 2 for Ubuntu 24.04 or a cross-distro CIS hardening service
(CentOS, Rocky, AlmaLinux, RHEL, Debian, openSUSE, Amazon Linux, etc.),
feel free to contact me — I can help you extend this framework or tailor it to your infrastructure.

🤝 Contributions

Contributions, improvements, and suggestions are welcome!
Feel free to open issues or submit PRs.
