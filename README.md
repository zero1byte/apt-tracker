# APT Tracker

A lightweight, zero-dependency apt wrapper that tracks package install/remove/upgrade
history into a simple CSV file. Built entirely in **Bash** — works on any Debian/Ubuntu
system, no Python or extra packages needed.

---

## How It Works

```
User runs: apt install vim
               ↓
  /usr/local/bin/apt   ← our wrapper (higher PATH priority)
               ↓
  /usr/bin/apt install vim   ← real apt runs unchanged
               ↓
  exit code = 0 (success)?
               ↓  YES
  Write record to /var/lib/apt-tracker/records.csv
```

The real apt at `/usr/bin/apt` is **never touched**. The wrapper sits at
`/usr/local/bin/apt` which is earlier in `$PATH`, so it intercepts all `apt` calls.

---

## Files

```
apt-tracker/
├── apt             ← wrapper script (installed to /usr/local/bin/apt)
├── install.sh      ← installer (run this first)
└── uninstall.sh    ← uninstaller
```

Records are stored at: `/var/lib/apt-tracker/records.csv`

---

## Installation

```bash
sudo bash install.sh
```

The installer will:
1. Check for root privileges
2. Verify real apt exists at /usr/bin/apt
3. Create /var/lib/apt-tracker/ with correct permissions
4. Create records.csv with CSV header
5. Copy the wrapper to /usr/local/bin/apt
6. Write a bootstrap install record
7. Verify the wrapper is picked up correctly

---

## Usage

All normal apt commands work exactly as before:

```bash
sudo apt update
sudo apt install vim curl git
sudo apt remove vim
sudo apt upgrade
sudo apt autoremove
```

### History Commands

```bash
apt history                  # Show all history
apt history install          # Only installs
apt history remove           # Only removals
apt history upgrade          # Only upgrades
apt history update           # Only updates
apt history autoremove       # Only autoremoves
apt history search vim       # Search by package name
apt history stats            # Summary statistics
apt history export           # Export CSV to home directory
apt history export /tmp/x.csv  # Export to specific path
apt history clear            # Clear all history (with confirmation)
apt history help             # Show help
```

---

## Records CSV Format

```
action,package,version,timestamp,user,status
"install","vim","2:8.2.3995-1ubuntu2","2024-01-15 10:30:00","john","success"
"remove","curl","n/a","2024-01-15 11:00:00","john","success"
"update","(all)","n/a","2024-01-15 12:00:00","root","success"
"upgrade","bash","5.1-6ubuntu1","2024-01-15 12:05:00","root","success"
```

**Fields:**
- `action` — install / remove / purge / upgrade / update / full-upgrade / dist-upgrade / autoremove
- `package` — package name (or `(all)` for update/upgrade with no specifics)
- `version` — installed version (from dpkg-query) or `n/a`
- `timestamp` — YYYY-MM-DD HH:MM:SS
- `user` — actual user (resolves SUDO_USER so you see the real person)
- `status` — success / failed

---

## Edge Cases Handled

| Scenario | Behaviour |
|---|---|
| apt command fails | Records written with `status=failed` |
| `update` (no packages) | Single record: package=`(all)` |
| `upgrade` | Each upgraded package gets its own record |
| `autoremove` | Each removed package gets its own record |
| Concurrent writes | File lock prevents corruption |
| Records file missing | Warning shown, tracker recreates it |
| Tracker dir missing | Warning shown, graceful degradation |
| Non-tracked commands | Passed directly to real apt, no overhead |
| Wrapper already installed | Installer asks before overwriting |
| Records file bad header | Backup created, file reinitialised |
| sudo vs root | SUDO_USER resolved to real username |

---

## Uninstallation

```bash
sudo bash uninstall.sh
```

Removes the wrapper from `/usr/local/bin/apt`. You choose whether to keep or delete
the records. The real apt at `/usr/bin/apt` is unaffected throughout.

---

## Requirements

- Bash 4+ (pre-installed on all Debian/Ubuntu)
- `dpkg-query` (always available with apt)
- `apt-get` (always available with apt)
- No Python, no Ruby, no external dependencies
