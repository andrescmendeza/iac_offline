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















1️⃣ Arquitectura final – Master, agentes, slaves y tests
📍 Infra física / lógica
┌────────────────────────────┐
│ Azure DevOps                │
│  - Pipelines                │
└────────────┬───────────────┘
             │
             ▼
┌────────────────────────────┐
│ JMeter Master (.31)         │
│ - Azure DevOps Agent        │
│ - JMeter CLI                │
│ - Scripts ejecución         │
│ - Workspace de pipelines    │
└────────────┬───────────────┘
             │ RMI
     ┌───────┴────────┐
     ▼                ▼
┌─────────────┐  ┌─────────────┐
│ Slave (.32) │  │ Slave (.33) │
│ - JMeter    │  │ - JMeter    │
│ - Java      │  │ - Java      │
└─────────────┘  └─────────────┘


📌 Reglas claras:

El agente vive solo en el master

Los slaves no conocen Azure DevOps

El pipeline controla al master

JMeter no toma decisiones

2️⃣ Flujo de ejecución del pipeline (end-to-end)
Trigger manual / schedule
        │
        ▼
Stage 1 — Prepare
  - Checkout repos
  - Validaciones
        │
        ▼
Stage 2 — Execute Test
  - Run JMeter
  - Distributed load
        │
        ▼
Stage 3 — Validate Results
  - Parse JTL
  - Apply thresholds
        │
        ▼
Stage 4 — Publish
  - Artifacts
  - Metrics (Datadog)
  - Notifications


📌 Pipeline = orquestador total

3️⃣ Estructura del pipeline (stages reales)
🧩 Stage 1 — Prepare

Objetivo: dejar todo listo y fallar rápido si algo está mal.

Checkout repos

Validar conexión a slaves

Validar parámetros

- stage: Prepare
  jobs:
  - job: Precheck
    steps:
    - checkout: self
    - checkout: tests
    - script: scripts/validate_cluster.sh

🧩 Stage 2 — Execute

Objetivo: ejecutar exactamente UN test.

- stage: Execute
  jobs:
  - job: RunJMeter
    steps:
    - script: |
        jmeter -n \
          -t tests/$(TEST_FILE) \
          -R $(SLAVES) \
          -l results/results.jtl \
          -e -o report/

🧩 Stage 3 — Validate

Objetivo: decidir PASS / FAIL.

Parse .jtl

Evaluar SLAs

Fallar pipeline si no cumple

- stage: Validate
  jobs:
  - job: Evaluate
    steps:
    - script: python scripts/evaluate_results.py

🧩 Stage 4 — Publish

Objetivo: sacar resultados fuera del pipeline.

Artifacts

Datadog

Slack / Confluence

4️⃣ Estructura del nuevo repositorio (pipelines + config)
📦 Repo: perf-platform
perf-platform/
│
├─ pipelines/
│   ├─ performance.yml
│   ├─ stress.yml
│   ├─ endurance.yml
│
├─ scripts/
│   ├─ run_jmeter.sh
│   ├─ validate_cluster.sh
│   ├─ evaluate_results.py
│   └─ push_metrics_datadog.py
│
├─ config/
│   ├─ environments/
│   │   ├─ qa.yml
│   │   └─ perf.yml
│   ├─ thresholds/
│   │   ├─ performance.yml
│   │   ├─ stress.yml
│   │   └─ endurance.yml
│
└─ docs/
    └─ operating-model.md

5️⃣ Repo de tests (independiente)
📦 Repo: perf-tests
perf-tests/
│
├─ performance/
│   ├─ login_perf.jmx
│   └─ checkout_perf.jmx
│
├─ stress/
│   ├─ checkout_stress.jmx
│
├─ endurance/
│   ├─ checkout_8h.jmx
│
├─ data/
│   └─ users.csv
│
└─ properties/
    ├─ qa.properties
    └─ perf.properties


📌 Naming define el tipo de test, no lógica en el .jmx.

6️⃣ Diferenciación por tipo de test
Cada pipeline aplica:

Duración

Thresholds

Ramp-up

SLAs

Ejemplo:

Tipo	Pipeline	Threshold
Performance	performance.yml	p95 < 2s
Stress	stress.yml	error < 5%
Endurance	endurance.yml	estabilidad
