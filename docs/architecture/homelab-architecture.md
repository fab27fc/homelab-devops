# Homelab Architecture

## Overview

This homelab environment was designed to practice real-world technologies used in:

- DevOps Engineering
- Site Reliability Engineering (SRE)
- Cloud Architecture
- Kubernetes Administration
- Infrastructure as Code (IaC)
- Monitoring and Observability
- Network Security
- Automation

The environment simulates an enterprise infrastructure integrating:

- Firewall security
- Linux servers
- Windows infrastructure services
- Kubernetes workloads
- Monitoring platforms
- Cloud automation tools

---

# High Level Architecture

```text
                         Internet
                            |
                            |
                    ISP Router / Modem
                     192.168.100.1
                            |
                            |
                      FortiGate VM
                      10.10.10.1
                            |
                    LAN 10.10.10.0/24
                            |
 -----------------------------------------------------------------
 |                              |                                |
 |                              |                                |

10.10.10.10              10.10.10.20                    10.10.10.30

Windows Server           LAB-UBU-MGMT-01                LAB-RHEL-K8S-01

Active Directory         Terraform                      Kubernetes
DNS                      Ansible                        Containerd
Domain Services          AWS CLI                        Pods
                         Docker                         Calico CNI
                         kubectl                        Prometheus
                         Helm                           Grafana
                         Git                            Datadog
                                                        Splunk
                                                        ArgoCD
```

---

# Physical Infrastructure

## Windows Server

### Role

Enterprise Infrastructure Server


### IP Address

```text
10.10.10.10/24
```

### Purpose

The Windows Server simulates enterprise identity and infrastructure services commonly used in corporate environments.


### Installed Services

- Active Directory Domain Services
- DNS Server
- Domain Controller


### Responsibilities

- Centralized authentication
- User management
- DNS resolution
- Group Policy management
- Enterprise service simulation


---

# LAB-UBU-MGMT-01

## Role

DevOps Management Server


## IP Address

```text
10.10.10.20/24
```

## Purpose

Central administration server used to manage:

- Infrastructure automation
- Kubernetes administration
- Cloud resources
- Configuration management


## Installed Tools

### Version Control

- Git
- GitHub SSH Authentication


### Infrastructure as Code

- Terraform


### Configuration Management

- Ansible


### Cloud Tools

- AWS CLI


### Containers

- Docker


### Kubernetes Administration

- kubectl
- Helm


## Responsibilities

- Manage Infrastructure as Code deployments
- Execute Terraform deployments
- Execute Ansible playbooks
- Manage Kubernetes remotely
- Manage Git repositories
- Deploy cloud infrastructure


---

# LAB-RHEL-K8S-01

## Role

Kubernetes Platform Server


## IP Address

```text
10.10.10.30/24
```


## Purpose

Physical Red Hat Enterprise Linux server used as a Kubernetes platform for:

- Container orchestration
- Application deployment
- Monitoring
- Observability
- GitOps practices


---

# Kubernetes Components

## Kubernetes Core

Installed components:

- kubeadm
- kubelet
- kubectl
- Kubernetes Control Plane
- API Server
- Scheduler
- Controller Manager
- etcd
- containerd Container Runtime


---

# Kubernetes Networking

## CNI

Installed:

- Calico


Purpose:

- Pod networking
- Network policies
- Kubernetes traffic management


---

# Kubernetes Workloads

Supported workloads:

- Application Containers
- Pods
- Deployments
- Services
- ConfigMaps
- Secrets
- Persistent Volumes


---

# Monitoring and Observability Stack

## Prometheus

Purpose:

- Metrics collection
- Kubernetes monitoring
- Application metrics


## Grafana

Purpose:

- Dashboards
- Metrics visualization


## Datadog Agent

Purpose:

- Infrastructure monitoring
- Application monitoring
- Cloud observability


## Splunk Forwarder

Purpose:

- Log collection
- Log forwarding


---

# GitOps Platform

## ArgoCD

Purpose:

Continuous Delivery tool following GitOps practices.


Workflow:

```text
Developer
    |
    |
 GitHub Repository
    |
    |
 ArgoCD
    |
    |
 Kubernetes Cluster
```

Responsibilities:

- Monitor Git repositories
- Synchronize Kubernetes manifests
- Deploy applications automatically


---

# FortiGate Firewall

## Role

Network Security Gateway


## Interfaces

| Interface | Network | Purpose |
|---|---|---|
| WAN | 192.168.100.0/24 | Internet Access |
| LAN | 10.10.10.0/24 | Homelab Network |


## Functions

- Firewall policies
- NAT
- Routing
- Traffic filtering
- Network security


---

# Network Design

## Current Network

| Device | IP Address | Role |
|---|---|---|
| FortiGate LAN | 10.10.10.1 | Gateway |
| Windows Server | 10.10.10.10 | AD / DNS |
| LAB-UBU-MGMT-01 | 10.10.10.20 | DevOps Management |
| LAB-RHEL-K8S-01 | 10.10.10.30 | Kubernetes Platform |


## Subnet

```text
Network: 10.10.10.0/24

Gateway:
10.10.10.1

DNS:
10.10.10.10
```

---

# DevOps Workflow

```text
Developer
    |
    |
 GitHub
    |
    |
 Terraform / Ansible
    |
    |
 Infrastructure
    |
    |
 Kubernetes
    |
    |
 Monitoring Stack
```

---

# Future Improvements

Planned improvements:

- Add additional Kubernetes worker nodes
- Implement VLAN segmentation
- Add Jenkins CI/CD pipelines
- Deploy AWS workloads using Terraform
- Integrate AWS monitoring with Datadog
- Add automated backup solution
- Implement security scanning with Trivy
- Implement SonarQube code analysis


Future network segmentation:

| VLAN | Network | Purpose |
|---|---|---|
| VLAN10 | 10.10.10.0/24 | Management |
| VLAN20 | 10.10.20.0/24 | Kubernetes |
| VLAN30 | 10.10.30.0/24 | Monitoring |
| VLAN40 | 10.10.40.0/24 | DevOps |

---

# Repository

Project repository:

```text
github.com/fab27fc/homelab-devops
```
