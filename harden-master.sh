#!/bin/bash
# ==========================================================
# JMeter MASTER Hardening Script
# FINAL VERSION – READY FOR PRODUCTION
#
# Responsibilities:
#  - Distributed test orchestration
#  - Result aggregation
#
# JVM Heap:
#  - Fixed 8 GB (Xms = Xmx)
# ==========================================================

set -e

echo "🔧 Hardening JMeter MASTER node..."

# ----------------------------------------------------------
# 1. FILE DESCRIPTORS
# Purpose:
#  - Prevent socket exhaustion (RMI + result streaming)
# ----------------------------------------------------------
ulimit -n 65535

grep -q "jmeter soft nofile" /etc/security/limits.conf || cat <<EOF >> /etc/security/limits.conf
jmeter soft nofile 65535
jmeter hard nofile 65535
EOF

# ----------------------------------------------------------
# 2. KERNEL & TCP TUNING
# Purpose:
#  - Avoid ephemeral port exhaustion
#  - Reduce TIME_WAIT accumulation
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
#  - Avoid CPU frequency scaling during tests
# ----------------------------------------------------------
if command -v cpupower &>/dev/null; then
  cpupower frequency-set -g performance
fi

# ----------------------------------------------------------
# 4. JVM CONFIGURATION (MASTER)
# Purpose:
#  - Fixed heap avoids GC noise and resizing pauses
# ----------------------------------------------------------
JMETER_BIN="/opt/jmeter/bin"

sed -i 's/-Xms.*/-Xms8g/' $JMETER_BIN/jmeter
sed -i 's/-Xmx.*/-Xmx8g/' $JMETER_BIN/jmeter

grep -q "UseG1GC" $JMETER_BIN/jmeter || cat <<EOF >> $JMETER_BIN/jmeter
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-Xlog:gc*:file=gc-master.log:time,uptime,level,tags
EOF

# ----------------------------------------------------------
# 5. JMETER PROPERTIES – RESULT HANDLING (CRITICAL)
# Purpose:
#  - Ensure samples are NOT kept in memory
#  - Stream results directly to disk
# ----------------------------------------------------------
JMETER_PROPS="$JMETER_BIN/jmeter.properties"

cat <<EOF >> $JMETER_PROPS

# ================== RMI CONFIG ==================
server.rmi.localport=4445
server_port=1099

# ================= RESULT STREAMING ==============
jmeter.save.saveservice.autoflush=true

# Disable payload storage (memory protection)
jmeter.save.saveservice.response_data=false
jmeter.save.saveservice.response_headers=false
jmeter.save.saveservice.request_headers=false
jmeter.save.saveservice.samplerData=false

# Store only minimal required metrics
jmeter.save.saveservice.label=true
jmeter.save.saveservice.success=true
jmeter.save.saveservice.time=true
jmeter.save.saveservice.bytes=true
jmeter.save.saveservice.latency=true
jmeter.save.saveservice.thread_counts=true

# CSV output for efficient post-processing
jmeter.save.saveservice.output_format=csv
EOF

echo "✅ JMeter MASTER hardening completed successfully"
