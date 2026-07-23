# 📊 Phase 2 — Monitoring Platform (Prometheus + Grafana)

This folder documents the installation and configuration of the
monitoring stack for the Kubernetes homelab, using **Helm** to deploy
`kube-prometheus-stack` (Prometheus + Grafana + Alertmanager + Node
Exporter + kube-state-metrics).

## Contents

| File | Description |
|---|---|
| [01-kube-prometheus-stack.md](01-kube-prometheus-stack.md) | Installing Helm and the `kube-prometheus-stack` chart, persistent storage, and `helm upgrade`. |
| [02-prometheus.md](02-prometheus.md) | Accessing the Prometheus UI, Targets, and the `up` metric. |
| [03-grafana.md](03-grafana.md) | Accessing Grafana, credentials, and exposing the service. |
| [04-promql.md](04-promql.md) | Introduction to PromQL with the queries used. |
| [05-grafana-dashboards.md](05-grafana-dashboards.md) | Building the "Enterprise Kubernetes Platform" dashboard, panel by panel. |
| [06-alertmanager.md](06-alertmanager.md) | Alerting with Alertmanager (still to be built). |
| [07-troubleshooting.md](07-troubleshooting.md) | Errors encountered during the lab and how they were fixed. |

## General architecture

```
RHEL Kubernetes Node
  ├── Node Exporter
  ├── kube-state-metrics
  ├── Prometheus Operator
  ├── Prometheus (+ persistent storage)
  ├── Alertmanager
  └── Grafana
        │
        ▼
192.168.100.20:31441
```

## Prerequisites

- A working Kubernetes cluster (homelab foundation already completed:
  Pods, Deployments, Services, Ingress, PVCs, ConfigMaps, Secrets).
- Helm v3 installed.
- `kubectl` access to the cluster.

## Screenshots

All screenshots for this module live in `images/`, using lowercase,
hyphen-separated, descriptive file names, for example:

```
images/
  helm-repo-list.png
  prometheus-targets.png
  grafana-namespace-overview.png
  prometheus-graph-namespaces.png
```

Reference them from any `.md` file like this:

```markdown
![Image description](images/file-name.png)
```
