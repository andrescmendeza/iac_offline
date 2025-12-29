#!/bin/bash
# install_jmeter.sh - Install JMeter from offline bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
JMETER_DIR="${REPO_ROOT}/jmeter"
INSTALL_DIR="/opt/jmeter"

echo "Installing JMeter from offline bundle..."

# Check if JMeter directories exist
if [ ! -d "${JMETER_DIR}/bin" ] || [ ! -d "${JMETER_DIR}/lib" ]; then
    echo "Error: JMeter bundle not found in ${JMETER_DIR}"
    echo "Please ensure jmeter/bin, jmeter/lib, and jmeter/plugins directories contain the required files."
    exit 1
fi

# Create installation directory
sudo mkdir -p "${INSTALL_DIR}"

# Copy JMeter files
echo "Copying JMeter files to ${INSTALL_DIR}..."
sudo cp -r "${JMETER_DIR}"/* "${INSTALL_DIR}/"

# Make JMeter scripts executable
sudo chmod +x "${INSTALL_DIR}"/bin/*.sh 2>/dev/null || true

# Set JMETER_HOME environment variable
echo "export JMETER_HOME=${INSTALL_DIR}" | sudo tee -a /etc/profile.d/jmeter.sh
echo "export PATH=\$JMETER_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/jmeter.sh

# Source the profile
source /etc/profile.d/jmeter.sh

echo "JMeter installation completed!"
echo "JMETER_HOME: ${JMETER_HOME}"

# Verify installation
if [ -f "${INSTALL_DIR}/bin/jmeter" ]; then
    echo "JMeter is ready to use."
else
    echo "Warning: JMeter executable not found. Please ensure the offline bundle is complete."
fi
