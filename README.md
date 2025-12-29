# iac_offline

🔧 Paso 1 — Empaquetar JMeter (offline)

Desde una máquina con internet:

Descargas:

JDK (misma versión)

Apache JMeter

Plugins necesarios

Los comprimes:

tar -czf jmeter-bundle.tar.gz apache-jmeter/


Este bundle se convierte en artefacto.

🔧 Paso 2 — Scripts idempotentes (clave)

Ejemplo: install_jmeter.sh

if [ ! -d /opt/jmeter ]; then
  tar -xzf jmeter-bundle.tar.gz -C /opt
fi


👉 Puedes correrlo 10 veces y no rompe nada.

🔧 Paso 3 — Configuración declarativa
Master:
remote_hosts=10.0.0.32,10.0.0.33
server.rmi.ssl.disable=true

Slaves:
server_port=1099
server.rmi.ssl.disable=true


Copiadas automáticamente según rol.

🔧 Paso 4 — Validaciones automáticas

Ejemplo:

nc -z 10.0.0.32 1099
nc -z 10.0.0.33 1099


Fail = pipeline falla.

🚀 Paso 5 — Azure DevOps Pipeline (IaC runner)
Pipeline de setup (solo corre cuando hay cambios)
stages:
- stage: SetupJMeter
  jobs:
  - job: ConfigureMaster
    pool: jmeter-master
    steps:
    - script: scripts/install_java.sh
    - script: scripts/install_jmeter.sh
    - script: scripts/configure_master.sh

  - job: ConfigureSlaves
    pool: jmeter-slaves
    steps:
    - script: scripts/install_java.sh
    - script: scripts/install_jmeter.sh
    - script: scripts/configure_slave.sh
