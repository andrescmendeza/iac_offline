#!/bin/bash
# validate_cluster.sh - Validate JMeter cluster setup

set -e

JMETER_HOME="${JMETER_HOME:-/opt/jmeter}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================="
echo "JMeter Cluster Validation"
echo "==================================="
echo ""

# Function to print status
print_status() {
    local check_name=$1
    local status=$2
    if [ "${status}" = "OK" ]; then
        echo "✓ ${check_name}: OK"
    else
        echo "✗ ${check_name}: FAILED - ${status}"
    fi
}

# Check Java installation
echo "1. Checking Java installation..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    print_status "Java installed" "OK"
    echo "   Version: ${JAVA_VERSION}"
else
    print_status "Java installed" "Java not found. Run install_java.sh"
fi
echo ""

# Check JMeter installation
echo "2. Checking JMeter installation..."
if [ -d "${JMETER_HOME}" ]; then
    print_status "JMeter installed" "OK"
    echo "   Location: ${JMETER_HOME}"
    
    if [ -f "${JMETER_HOME}/bin/jmeter" ]; then
        print_status "JMeter executable" "OK"
    else
        print_status "JMeter executable" "Not found"
    fi
else
    print_status "JMeter installed" "JMeter not found. Run install_jmeter.sh"
fi
echo ""

# Check JMeter configuration
echo "3. Checking JMeter configuration..."
if [ -f "${JMETER_HOME}/bin/jmeter.properties" ]; then
    print_status "JMeter configuration" "OK"
    
    # Check for remote_hosts configuration
    if grep -q "^remote_hosts=" "${JMETER_HOME}/bin/jmeter.properties"; then
        REMOTE_HOSTS=$(grep "^remote_hosts=" "${JMETER_HOME}/bin/jmeter.properties" | cut -d'=' -f2)
        echo "   Remote hosts configured: ${REMOTE_HOSTS}"
    else
        echo "   Warning: remote_hosts not configured"
    fi
else
    print_status "JMeter configuration" "Configuration file not found"
fi
echo ""

# Check network connectivity
echo "4. Checking network connectivity..."
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "   Local IP: ${LOCAL_IP}"

if [ -f "${JMETER_HOME}/bin/jmeter.properties" ]; then
    REMOTE_HOSTS=$(grep "^remote_hosts=" "${JMETER_HOME}/bin/jmeter.properties" 2>/dev/null | cut -d'=' -f2)
    if [ -n "${REMOTE_HOSTS}" ]; then
        IFS=',' read -ra HOSTS <<< "${REMOTE_HOSTS}"
        for host in "${HOSTS[@]}"; do
            host=$(echo "${host}" | xargs) # trim whitespace
            if ping -c 1 -W 2 "${host}" &> /dev/null; then
                print_status "Connectivity to ${host}" "OK"
            else
                print_status "Connectivity to ${host}" "Cannot reach host"
            fi
        done
    fi
fi
echo ""

# Check if JMeter server is running
echo "5. Checking JMeter server status..."
if pgrep -f "jmeter-server" > /dev/null; then
    print_status "JMeter server" "Running"
    echo "   PID: $(pgrep -f 'jmeter-server')"
else
    print_status "JMeter server" "Not running"
    echo "   (This is OK for master nodes)"
fi
echo ""

# Summary
echo "==================================="
echo "Validation completed!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  - For master: Run 'scripts/configure_master.sh' if not configured"
echo "  - For slave: Run 'scripts/configure_slave.sh' then 'scripts/start_slave.sh'"
echo "  - Verify all slave nodes are reachable from the master"
echo "  - Test connectivity between master and slaves on port 1099"
