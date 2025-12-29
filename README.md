# iac_offline

Git Repo
│
├─ jmeter/
│   ├─ bin/                 (offline bundle)
│   ├─ lib/
│   ├─ plugins/
│
├─ java/
│   └─ jdk.tar.gz
│
├─ config/
│   ├─ master/
│   │   └─ jmeter.properties
│   ├─ slave/
│   │   └─ jmeter.properties
│
├─ scripts/
│   ├─ install_java.sh
│   ├─ install_jmeter.sh
│   ├─ configure_master.sh
│   ├─ configure_slave.sh
│   ├─ start_slave.sh
│   └─ validate_cluster.sh
│
└─ pipelines/
    └─ setup-jmeter.yml


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

Flujo del pipeline para ejecucion de los test

Dev / QA
  │
  ▼
Git Repo (tests)
  │
  ▼
Azure DevOps Pipeline
  │
  ├─ Checkout repo
  ├─ Copiar tests al Master (.31)
  ├─ Seleccionar qué test correr
  ├─ Ejecutar JMeter (CLI)
  ├─ Recoger resultados
  └─ Publicar artefactos

4️⃣ Estructura típica del repositorio
jmeter-tests/
│
├─ tests/
│   ├─ login_test.jmx
│   ├─ checkout_test.jmx
│   └─ search_test.jmx
│
├─ data/
│   ├─ users.csv
│   └─ products.csv
│
├─ properties/
│   ├─ dev.properties
│   ├─ qa.properties
│   └─ perf.properties
│
├─ scripts/
│   └─ run_jmeter.sh
│
└─ azure-pipelines.yml

1️⃣2️⃣ Flujo visual final
Git (tests)
   │
   ▼
Azure Pipeline
   │
   ▼
Agent (.31)
   │
   ▼
JMeter Master
   │
   ├─ Slave (.32)
   └─ Slave (.33)

   🔑 Reglas de oro (muy importantes)

Tests viven en Git

Pipeline siempre orquesta

JMeter nunca decide

Resultados no se versionan

Master = punto de control


8️⃣ Ejemplo REAL de pipeline
trigger: none

parameters:
- name: test
  default: checkout_test.jmx

pool:
  name: jmeter-master

steps:
- checkout: self

- script: |
    /opt/jmeter/bin/jmeter \
      -n \
      -t tests/${{ parameters.test }} \
      -R 10.0.0.32,10.0.0.33 \
      -l results.jtl \
      -e -o report/
  displayName: Run JMeter Test

- publish: report
  artifact: jmeter-report

9️⃣ ¿Cómo JMeter ejecuta realmente?
En el Master (.31):
jmeter -n \
  -t checkout_test.jmx \
  -R slave1,slave2


JMeter:

Lee el .jmx

Distribuye el plan a los slaves

Ejecuta carga desde los slaves

Recoge métricas

Genera resultados

🔟 ¿Cómo se versiona un cambio de test?

Ejemplo:

Ajustas el ramp-up

Cambias assertions

Cambias timers

👉 Commit → Push → Pipeline ejecuta nueva versión
👉 Repetible
👉 Audit trail completo

1️⃣1️⃣ Qué pasa si agrego un nuevo test

Agregas new_api_test.jmx

Commit a Git

Ejecutas pipeline pasando:

test = new_api_test.jmx


JMeter lo corre

📌 Nada se “auto-activa”.
