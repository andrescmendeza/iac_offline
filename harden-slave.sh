#!/bin/bash
# ==========================================================
# JMeter SLAVE Hardening Script
# FINAL VERSION – READY FOR PRODUCTION
#
# Responsibilities:
#  - Pure load generation
#
# JVM Heap:
#  - Fixed 8 GB (Xms = Xmx)
# ==========================================================

set -e

echo "🔧 Hardening JMeter SLAVE node..."

# ----------------------------------------------------------
# 1. FILE DESCRIPTORS
# Purpose:
#  - Each virtual user consumes sockets and descriptors
# ----------------------------------------------------------
ulimit -n 65535

grep -q "jmeter soft nofile" /etc/security/limits.conf || cat <<EOF >> /etc/security/limits.conf
jmeter soft nofile 65535
jmeter hard nofile 65535
EOF

# ----------------------------------------------------------
# 2. KERNEL & TCP TUNING
# Purpose:
#  - Efficient TCP recycling under high throughput
# ----------------------------------------------------------
cat <<EOF > /etc/sysctl.d/99-jmeter.conf
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_syn_backlog = 4096
EOF

sysctl -p /etc/sysctl.d/99-jmeter.conf

# ----------------------------------------------------------
# 3. CPU GOVERNOR
# Purpose:
#  - Prevent CPU throttling during sustained load
# ----------------------------------------------------------
if command -v cpupower &>/dev/null; then
  cpupower frequency-set -g performance
fi

# ----------------------------------------------------------
# 4. JVM CONFIGURATION (SLAVE)
# Purpose:
#  - Stable throughput and predictable GC
# ----------------------------------------------------------
JMETER_BIN="/opt/jmeter/bin"

sed -i 's/-Xms.*/-Xms8g/' $JMETER_BIN/jmeter-server
sed -i 's/-Xmx.*/-Xmx8g/' $JMETER_BIN/jmeter-server

grep -q "UseG1GC" $JMETER_BIN/jmeter-server || cat <<EOF >> $JMETER_BIN/jmeter-server
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+DisableExplicitGC
EOF

# ----------------------------------------------------------
# 5. JMETER PROPERTIES – RESULT SAFETY
# Purpose:
#  - Ensure slaves NEVER store samples in memory
# ----------------------------------------------------------
JMETER_PROPS="$JMETER_BIN/jmeter.properties"

cat <<EOF >> $JMETER_PROPS

# ================== RMI CONFIG ==================
server.rmi.localport=4445
server_port=1099

# ================= RESULT STREAMING ==============
jmeter.save.saveservice.autoflush=true

jmeter.save.saveservice.response_data=false
jmeter.save.saveservice.response_headers=false
jmeter.save.saveservice.request_headers=false
jmeter.save.saveservice.samplerData=false
EOF

echo "⚠ Ensure ports 1099 and 4445 are open on this SLAVE"
echo "✅ JMeter SLAVE hardening completed successfully"
