# Homelab Architecture

## Overview

This homelab is designed to practice:

- DevOps Engineering
- Site Reliability Engineering (SRE)
- Cloud Architecture
- Kubernetes Administration
- Infrastructure as Code (IaC)
- Monitoring and Observability
- Network Security

---

# Physical Infrastructure

## LAB-UBU-MGMT-01

Role:

DevOps Management Server

IP Address:

10.10.10.20/24

Purpose:

Central server used to manage automation, infrastructure deployments and Kubernetes administration.

Tools:

- Git
- Terraform
- Ansible
- AWS CLI
- Docker
- kubectl
- Helm

Responsibilities:

- Execute Terraform deployments
- Run Ansible playbooks
- Manage Kubernetes clusters
- Manage Git repositories
- Deploy applications


---

## LAB-RHEL-K8S-01

Role:

Kubernetes Server

IP Address:

10.10.10.30/24

Purpose:

Physical Linux server used to run Kubernetes workloads.

Components:

- containerd
- kubelet
- kubeadm
- kubectl
- Kubernetes Control Plane

Future workloads:

- Application containers
- Prometheus
- Grafana
- Datadog Agent
- Splunk Forwarder


---

## Windows Server

Role:

Enterprise Services Server

IP Address:

10.10.10.10/24

Purpose:

Simulate enterprise infrastructure services.

Components:

- Active Directory Domain Services
- DNS Server
- User Management
- Group Policies


---

## FortiGate Firewall

Role:

Network Security Gateway

Purpose:

Provide network security, firewall policies and internet access.

Functions:

- Firewall policies
- NAT
- Routing
- Traffic inspection

Interfaces:

| Interface | Network |
|---|---|
| LAN | 10.10.10.0/24 |
| WAN | 192.168.100.0/24 |


---

# Network Design

Current network implementation:

| Device | IP Address | Purpose |
|---|---|---|
| Windows Server | 10.10.10.10 | AD / DNS |
| LAB-UBU-MGMT-01 | 10.10.10.20 | DevOps Management |
| LAB-RHEL-K8S-01 | 10.10.10.30 | Kubernetes |
| FortiGate LAN | 10.10.10.1 | Gateway |


Network:

```text
Internet
   |
ISP Router
192.168.100.1
   |
FortiGate
10.10.10.1
   |
LAN Network
10.10.10.0/24
   |
   +---- Windows Server
   |
   +---- Ubuntu Management
   |
   +---- Red Hat Kubernetes
