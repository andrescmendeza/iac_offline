#!/bin/bash
# install_java.sh - Install Java JDK from offline archive

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
JAVA_DIR="${REPO_ROOT}/java"
INSTALL_DIR="/opt/java"

echo "Installing Java JDK from offline archive..."

# Check if JDK archive exists
if [ ! -f "${JAVA_DIR}/jdk.tar.gz" ]; then
    echo "Error: JDK archive not found at ${JAVA_DIR}/jdk.tar.gz"
    echo "Please place the JDK archive in the java directory."
    exit 1
fi

# Create installation directory
sudo mkdir -p "${INSTALL_DIR}"

# Extract JDK
echo "Extracting JDK to ${INSTALL_DIR}..."
sudo tar -xzf "${JAVA_DIR}/jdk.tar.gz" -C "${INSTALL_DIR}"

# Find the extracted JDK directory
JDK_EXTRACTED=$(sudo find "${INSTALL_DIR}" -maxdepth 1 -type d -name "jdk*" | head -n 1)

if [ -z "${JDK_EXTRACTED}" ]; then
    echo "Error: Could not find extracted JDK directory"
    exit 1
fi

# Create symbolic link for easier access
sudo ln -sf "${JDK_EXTRACTED}" "${INSTALL_DIR}/current"

# Set JAVA_HOME environment variable
echo "export JAVA_HOME=${INSTALL_DIR}/current" | sudo tee -a /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/java.sh

# Source the profile
source /etc/profile.d/java.sh

# Verify installation
echo "Java installation completed!"
java -version

echo "JAVA_HOME: ${JAVA_HOME}"
