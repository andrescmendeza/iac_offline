# IaC Offline

Infrastructure as Code (IaC) utilities designed for **offline / air-gapped environments**, focused on **performance testing platforms**, **JMeter distributed execution**, and **reproducible system hardening**.

This repository provides scripts, documentation, and architectural references to standardize infrastructure configuration where **internet access is not available** and **manual setup is error-prone**.

---

## 🚀 Purpose

In restricted or isolated environments, infrastructure configuration is often performed manually, leading to:

- Configuration drift
- Inconsistent environments
- Performance instability
- Difficult troubleshooting and audits

This repository addresses those problems by providing:

- **Offline-friendly IaC**
- **Repeatable hardening scripts**
- **Performance-safe JMeter configurations**
- **Clear operational documentation**

---

## 🎯 Key Use Cases

- Distributed **JMeter performance testing** (Master / Slave)
- **Air-gapped or restricted networks**
- Performance testing environments without external repositories
- CI/CD pipelines operating in isolated infrastructures
- Audit-ready and reproducible system setups

---

## 📦 What This Repository Provides

- OS, JVM and JMeter hardening scripts
- Deterministic Java memory configuration
- Safe result handling (no in-memory sample accumulation)
- Reference architecture and pipeline diagrams
- Documentation for operational consistency

---

## 📂 Repository Structure

```text
iac_offline/
├── doc/
│   └── technical_docs.md          # Technical and architectural documentation
│
├── pipelines_arch/
│   └── diagrams/                  # Pipeline and execution architecture diagrams
│
├── harden-master.sh               # JMeter MASTER hardening script
├── harden-slave.sh                # JMeter SLAVE hardening script
└── README.md                      # Project documentation
