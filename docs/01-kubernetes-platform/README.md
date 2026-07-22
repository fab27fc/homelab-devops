# Kubernetes Platform

## Overview

This project documents the Kubernetes platform built as part of my DevOps/SRE Homelab.

The cluster was built using kubeadm and containerd, with Calico providing networking and Helm managing application deployments.

The goal of this project is to understand how Kubernetes works from the infrastructure level to application deployment.

---

# Contents

## 1. Cluster Overview

High-level architecture of the Kubernetes platform.

- Cluster design
- Components
- Environment
- Project structure

➡ **01-cluster-overview.md**

---

## 2. Workloads

Kubernetes workloads created during the project.

- Pods
- ReplicaSets
- Deployments
- Services
- ConfigMaps
- Secrets
- Ingress
- Persistent Volumes

➡ **02-workloads.md**

---

## 3. Networking

Networking architecture.

- Calico
- CoreDNS
- Services
- Endpoints
- Ingress

➡ **03-networking.md**

---

## 4. Storage

Persistent storage implementation.

- Persistent Volumes
- Persistent Volume Claims
- Test Pod
- Prometheus storage

➡ **04-storage.md**

---

## 5. Helm

Deployment automation using Helm.

- Helm
- kube-prometheus-stack
- values.yaml
- upgrades
- rollbacks

➡ **05-helm.md**