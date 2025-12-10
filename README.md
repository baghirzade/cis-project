# 🔒CIS Benchmark Automation for Ubuntu 24.04 — Level 1  
**Automated Check & Remediation Framework | 405 Controls Coverage**

This project provides a fully automated solution to **audit and remediate CIS Benchmark Level 1** requirements for **Ubuntu 24.04 (Noble Numbat)**.  
All 405 rules are implemented with dedicated check and remediation logic, producing clear, color-coded, and fully traceable compliance results.

Whether you're securing a single server or a large-scale environment, this framework ensures consistency, repeatability, and reliable CIS hardening.

---

## ✨ Features

- 🔐 **Complete CIS Level 1 coverage** for Ubuntu 24.04  
- 📝 **Separate check and remediation logic** for every rule  
- 🎨 **Color-coded output** (PASS / WARN / FAIL / SKIP / NOTAPPL)  
- 📊 **Detailed audit reports** saved with timestamps  
- 🔁 **Idempotent and safe remediation actions**  
- ⚙️ Suitable for DevSecOps, SOC teams, compliance pipelines, security audits

---

## 🚀 Usage

### Run CIS Audit
```bash
sudo ./cis-audit.sh
```

### Run Full Remediation
```bash
sudo ./remediation.sh
```

### View Reports
Audit results are stored automatically:
```
reports/cis-audit-YYYYMMDD-HHMMSS.log
```

---

## 📦 Requirements

- Ubuntu 24.04 LTS  
- Bash 5.x  
- Root privileges  

---

## 🔐 Why This Project?

- Automates the entire CIS Level 1 audit and remediation process  
- Removes manual errors and ensures consistent hardening  
- Produces structured output ideal for monitoring or CI/CD  
- Easy to extend with new rules or custom compliance policies  

---

## 📧 Need CIS Level 2 or Multi-Distro Support?

If you want **Ubuntu 24.04 CIS Level 2** automation  
or a **CIS audit/remediation system for any Linux distribution**  
(RHEL, Rocky, AlmaLinux, CentOS, Debian, Amazon Linux, openSUSE, etc.),  
feel free to contact me — I can extend or customize this framework for your infrastructure.

---

## 🤝 Contributions

Ideas, improvements, and pull requests are always welcome.
