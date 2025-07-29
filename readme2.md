# XLD Logging Setup – README

This guide walks you through installing and configuring centralized logging on an **XLD instance** using the provided `setup-logging.sh` script.

---

## What this script does

The script automates:

- Log forwarding from the XLD log file
- Systemd service setup to mirror logs into `/var/log/deployit/deployit.log`
- Log rotation for clean disk usage
- TLS-based `rsyslog` forwarding to a central log collector (dev or prod)

---

## Requirements

- This script **must be run as root**
- You'll need **temporary sudo rights** on the instance
- Works on systems using `yum` (RHEL-based)

---

## How to Use

### 1. Gain root access

If you're a regular user:

```bash
sudo -v      # Refresh sudo credentials
sudo su -    # Become root
```
### 2. Create the setup script
```bash
vi setup-logging.sh
```
Paste the full content of the setup-logging.sh script inside and save.

### 3. Edit configuration variables
```bash
SOURCE_LOG="/path/to/your/xldeploy.log"    # E.g., /data_xldeploy_00/deployit/.../deployit.log
LOCAL_HOSTNAME="XLDeploy-TST-00-v25-az1"   # Must match the server name
RSYSLOG_TARGET="xldeploy-log-collector-dev.fr.world.socgen"
```
Use -dev in the hostname for DEV
Use xldeploy-log-collector.fr.world.socgen (no -dev) for PROD

### 4. Make the script executable
```bash
chmod +x setup-logging.sh
```
### 5. Run the script
```bash
./setup-logging.sh
```
This will:
- Start log forwarding
- Configure logrotate
- Install TLS cert and configure rsyslog
- Restart rsyslog to activate forwarding

## After Running this script:
The logging setup will be complete. Logs from XLD will be:
- Stored and rotated in /var/log/deployit/deployit.log
- Forwarded securely to the central log collector over TLS
