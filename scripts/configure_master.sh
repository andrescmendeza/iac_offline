#!/bin/bash
# configure_master.sh - Configure JMeter master node

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config/master"
JMETER_HOME="${JMETER_HOME:-/opt/jmeter}"

echo "Configuring JMeter master node..."

# Check if JMeter is installed
if [ ! -d "${JMETER_HOME}" ]; then
    echo "Error: JMeter not found at ${JMETER_HOME}"
    echo "Please run install_jmeter.sh first."
    exit 1
fi

# Check if master configuration exists
if [ ! -f "${CONFIG_DIR}/jmeter.properties" ]; then
    echo "Error: Master configuration not found at ${CONFIG_DIR}/jmeter.properties"
    exit 1
fi

# Backup existing configuration if it exists
if [ -f "${JMETER_HOME}/bin/jmeter.properties" ]; then
    echo "Backing up existing JMeter configuration..."
    sudo cp "${JMETER_HOME}/bin/jmeter.properties" "${JMETER_HOME}/bin/jmeter.properties.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copy master configuration
echo "Applying master configuration..."
sudo cp "${CONFIG_DIR}/jmeter.properties" "${JMETER_HOME}/bin/jmeter.properties"

# Prompt for slave IPs
echo ""
echo "Please enter the IP addresses of slave nodes (comma-separated):"
echo "Example: 192.168.1.10,192.168.1.11,192.168.1.12"
read -p "Slave IPs: " SLAVE_IPS

if [ -n "${SLAVE_IPS}" ]; then
    # Update remote_hosts in jmeter.properties
    sudo sed -i "s/^remote_hosts=.*/remote_hosts=${SLAVE_IPS}/" "${JMETER_HOME}/bin/jmeter.properties"
    echo "Updated remote_hosts with: ${SLAVE_IPS}"
fi

echo ""
echo "Master node configuration completed!"
echo "Configuration file: ${JMETER_HOME}/bin/jmeter.properties"
echo ""
echo "To start a distributed test, use:"
echo "  jmeter -n -t test_plan.jmx -r -l results.jtl"
