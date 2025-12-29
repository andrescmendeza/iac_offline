#!/bin/bash
# configure_slave.sh - Configure JMeter slave node

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config/slave"
JMETER_HOME="${JMETER_HOME:-/opt/jmeter}"

echo "Configuring JMeter slave node..."

# Check if JMeter is installed
if [ ! -d "${JMETER_HOME}" ]; then
    echo "Error: JMeter not found at ${JMETER_HOME}"
    echo "Please run install_jmeter.sh first."
    exit 1
fi

# Check if slave configuration exists
if [ ! -f "${CONFIG_DIR}/jmeter.properties" ]; then
    echo "Error: Slave configuration not found at ${CONFIG_DIR}/jmeter.properties"
    exit 1
fi

# Backup existing configuration if it exists
if [ -f "${JMETER_HOME}/bin/jmeter.properties" ]; then
    echo "Backing up existing JMeter configuration..."
    sudo cp "${JMETER_HOME}/bin/jmeter.properties" "${JMETER_HOME}/bin/jmeter.properties.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy slave configuration
echo "Applying slave configuration..."
sudo cp "${CONFIG_DIR}/jmeter.properties" "${JMETER_HOME}/bin/jmeter.properties"

# Get the slave node's IP address
SLAVE_IP=$(hostname -I | awk '{print $1}')
echo "Detected slave IP address: ${SLAVE_IP}"

# Prompt to confirm or change
read -p "Is this the correct IP address? (y/n): " CONFIRM
if [ "${CONFIRM}" != "y" ]; then
    read -p "Enter the correct IP address: " SLAVE_IP
fi

echo ""
echo "Slave node configuration completed!"
echo "Configuration file: ${JMETER_HOME}/bin/jmeter.properties"
echo "Slave IP: ${SLAVE_IP}"
echo ""
echo "To start the slave node, run: scripts/start_slave.sh"
echo "Make sure to add this IP (${SLAVE_IP}) to the master's remote_hosts configuration."
