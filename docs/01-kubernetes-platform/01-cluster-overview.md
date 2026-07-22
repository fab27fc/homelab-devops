# Kubernetes Platform

## Project Overview

This project documents the Kubernetes platform used in my personal DevOps/SRE Homelab.

The objective is to build a production-like Kubernetes environment where I can practice:

- Kubernetes administration
- Container orchestration
- Networking
- Storage
- Monitoring
- GitOps
- CI/CD
- Infrastructure as Code

The platform is completely self-hosted and serves as the foundation for the rest of the homelab projects.

---

# Environment

## Kubernetes Distribution

kubeadm

## Container Runtime

containerd

## CNI

Calico

## Package Manager

Helm

## Monitoring

Prometheus

Grafana

## GitOps

ArgoCD

---

# Current Architecture

```
                    Internet
                        │
                192.168.100.1
                        │
        ┌──────────────────────────────┐
        │                              │
 Windows Server                 Ubuntu Management
 Active Directory              Terraform
 DNS                           Ansible
 VMware                        Helm
                               kubectl
                               Git
                               AWS CLI
                        │
                        │
                 RHEL Kubernetes Node
                 kubeadm
                 containerd
                 Calico
                 Prometheus
                 Grafana
                 ArgoCD
```

---

# Current Status

- Kubernetes Cluster Installed
- Containerd Configured
- Calico Installed
- Helm Installed
- Prometheus Installed
- Grafana Installed
- ArgoCD Installed
- Sample Applications Deployed

---

# Project Structure

The Kubernetes manifests are organized by resource type.

```
kubernetes/

configmaps/
deployments/
ingress/
namespaces/
replicasets/
secrets-templates/
services/
storage/
```

---

# Next Steps

- Deploy production-like applications
- Implement GitOps workflows
- Improve monitoring dashboards
- Configure alerting
- Build CI/CD pipelines