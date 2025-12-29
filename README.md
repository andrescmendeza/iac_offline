# IAC Offline - JMeter Cluster Setup

Infrastructure as Code for setting up Apache JMeter distributed testing clusters in offline/air-gapped environments.

## Repository Structure

```
iac_offline/
│
├─ jmeter/                  # JMeter offline bundle
│   ├─ bin/                 # JMeter binary files
│   ├─ lib/                 # JMeter library files
│   └─ plugins/             # JMeter plugins
│
├─ java/                    # Java JDK archive
│   └─ jdk.tar.gz           # Java Development Kit (place here)
│
├─ config/                  # Configuration files
│   ├─ master/              # Master node configuration
│   │   └─ jmeter.properties
│   └─ slave/               # Slave node configuration
│       └─ jmeter.properties
│
├─ scripts/                 # Installation and setup scripts
│   ├─ install_java.sh      # Install Java JDK
│   ├─ install_jmeter.sh    # Install JMeter from bundle
│   ├─ configure_master.sh  # Configure master node
│   ├─ configure_slave.sh   # Configure slave node
│   ├─ start_slave.sh       # Start slave server
│   └─ validate_cluster.sh  # Validate cluster setup
│
└─ pipelines/               # CI/CD pipeline definitions
    └─ setup-jmeter.yml     # Azure DevOps pipeline
```

## Prerequisites

- Linux-based operating system (Ubuntu, RHEL, CentOS, etc.)
- sudo privileges
- Network connectivity between master and slave nodes
- JMeter offline bundle in `jmeter/` directory
- Java JDK archive in `java/` directory

## Quick Start

### Setting up a Master Node

1. Clone this repository to your master node
2. Ensure the offline bundles are in place:
   - Java JDK archive at `java/jdk.tar.gz`
   - JMeter files in `jmeter/bin/`, `jmeter/lib/`, and `jmeter/plugins/`
3. Run the installation scripts:

```bash
# Install Java
sudo bash scripts/install_java.sh

# Install JMeter
sudo bash scripts/install_jmeter.sh

# Configure as master node
bash scripts/configure_master.sh
```

### Setting up Slave Nodes

1. Clone this repository to each slave node
2. Ensure the offline bundles are in place
3. Run the installation scripts:

```bash
# Install Java
sudo bash scripts/install_java.sh

# Install JMeter
sudo bash scripts/install_jmeter.sh

# Configure as slave node
bash scripts/configure_slave.sh

# Start the slave server
bash scripts/start_slave.sh
```

### Validating the Cluster

Run the validation script on any node to check the setup:

```bash
bash scripts/validate_cluster.sh
```

## Configuration

### Master Node Configuration

The master node configuration (`config/master/jmeter.properties`) includes:
- Remote slave host definitions
- RMI settings
- Distributed testing parameters
- Logging configuration

Key settings:
- `remote_hosts`: Comma-separated list of slave IPs
- `server_port`: Default is 1099
- `server.rmi.localport`: Default is 4000

### Slave Node Configuration

The slave node configuration (`config/slave/jmeter.properties`) includes:
- Server settings
- RMI configuration
- Logging settings

## Running Distributed Tests

From the master node:

```bash
# Run a distributed test across all configured slaves
jmeter -n -t test_plan.jmx -r -l results.jtl

# Run on specific slaves
jmeter -n -t test_plan.jmx -R slave1,slave2 -l results.jtl
```

## Offline Bundle Preparation

### Java JDK
1. Download the Java JDK tar.gz archive
2. Place it in the `java/` directory as `jdk.tar.gz`

### JMeter Bundle
1. Download Apache JMeter
2. Extract and copy the contents:
   - Copy `bin/` directory contents to `jmeter/bin/`
   - Copy `lib/` directory contents to `jmeter/lib/`
   - Copy any plugins to `jmeter/plugins/`

## CI/CD Pipeline

An Azure DevOps pipeline is provided in `pipelines/setup-jmeter.yml` that automates:
- Bundle validation
- Master node setup
- Multiple slave node setup
- Cluster validation

## Troubleshooting

### Common Issues

1. **Cannot connect to slave nodes**
   - Verify network connectivity: `ping <slave-ip>`
   - Check firewall rules for port 1099 and 4000
   - Verify slave server is running: `ps aux | grep jmeter-server`

2. **Java not found**
   - Ensure `java/jdk.tar.gz` exists
   - Re-run `scripts/install_java.sh`
   - Source the profile: `source /etc/profile.d/java.sh`

3. **JMeter bundle incomplete**
   - Verify all required files are in `jmeter/bin/`, `jmeter/lib/`
   - Check JMeter scripts are executable: `chmod +x /opt/jmeter/bin/*.sh`

## Security Considerations

- RMI SSL is disabled by default for offline environments
- Consider enabling SSL for production deployments
- Ensure proper network segmentation between test and production networks
- Review and customize jmeter.properties for your security requirements

## License

This project is provided as-is for infrastructure automation purposes.

## Contributing

Feel free to submit issues and pull requests for improvements.