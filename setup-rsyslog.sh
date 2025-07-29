#!/bin/bash

set -e

# === Configuration Variables ===
LOCAL_HOSTNAME="XLDeploy-TST-00-v25-az1"
TARGET_HOST="xldeploy-log-collector-dev.fr.world.socgen"
PORT="10514"

# === Paths ===
CERT_DIR="/etc/rsyslog/certs"
CA_FILE="$CERT_DIR/ca.pem"
CONF_DIR="/etc/rsyslog.appli.d"
CONF_FILE="$CONF_DIR/xldeploy.conf"

echo "📦 Installing rsyslog-gnutls..."
yum install -y rsyslog-gnutls

echo "📁 Creating certificate directory..."
mkdir -p "$CERT_DIR"

echo "🔐 Writing CA certificate to $CA_FILE..."
cat > "$CA_FILE" <<'EOF'
-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----
EOF

chmod 644 "$CA_FILE"

echo "📁 Creating rsyslog config directory..."
mkdir -p "$CONF_DIR"

echo "📝 Writing xldeploy rsyslog config to $CONF_FILE..."
cat > "$CONF_FILE" <<EOF
\$LocalHostName $LOCAL_HOSTNAME

module(load="imfile" PollingInterval="10")
input(type="imfile"
  File="/var/log/deployit/deployit.log"
  Tag="deployit"
  reopenOnTruncate="on"
)

global(
  DefaultNetstreamDriver="gtls"
  DefaultNetstreamDriverCAFile="$CA_FILE"
)

if (\$programname contains 'deployit'
 or \$programname contains 'systemd' or \$programname contains 'sudo'
 or \$programname contains 'sshd') then {
  action(
    type="omfwd" target="$TARGET_HOST" protocol="tcp" port="$PORT"
    StreamDriver="gtls" StreamDriverMode="1" StreamDriverAuthMode="anon"
    template="RSYSLOG_SyslogProtocol23Format"
  )
  stop
}
EOF

echo "Restarting rsyslog service..."
systemctl restart rsyslog

echo "Rsyslog TLS forwarding setup complete and rsyslog restarted."
