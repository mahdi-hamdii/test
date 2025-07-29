#!/bin/bash

set -e

### === Top-level Configuration ===
SOURCE_LOG="/data_xldeploy_00/deployit/your/path/deployit.log"
TARGET_LOG="/var/log/deployit/deployit.log"
FORWARDER_SCRIPT="/usr/local/bin/deployit-log-forwarder.sh"
SERVICE_FILE="/etc/systemd/system/deployit-forwarder.service"
LOGROTATE_CONF="/etc/logrotate.d/deployit-log"
RSYSLOG_CERT_DIR="/etc/rsyslog/certs"
RSYSLOG_CA_FILE="$RSYSLOG_CERT_DIR/ca.pem"
RSYSLOG_APPLI_CONF="/etc/rsyslog.appli.d/xldeploy.conf"
LOCAL_HOSTNAME="XLDeploy-TST-00-v25-az1"
RSYSLOG_TARGET="xldeploy-log-collector-dev.fr.world.socgen"
RSYSLOG_PORT="10514"

### === 1. Log Forwarder Setup ===
echo "Creating target log directory..."
mkdir -p "$(dirname "$TARGET_LOG")"
touch "$TARGET_LOG"
restorecon -v "$TARGET_LOG"

echo "Creating log forwarder script..."
cat > "$FORWARDER_SCRIPT" <<EOF
#!/bin/bash

while [ ! -f "$SOURCE_LOG" ]; do
  sleep 5
done

tail -F "$SOURCE_LOG" >> "$TARGET_LOG"
EOF

chmod +x "$FORWARDER_SCRIPT"

echo "Creating systemd service for forwarder..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Deployit Log Forwarder
After=network.target

[Service]
ExecStart=$FORWARDER_SCRIPT
Restart=always
RestartSec=5
StandardOutput=null
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now deployit-forwarder.service

### === 2. Logrotate Setup ===
echo "Setting up logrotate config..."
cat > "$LOGROTATE_CONF" <<EOF
$TARGET_LOG {
  daily
  rotate 7
  missingok
  compress
  delaycompress
  notifempty
  dateext
  dateformat .%Y-%m-%d_%s
  copytruncate
}
EOF

### === 3. rsyslog TLS Forwarding Setup ===
echo "Installing rsyslog-gnutls..."
yum install -y rsyslog-gnutls

echo "Writing CA certificate..."
mkdir -p "$RSYSLOG_CERT_DIR"
cat > "$RSYSLOG_CA_FILE" <<'EOF'
-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----
EOF
chmod 644 "$RSYSLOG_CA_FILE"

echo "Creating rsyslog forwarding config..."
mkdir -p "$(dirname "$RSYSLOG_APPLI_CONF")"
cat > "$RSYSLOG_APPLI_CONF" <<EOF
\$LocalHostName $LOCAL_HOSTNAME

module(load="imfile" PollingInterval="10")
input(type="imfile"
  File="$TARGET_LOG"
  Tag="deployit"
  reopenOnTruncate="on"
)

global(
  DefaultNetstreamDriver="gtls"
  DefaultNetstreamDriverCAFile="$RSYSLOG_CA_FILE"
)

if (\$programname contains 'deployit'
 or \$programname contains 'systemd' or \$programname contains 'sudo'
 or \$programname contains 'sshd') then {
  action(
    type="omfwd" target="$RSYSLOG_TARGET" protocol="tcp" port="$RSYSLOG_PORT"
    StreamDriver="gtls" StreamDriverMode="1" StreamDriverAuthMode="anon"
    template="RSYSLOG_SyslogProtocol23Format"
  )
  stop
}
EOF

echo "Restarting rsyslog service..."
systemctl restart rsyslog

echo "All components installed and configured."
