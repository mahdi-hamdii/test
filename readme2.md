# XLD Monitoring and Logging Setup

This guide explains how to install and configure both centralized **monitoring** and **logging** on an XLD instance.

## Contents

- [1. Prerequisites](#1-prerequisites)
- [2. Setup Monitoring (collectd)](#2-setup-monitoring-collectd)
- [3. Setup Logging (rsyslog)](#3-setup-logging-rsyslog)

---

## 1. Prerequisites

- You must run the setup scripts **as root**
- Begin by obtaining **temporary sudo rights**
- These scripts are designed for RHEL-based systems using `yum`
- Create folder named `xld-observability`
## 2. Setup Monitoring (collectd)
The monitoring setup uses collectd to gather system metrics and forward them to Logstash.

### Steps:
#### 1. Create the monitoring script
```bash
cd xld-observability
vi setup-collectd.sh
```
#### 2. Paste the setup-collectd.sh script into the file.
#### 3. Ensure the following variables are set correctly in the script:
```bash
VM_NAME="xldeploy-prod-00"
LOGSTASH_HOST="logstash-collector.world.socgen"
LOGSTASH_PORT="5044"
```
#### 4. Copy collectd.conf.j2 file inside xld-observability folder
#### 5. Run the script
```bash
chmod +x setup-collectd.sh
./setup-collectd.sh
```
This will:

- Install collectd with epel enabled
- Render the configuration
- Deploy it to /etc/collectd.conf
- Restart the collectd service
---
## 3. Setup Logging (rsyslog)
The logging setup forwards XLD logs over TLS using rsyslog and also manages log rotation.

### Steps:

### 1. Gain root access

If you're a regular user:

```bash
sudo su
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

## After Running these scripts:
After Running Both Scripts
- Your XLD instance will be configured to:
- Monitor system metrics via collectd
- Forward logs securely using rsyslog
- Rotate logs cleanly to manage disk usage
