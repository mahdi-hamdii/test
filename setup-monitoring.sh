#!/bin/bash

set -e

# === Configuration Variables ===
VM_NAME="xldeploy-prod-00"
LOGSTASH_HOST="logstash-collector.world.socgen"
LOGSTASH_PORT="5044"
TEMPLATE_FILE="./collectd.conf.j2"
FINAL_CONF="/etc/collectd.conf"

echo "Installing collectd from EPEL..."
yum install -y --enablerepo=epel collectd

echo "Rendering collectd config from template..."
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Template file $TEMPLATE_FILE not found!"
  exit 1
fi

RENDERED=$(cat "$TEMPLATE_FILE" \
  | sed "s|{{ *vm_name *}}|$VM_NAME|g" \
  | sed "s|{{ *logstash_host *}}|$LOGSTASH_HOST|g" \
  | sed "s|{{ *logstash_port *}}|$LOGSTASH_PORT|g")

echo "$RENDERED" > "$FINAL_CONF"

echo "collectd config deployed to $FINAL_CONF"
systemctl restart collectd
