# APT Tracker Wrapper

A simple wrapper for `apt` that tracks only applications explicitly installed by the user.
It avoids dependency noise and keeps a clean, readable list of installed tools.

---

## Overview

This utility replaces the default `apt` command (via `/usr/local/bin/apt`) and records only the package names provided by the user during installation. Automatically installed dependencies are ignored.

The result is a clear and minimal list of user-installed applications.

---

## Features

* Tracks only user-installed applications
* Ignores dependencies installed by APT
* Removes entries when applications are uninstalled
* Displays a clean table with:

  * Package name
  * Version
  * Installation time
  * User
* Uses the original `/usr/bin/apt` for all operations
* Lightweight and predictable behavior

---

## Installation

```bash
chmod +x apt-wrapper.sh
sudo mv apt-wrapper.sh /usr/local/bin/apt
```

Ensure `/usr/local/bin` is before `/usr/bin` in your PATH:

```bash
echo $PATH
```

---

## Uninstall

```bash
sudo rm /usr/local/bin/apt
hash -r
```

---

## Usage

### Install applications

```bash
sudo apt install nmap curl
```

### Remove applications

```bash
sudo apt remove curl
```

### View tracked applications

```bash
apt history
```

### Help

```bash
apt history help
```

---

## Example Output

```
PACKAGE                   VERSION              INSTALLED ON        USER
---------------------------------------------------------------------------
nmap                      7.94-1               2026-03-26 16:10:12 kali
---------------------------------------------------------------------------
Total apps: 1
```

---

## How It Works

* Intercepts `install`, `remove`, and `purge` commands
* Extracts only user-provided package names
* Stores records in:

  ```
  /var/lib/apt-tracker/apps.csv
  ```
* Updates the list only when commands complete successfully

---

## Limitations

* Tracks only CLI usage of `apt install`
* Does not track:

  * Dependencies
  * GUI-based installations
  * Manual `.deb` installs
* Meta-packages are stored as a single entry

---

## File Locations

```
/usr/local/bin/apt                Wrapper script
/usr/bin/apt                      Original apt binary
/var/lib/apt-tracker/apps.csv     Stored application data
```

---

## Safety

* Does not modify the original APT binary
* Falls back to system APT for unsupported commands
* Uses file locking to prevent concurrent write issues

---

## License

MIT License
