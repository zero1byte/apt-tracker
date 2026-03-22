# apt-tracker

Track every package you install, remove, or upgrade on Debian/Ubuntu-based systems.  
Built entirely in **Bash** — no Python, no database, no extra dependencies.

---

## The Problem

`apt` has no built-in history. If you want to know:

- What packages did I install last month?
- When did I remove that tool?
- What got upgraded last week?
- Did that package actually install successfully?

There is no native command for any of this. `apt` just runs and forgets.  
`/var/log/dpkg.log` exists but it is raw, hard to read, and not queryable.

---

## How It Works

apt-tracker installs a **wrapper script** at `/usr/local/bin/apt`.  
Because `/usr/local/bin` comes before `/usr/bin` in `$PATH`, every time you  
type `apt`, your shell finds the wrapper first — not the real apt.

```
You type:  sudo apt install vim
               ↓
  /usr/local/bin/apt        ← wrapper intercepts
               ↓
  apt-get -s install vim    ← simulate first, collect package list
               ↓
  /usr/bin/apt install vim  ← real apt runs, fully interactive
               ↓
  exit code = 0?
               ↓  YES
  write record to /var/lib/apt-tracker/records.csv
```

**The real apt at `/usr/bin/apt` is never modified or renamed.**  
If the wrapper is deleted, `apt` falls back to the real one automatically.

### Why simulate first?

Before running the real apt, we run `apt-get -s` (simulate/dry-run).  
This tells us exactly which packages will be installed or removed — without  
touching the system. We save that list, then run the real apt. If it succeeds,  
we write records for exactly those packages.

This approach means:
- No pipes breaking interactive `[Y/n]` prompts
- No temp files or output parsing
- Already-installed packages are never recorded (simulate shows only changes)
- Failed apt runs produce zero records (nothing changed)

### Records file

All history is stored in a simple CSV:

```
/var/lib/apt-tracker/records.csv
```

Format:
```
action,package,version,timestamp,user,status
"install","vim","2:8.2.3995-1","2026-03-22 10:30:00","kali","success"
"remove","curl","7.88.1-10","2026-03-22 11:00:00","kali","success"
"update","(cache)","n/a","2026-03-22 12:00:00","kali","success"
"upgrade","bash","5.2.15-2","2026-03-23 09:00:00","kali","success"
```

Fields:

| Field     | Description                                                  |
|-----------|--------------------------------------------------------------|
| action    | install / remove / purge / upgrade / update / autoremove     |
| package   | package name                                                 |
| version   | version installed (n/a for removals)                         |
| timestamp | YYYY-MM-DD HH:MM:SS                                          |
| user      | real user (resolves SUDO_USER — shows kali, not root)        |
| status    | success / failed                                             |

---

## Project Files

```
apt-tracker/
├── apt            ← the wrapper script
├── install.sh     ← installer (run this first)
└── uninstall.sh   ← uninstaller
```

---

## Installation

### Requirements

- Debian / Ubuntu / Kali or any apt-based Linux distro
- Bash (pre-installed everywhere apt is)
- Root / sudo access

### Steps

```bash
# 1. Download the project
git clone https://github.com/yourname/apt-tracker
cd apt-tracker

# 2. Run the installer as root
sudo bash install.sh
```

### What the installer does

| Step | Action |
|------|--------|
| 1 | Verifies running as root |
| 2 | Checks real apt exists at `/usr/bin/apt` |
| 3 | Checks wrapper source `apt` is in the same folder as `install.sh` |
| 4 | Creates `/var/lib/apt-tracker/` directory |
| 5 | Creates `records.csv` with CSV header |
| 6 | Copies wrapper to `/usr/local/bin/apt` with 755 permissions |
| 7 | Adds your user to `adm` group (for dpkg.log read access) |
| 8 | Writes a bootstrap install record |

### After installation

Open a new terminal or run:
```bash
newgrp adm
```
This applies the `adm` group change immediately without logging out.

Verify the wrapper is active:
```bash
which apt
# expected: /usr/local/bin/apt
```

---

## Uninstallation

```bash
sudo bash uninstall.sh
```

The uninstaller:
- Checks that `/usr/local/bin/apt` is our wrapper before touching it
- Removes the wrapper
- Asks whether to delete the records and tracker directory
- Never touches `/usr/bin/apt`

After uninstall, `apt` automatically falls back to the real `/usr/bin/apt`.

---

## Commands

All normal `apt` commands work exactly as before — nothing changes for regular use.  
The wrapper adds one new top-level command: **`apt history`**.

---

### View all history

```bash
apt history
```

```
ACTION       PACKAGE              VERSION              TIMESTAMP            USER       STATUS
──────────────────────────────────────────────────────────────────────────────────────────────
install      vim                  2:8.2.3995-1         2026-03-22 10:30:00  kali       success
install      curl                 7.88.1-10             2026-03-22 10:30:01  kali       success
remove       nano                 7.2-1                2026-03-22 11:00:00  kali       success
update       (cache)              n/a                  2026-03-22 12:00:00  kali       success
upgrade      bash                 5.2.15-2             2026-03-23 09:00:00  kali       success
──────────────────────────────────────────────────────────────────────────────────────────────
  Total: 5 record(s)
```

---

### Filter by action

```bash
apt history install       # only installs
apt history remove        # only removes and purges
apt history upgrade       # only upgrades (includes full-upgrade, dist-upgrade)
apt history update        # only cache updates (apt update)
apt history autoremove    # only autoremoves
```

---

### Filter by time period

```bash
apt history week          # last 7 days
apt history month         # last 30 days
apt history year          # last 365 days
```

---

### Combine action + time period

Both orders work:

```bash
apt history install week        # packages installed in last 7 days
apt history remove month        # packages removed in last 30 days
apt history upgrade year        # packages upgraded in last 365 days
apt history week install        # same result — order does not matter
```

---

### Search by package name

Partial match supported:

```bash
apt history search vim
apt history search python
apt history search lib          # matches libssl, libcurl, etc.
```

---

### Statistics

```bash
apt history stats
```

```
  Installs    : 42
  Removes     : 7
  Upgrades    : 103
  Updates     : 15
  Autoremoves : 3
  Failed      : 1
  ──────────────
  Total       : 171
  File        : /var/lib/apt-tracker/records.csv
```

---

### Export records

```bash
apt history export                        # saves to ~/apt-history-YYYYMMDD_HHMMSS.csv
apt history export /tmp/mybackup.csv      # saves to specified path
```

---

### Clear history

```bash
apt history clear
```

Prompts for confirmation before wiping. Resets the CSV to just the header row.

---

### Help

```bash
apt history help
```

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Package already installed | `apt-get -s` reports nothing to do → no record written |
| apt command fails (non-zero exit) | No records written — system was not changed |
| `apt update` | Single record: action=`update`, package=`(cache)`, version=`n/a` |
| `apt upgrade` | Records upgraded packages (`Inst` lines) AND removed obsolete ones (`Remv` lines) |
| Running without sudo | `SUDO_USER` not set — records the current user via `whoami` |
| Running with sudo | `SUDO_USER` resolved — records real username, not `root` |
| Two apt runs simultaneously | `flock` file lock prevents corrupt CSV writes |
| Records file missing | Recreated automatically with header on next write |
| Wrapper deleted manually | Shell falls back to `/usr/bin/apt` — system still works |
| Non-tracked subcommands (`apt list`, `apt show`, etc.) | Passed directly to real apt with `exec` — zero overhead |

---

## Manual CSV Access

Records are plain CSV — query them with any standard tool:

```bash
# view raw file
cat /var/lib/apt-tracker/records.csv

# count total installs
grep '"install"' /var/lib/apt-tracker/records.csv | wc -l

# find everything from a specific date
grep '2026-03-22' /var/lib/apt-tracker/records.csv

# list all packages installed this month
grep '"install"' /var/lib/apt-tracker/records.csv | grep '2026-03'

# open in spreadsheet
libreoffice --calc /var/lib/apt-tracker/records.csv
```

---

## File Locations

| Path | Description |
|------|-------------|
| `/usr/local/bin/apt` | Wrapper script |
| `/usr/bin/apt` | Real apt — never touched |
| `/var/lib/apt-tracker/` | Tracker data directory |
| `/var/lib/apt-tracker/records.csv` | All history records |
| `/var/lib/apt-tracker/lock` | Write lock file (auto-managed) |
