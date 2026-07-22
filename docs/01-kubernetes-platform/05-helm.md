# Helm

## Overview

Helm is the package manager for Kubernetes.

Instead of deploying dozens of YAML manifests manually, Helm packages Kubernetes resources into reusable Charts that can be installed, upgraded, rolled back, and configured using values files.

The monitoring platform in this homelab is deployed using the kube-prometheus-stack Helm Chart.

---

# Helm Installation

Verify Helm installation:

```bash
helm version
```

Verify configured repositories:

```bash
helm repo list
```

Update repositories:

```bash
helm repo update
```

---

# kube-prometheus-stack

The monitoring platform is based on the official Prometheus Community Chart.

Repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Install:

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
-n monitoring \
--create-namespace \
-f monitoring/prometheus/helm/custom-values.yaml
```

---

# Helm Values

The repository contains three values files.

## values.yaml

Original default values from the Helm Chart.

```
monitoring/prometheus/helm/values.yaml
```

---

## custom-values.yaml

Custom configuration created specifically for this homelab.

Examples include:

- Grafana configuration
- Persistent Volumes
- Prometheus storage
- Service configuration
- Dashboard settings

Location:

```
monitoring/prometheus/helm/custom-values.yaml
```

---

## running-values.yaml

Current configuration exported from the running release.

Generated with:

```bash
helm get values monitoring \
-n monitoring \
-a \
> running-values.yaml
```

Location:

```
monitoring/prometheus/helm/running-values.yaml
```

---

# Helm Release

Current release:

```bash
helm list -A
```

Detailed information:

```bash
helm status monitoring -n monitoring
```

---

# Upgrading the Chart

Upgrade using the custom values file.

```bash
helm upgrade monitoring \
prometheus-community/kube-prometheus-stack \
-n monitoring \
-f monitoring/prometheus/helm/custom-values.yaml
```

---

# Rollback

View release history:

```bash
helm history monitoring -n monitoring
```

Rollback:

```bash
helm rollback monitoring REVISION -n monitoring
```

---

# Validation Commands

```bash
helm version

helm repo list

helm list -A

helm status monitoring -n monitoring

helm history monitoring -n monitoring

kubectl get pods -n monitoring

kubectl get svc -n monitoring
```

---

# Lessons Learned

- Helm simplifies Kubernetes application deployment.
- Charts package multiple Kubernetes resources together.
- Values files customize deployments without editing templates.
- Helm upgrades preserve release history.
- Rollbacks make recovering from failed upgrades simple.
- Helm improves repeatability and consistency across environments.