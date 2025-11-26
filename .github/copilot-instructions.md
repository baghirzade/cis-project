### Purpose

This repository contains a small CIS Level 1 automation framework implemented as a set
of shell scripts. The goal of this document is to give AI coding agents the concrete,
actionable knowledge needed to make safe, consistent changes without guessing project
conventions.

**Quick run commands**
- Run all checks: `bash cis-audit.sh`
- Run remediations: `bash cis-remediate.sh`
- Print the latest summary: `bash cis-report.sh`

**Project layout (key files)**
- `cis-audit.sh` — orchestrates checks, creates `reports/cis-audit-<timestamp>.log` and sets `LOGFILE`.
- `cis-remediate.sh` — runs scripts from `remediation/` and logs to `reports/`.
- `cis-report.sh` — parses the most recent audit log under `reports/`.
- `lib/common.sh` — shared helpers; defines `log_info`, `log_warn`, `log_ok`, `log_fail`, and `run_or_warn`.
- `checks/*.sh` — individual check scripts. Each typically defines `CONTROL_ID`, a check function, and invokes it.
- `remediation/*.sh` — remediation scripts called by `cis-remediate.sh`.
- `config/skip-controls.conf` — newline-separated list of filenames (e.g. `15.1-aide-fim.sh`) to skip.

**Important behavioral conventions (must follow exactly)**
- Logging: Use helper functions from `lib/common.sh` for consistent log format: `log_info`, `log_warn`, `log_ok`, `log_fail`.
  - The main orchestrators (`cis-audit.sh` and `cis-remediate.sh`) source `lib/common.sh` before running.
  - When running checks in isolation during development, execute the check in the current shell after sourcing `lib/common.sh` (see examples below).
- Exit-code convention used by `cis-audit.sh`: `0` = OK, `1` = WARN, `2+` = FAIL. Follow this mapping in checks so the orchestrator can summarize correctly.
- Check filenames: Keep them as `NN.N-description.sh` (already used throughout `checks/`) and list any skip-worthy filenames in `config/skip-controls.conf`.

**Patterns and examples (copyable snippets)**
- Minimal check structure (follow this pattern):

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail

  CONTROL_ID="CIS-EXAMPLE-1.1"

  check_pass_max_days() {
    # compute value...
    # use log_ok/log_warn/log_info
    # return 0 for OK, 1 for WARN, 2 for FAIL
  }

  check_pass_max_days
  ```

- How to run a single check interactively (so logging functions are available):

  ```bash
  source lib/common.sh
  . checks/1.1-pass-max-days.sh
  ```

  Do NOT just run `bash checks/1.1-pass-max-days.sh` if you expect `log_*` output — that spawns a subshell that doesn't inherit function definitions. The orchestrator (`cis-audit.sh`) sets up logging for full runs.

**Remediation notes**
- Remediation scripts live in `remediation/` and are executed with `bash` by `cis-remediate.sh`.
- Remediations should be idempotent and log progress using `log_info` / `log_ok` / `log_warn` when appropriate.

**Testing and debugging**
- Run `bash cis-audit.sh` to produce a full `reports/cis-audit-<timestamp>.log` and see aggregated counts.
- Use `cat reports/cis-audit-<timestamp>.log` to inspect WARN/FAIL lines (the main script appends those sections).
- To test a check in isolation with the same logging format, `source lib/common.sh` then source the check (`. checks/<file>`).

**What I observed (useful signals when editing)**
- Every script starts with `#!/usr/bin/env bash` and `set -euo pipefail` — preserve this header.
- Checks commonly set a `CONTROL_ID` variable and then call a single function; prefer that structure when adding new checks.
- The skip list format is simple: plain filenames, one per line (`config/skip-controls.conf`).

If anything is missing or you'd like a code template added (unit-test harness, CI job, or sample check + remediation pair), tell me which and I will add it.
