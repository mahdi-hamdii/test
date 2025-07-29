#!/bin/bash

set -e

# Define paths
SOURCE_LOG="/data_xldeploy_00/deployit/your/path/deployit.log"
TARGET_LOG="/var/log/deployit/deployit.log"
FORWARDER_SCRIPT="/usr/local/bin/deployit-log-forwarder.sh"
SERVICE_FILE="/etc/systemd/system/deployit-forwarder.service"
LOGROTATE_CONF="/etc/logrotate.d/deployit"

echo "Creating log directory and target log file..."
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

echo "Creating systemd service unit..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Deployit Log Forwarder to $TARGET_LOG
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

echo "Reloading systemd and enabling forwarder service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now deployit-forwarder.service

echo "Creating logrotate config for $TARGET_LOG..."
cat > "$LOGROTATE_CONF" <<EOF
$TARGET_LOG {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
EOF

echo "Validating logrotate config..."
logrotate --debug "$LOGROTATE_CONF"

echo "Deployit log forwarding and rotation setup complete."
systemctl status deployit-forwarder.service
