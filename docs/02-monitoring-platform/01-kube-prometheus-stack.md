# 01 — Helm and kube-prometheus-stack

## Why Helm

Installing Prometheus by hand would require manually writing
Deployments, Services, ConfigMaps, Secrets, ServiceAccounts,
ClusterRoles, ClusterRoleBindings, PVCs, and Ingress — dozens of YAML
files per application. Helm packages all of that into a **Chart** and
installs it with a single command, the same way `docker pull` downloads
an image from Docker Hub.

```
Helm Client
   │
   ▼
Helm Repository
   │
   ▼
Download Chart
   │
   ▼
Kubernetes API Server
   │
   ▼
Creates the Kubernetes resources
```

Helm **does not run** applications; it only creates Kubernetes objects.
After that, the normal flow continues: `Deployment → ReplicaSet → Pods`.

### Terminology

- **Repository**: like Docker Hub (e.g. `prometheus-community`,
  `bitnami`).
- **Chart**: the package (e.g. `kube-prometheus-stack`).
- **Release**: a running installation of a Chart.

## Verifying Helm

```bash
helm version
helm env
helm repo list
helm repo update
helm search repo prometheus
```

## Choosing the right chart

| Chart | Contains |
|---|---|
| `prometheus-community/prometheus` | Prometheus only. |
| `prometheus-community/kube-prometheus-stack` | Prometheus + Alertmanager + Grafana + Node Exporter + kube-state-metrics + Prometheus Operator + CRDs. |

For an enterprise-style platform, `kube-prometheus-stack` is used.

## Standard workflow for every Helm application

1. Find the official chart.
2. Download the default `values.yaml`.
3. Store it in the Git repository.
4. Customize only what's needed.
5. Install/upgrade using the customized values file.

## Installation

```bash
cd ~/Homelabs/enterprise_kubernetes_platform/kubernetes/helm
mkdir -p prometheus
cd prometheus

# Download the chart's default configuration
helm show values prometheus-community/kube-prometheus-stack > values.yaml
```

### `custom-values.yaml`

Overrides file used to customize the installation (Grafana password,
service type, Prometheus storage):

```yaml
grafana:
  adminPassword: admin123
  service:
    type: NodePort

prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: prometheus-local
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 10Gi
```

> ⚠️ The correct configuration path can change between chart versions.
> Before assuming a value took effect, verify it with `helm get values`
> (see [07-troubleshooting.md](07-troubleshooting.md)).

## Persistent storage for Prometheus

Since the cluster had no dynamic `StorageClass`, a manual
`PersistentVolume` backed by a directory on the RHEL node was created.

```bash
sudo mkdir -p /data/kubernetes/prometheus
```

`prometheus-pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: prometheus-local
  hostPath:
    path: /data/kubernetes/prometheus
```

```bash
kubectl apply -f prometheus-pv.yaml
kubectl get pv
```

## Installing / upgrading the release

```bash
# Preview only (no changes applied)
helm upgrade monitoring \
  prometheus-community/kube-prometheus-stack \
  -n default \
  -f custom-values.yaml \
  --dry-run

# Apply
helm upgrade monitoring \
  prometheus-community/kube-prometheus-stack \
  -n default \
  -f custom-values.yaml
```

## Verifying the installation

```bash
kubectl get pods -n default
kubectl get svc -n default
kubectl get deployments -n default
kubectl get statefulsets -n default
kubectl get pvc -A
kubectl get pv
```

Expected result:

- Pods: Alertmanager, Grafana, Prometheus Operator, kube-state-metrics,
  node-exporter, and Prometheus → `Running`.
- Prometheus PVC → `Bound`.
- `prometheus-pv` → `Bound`.
- `monitoring-grafana` service → `NodePort`.

## 📸 Suggested screenshots

- `images/helm-repo-list.png` — output of `helm repo list` and
  `helm search repo prometheus`.
- `images/kubectl-get-pods-monitoring.png` — all stack Pods in
  `Running`.
- `images/pv-pvc-bound.png` — output of `kubectl get pvc -A` and
  `kubectl get pv` showing `Bound`.
