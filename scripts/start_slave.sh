#!/bin/bash
# start_slave.sh - Start JMeter slave server

set -e

JMETER_HOME="${JMETER_HOME:-/opt/jmeter}"

echo "Starting JMeter slave server..."

# Check if JMeter is installed
if [ ! -d "${JMETER_HOME}" ]; then
    echo "Error: JMeter not found at ${JMETER_HOME}"
    echo "Please run install_jmeter.sh first."
    exit 1
fi

# Check if jmeter-server script exists
if [ ! -f "${JMETER_HOME}/bin/jmeter-server" ]; then
    echo "Error: jmeter-server script not found at ${JMETER_HOME}/bin/jmeter-server"
    exit 1
fi

# Get slave IP
SLAVE_IP=$(hostname -I | awk '{print $1}')

echo "Slave IP: ${SLAVE_IP}"
echo "Starting JMeter server on port 1099..."

# Start JMeter server
cd "${JMETER_HOME}/bin"
./jmeter-server &

JMETER_PID=$!

echo ""
echo "JMeter slave server started with PID: ${JMETER_PID}"
echo "Slave is listening on ${SLAVE_IP}:1099"
echo ""
echo "To check if the server is running:"
echo "  ps aux | grep jmeter-server"
echo ""
echo "To stop the server:"
echo "  kill ${JMETER_PID}"
echo ""
echo "Logs can be found at: ${JMETER_HOME}/bin/jmeter-server.log"
