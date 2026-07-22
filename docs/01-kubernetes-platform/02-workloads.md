# Kubernetes Workloads

## Overview

This document describes the Kubernetes resources created and tested as part of the homelab.

The objective was to understand how Kubernetes deploys applications, maintains the desired state, exposes workloads through networking, and provides configuration and persistent storage.

The resources are stored in the main `kubernetes/` directory of this repository.

---

## Namespace

The application resources are deployed in the following namespace:

```text
applications
```

Using a dedicated namespace keeps application workloads separated from Kubernetes system components.

### Validation

```bash
kubectl get namespace applications
```

---

## ConfigMap

A ConfigMap is used to store non-sensitive application configuration.

Manifest:

```text
kubernetes/configmaps/app-config.yaml
```

### Apply the ConfigMap

```bash
kubectl apply -f kubernetes/configmaps/app-config.yaml
```

### Validate

```bash
kubectl get configmap -n applications
kubectl describe configmap app-config -n applications
```

---

## Secret Template

A Kubernetes Secret is used for sensitive data such as usernames and passwords.

The repository contains only a safe example template:

```text
kubernetes/secrets-templates/database-secret.example.yaml
```

Real credentials are not committed to Git.

### Example creation

```bash
kubectl create secret generic database-secret \
  --from-literal=username=CHANGE_ME \
  --from-literal=password=CHANGE_ME \
  -n applications
```

### Validate

```bash
kubectl get secrets -n applications
```

---

## Pods

The following standalone Pods were created for learning and validation:

```text
kubernetes/pods/nginx-pod.yaml
kubernetes/pods/configmap-pod.yaml
kubernetes/pods/config-secret-pod.yaml
kubernetes/pods/pvc-test-pod.yaml
```

Standalone Pods were useful for understanding the basic Kubernetes execution unit.

In production-like environments, applications should normally be managed by higher-level controllers such as Deployments.

### Apply a Pod

```bash
kubectl apply -f kubernetes/pods/nginx-pod.yaml
```

### Validate

```bash
kubectl get pods -n applications -o wide
kubectl describe pod nginx-pod -n applications
kubectl logs nginx-pod -n applications
```

---

## ReplicaSet

The ReplicaSet maintains the requested number of identical Pods.

Manifest:

```text
kubernetes/replicasets/nginx-rs.yaml
```

### Apply

```bash
kubectl apply -f kubernetes/replicasets/nginx-rs.yaml
```

### Validate

```bash
kubectl get replicasets -n applications
kubectl get pods -n applications
kubectl describe replicaset nginx-rs -n applications
```

The ReplicaSet recreates a Pod when one of its managed Pods is deleted.

---

## Deployment

The NGINX application is managed through a Deployment.

Manifest:

```text
kubernetes/deployments/nginx-deployment.yaml
```

A Deployment provides:

- Replica management
- Rolling updates
- Rollback support
- Self-healing
- Declarative application updates

### Apply

```bash
kubectl apply -f kubernetes/deployments/nginx-deployment.yaml
```

### Validate

```bash
kubectl get deployments -n applications
kubectl get replicasets -n applications
kubectl get pods -n applications -o wide
kubectl rollout status deployment/nginx-deployment -n applications
```

### View rollout history

```bash
kubectl rollout history deployment/nginx-deployment -n applications
```

### Roll back

```bash
kubectl rollout undo deployment/nginx-deployment -n applications
```

---

## Service

A Kubernetes Service provides a stable network endpoint for the NGINX Pods.

Manifest:

```text
kubernetes/services/nginx-service.yaml
```

The Service uses a label selector to send traffic to the Pods managed by the Deployment.

### Apply

```bash
kubectl apply -f kubernetes/services/nginx-service.yaml
```

### Validate

```bash
kubectl get services -n applications
kubectl describe service nginx-service -n applications
kubectl get endpoints -n applications
kubectl get endpointslices -n applications
```

### Test

```bash
curl http://<NODE-IP>:<NODEPORT>
```

---

## Ingress

The NGINX application is also exposed through the NGINX Ingress Controller.

Manifest:

```text
kubernetes/ingress/nginx-ingress.yaml
```

The Ingress resource routes traffic from:

```text
nginx.lab.local
```

to:

```text
nginx-service
```

### Apply

```bash
kubectl apply -f kubernetes/ingress/nginx-ingress.yaml
```

### Validate

```bash
kubectl get ingress -n applications
kubectl describe ingress nginx-ingress -n applications
```

### Local name resolution

Example `/etc/hosts` entry:

```text
192.168.100.20 nginx.lab.local
```

### Test

```bash
curl http://nginx.lab.local
```

---

## Persistent Storage

The application environment includes Persistent Volumes and Persistent Volume Claims.

Manifests:

```text
kubernetes/storage/persistent-volumes/pv001.yaml
kubernetes/storage/persistent-volumes/prometheus-pv.yaml
kubernetes/storage/persistent-volume-claims/pvc001.yaml
```

The test Pod verifies that the PersistentVolumeClaim can be mounted successfully.

### Validate

```bash
kubectl get pv
kubectl get pvc -A
kubectl describe pvc pvc001 -n applications
```

---

## Current Validation Commands

```bash
kubectl get all -n applications
kubectl get configmaps -n applications
kubectl get secrets -n applications
kubectl get ingress -n applications
kubectl get pv
kubectl get pvc -A
kubectl get endpointslices -n applications
```

---

## Key Lessons Learned

- Pods are temporary and should normally be managed by controllers.
- ReplicaSets maintain a desired number of Pods.
- Deployments manage ReplicaSets and application updates.
- Services provide stable access to dynamic Pods.
- Ingress provides HTTP routing to Services.
- ConfigMaps store non-sensitive configuration.
- Secrets store sensitive values.
- Persistent Volumes preserve data beyond the lifetime of a Pod.
- Labels and selectors connect Kubernetes resources.