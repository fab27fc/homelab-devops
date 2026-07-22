# Kubernetes Storage

## Overview

Persistent storage is required for applications that need to retain data beyond the lifecycle of a Pod.

This Kubernetes platform uses Persistent Volumes (PV) and Persistent Volume Claims (PVC) to provide persistent storage to workloads.

---

# Storage Architecture

```
Application
      │
      ▼
PersistentVolumeClaim
      │
      ▼
PersistentVolume
      │
      ▼
Host Storage
```

---

# Persistent Volumes

Persistent Volumes are cluster resources that provide storage independently of Pods.

Current manifests:

```
kubernetes/storage/persistent-volumes/

pv001.yaml

prometheus-pv.yaml
```

Validation:

```bash
kubectl get pv

kubectl describe pv
```

---

# Persistent Volume Claims

Applications request storage using Persistent Volume Claims.

Current manifest:

```
kubernetes/storage/persistent-volume-claims/pvc001.yaml
```

Validation:

```bash
kubectl get pvc -A

kubectl describe pvc pvc001 -n applications
```

---

# PVC Test Pod

A test Pod was created to verify that the PVC could be mounted correctly.

Manifest:

```
kubernetes/pods/pvc-test-pod.yaml
```

Validation:

```bash
kubectl get pod pvc-test-pod -n applications

kubectl describe pod pvc-test-pod -n applications
```

---

# Prometheus Storage

Prometheus stores time-series metrics on a Persistent Volume.

Manifest:

```
kubernetes/storage/persistent-volumes/prometheus-pv.yaml
```

This ensures that metrics remain available after Pod restarts.

Validation:

```bash
kubectl get pv

kubectl get pvc -A
```

---

# Useful Commands

```bash
kubectl get pv

kubectl get pvc

kubectl describe pv

kubectl describe pvc

kubectl get storageclass
```

---

# Lessons Learned

- Pods are ephemeral.
- Persistent Volumes exist independently of Pods.
- Persistent Volume Claims request storage resources.
- Applications consume storage through PVCs.
- Persistent storage protects application data from Pod recreation.