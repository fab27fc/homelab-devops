# Lesson 9 — Helm & the kube-prometheus-stack

## Objective

Move from hand-writing YAML to Helm — the way real infrastructure deploys
complex applications — and install a full monitoring stack
(Prometheus + Grafana + Alertmanager + Node Exporter + kube-state-metrics)
with persistent storage.

## Why Helm

Installing Prometheus by hand means writing Deployments, Services,
ConfigMaps, Secrets, ServiceAccounts, ClusterRoles, ClusterRoleBindings,
PVCs, Ingress — 30-50+ manifests for one application. Grafana and ArgoCD
add dozens more each. That's impractical to maintain by hand.

```
Docker            Helm
docker pull  ⇄   helm install
Docker Hub   ⇄   Helm Repository
```

A **Chart** is a packaged collection of Kubernetes manifests + templating.
A **Release** is a running installation of a Chart.

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
Creates Deployments / Services / ConfigMaps / Secrets / PVCs / RBAC / ...
```

Helm never runs your application — it only creates the same Kubernetes
objects you'd otherwise write by hand. Everything downstream (ReplicaSets,
Pods, self-healing, rolling updates) works exactly as in earlier lessons.

## Verify Helm

```bash
helm version
helm env
helm repo list
helm repo update
helm search repo prometheus
```

## `prometheus` chart vs. `kube-prometheus-stack`

| Chart | Installs |
|---|---|
| `prometheus-community/prometheus` | Prometheus only |
| `prometheus-community/kube-prometheus-stack` | Prometheus + Alertmanager + Grafana + Node Exporter + kube-state-metrics + Prometheus Operator + CRDs |

For an "enterprise platform" rather than a bare lab, we use
`kube-prometheus-stack` — a single release that gives you the whole
observability stack.

## Step 1 — inspect the chart before installing

Production practice: never `helm install` with silent defaults. Download
the chart's default `values.yaml`, review it, and only override what's
needed, so overrides are version-controlled in git and reusable with
`-f values.yaml` (this is also what makes the chart compatible with a
future GitOps workflow).

```bash
cd ~/enterprise-kubernetes-platform/manifests/helm/prometheus
helm show values prometheus-community/kube-prometheus-stack > values.yaml
less values.yaml   # thousands of lines — skim, don't edit wholesale
```

## Step 2 — write the override file

Our overrides live in
[`monitoring/prometheus/helm/custom-values.yaml`](../monitoring/prometheus/helm/custom-values.yaml):

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

## Step 3 — install

```bash
helm install monitoring \
  prometheus-community/kube-prometheus-stack \
  -n default \
  -f custom-values.yaml
```

Verify:

```bash
kubectl get pods -n default
kubectl get svc -n default
kubectl get deployments -n default
kubectl get statefulsets -n default
kubectl get pvc -n default
```

Expected Pods (all `Running`): Alertmanager, Grafana, Prometheus Operator,
kube-state-metrics, node-exporter, Prometheus.

---

## 🔧 Troubleshooting log (real issues hit during this install)

Documenting these because diagnosing them is the actual skill — not the
`helm install` itself.

### Issue 1 — a trailing `.` created a wrong filename

```bash
helm get values monitoring --all > running-values.yaml.
#                                                      ^ stray period
```

This silently created a file literally named `running-values.yaml.`, so
`grep -n "grafana:" running-values.yaml` failed with "No such file or
directory" even though the export had actually worked.

**Fix:**

```bash
ls -l *.yaml*                       # confirm exact filenames first
mv running-values.yaml. running-values.yaml
# or just re-run the export command without the trailing period
```

**Lesson:** when a file that should exist doesn't, `ls -l` before assuming
the command failed — shells don't warn about stray characters in
redirection targets.

### Issue 2 — overrides silently didn't apply

After the first install, `custom-values.yaml` used an outdated key path
(`prometheus.prometheusSpec` at the wrong nesting for that chart version),
so:

- Grafana's Service stayed `ClusterIP` instead of `NodePort`.
- Prometheus's `storageSpec: {}` was empty → Prometheus was writing to an
  `EmptyDir`, not a PVC.

**How this was diagnosed** — always verify what Helm *actually* applied,
not what you think you wrote:

```bash
helm get values monitoring --all > running-values.yaml
grep -n "grafana:" running-values.yaml
grep -n "storageSpec" running-values.yaml
```

**Lesson:** Helm chart value schemas change between versions. Always
verify the effective config with `helm get values <release> --all` after
installing/upgrading — a value that silently doesn't match the chart's
expected path fails **without any error**, it just gets ignored.

### Issue 3 — PVC stuck `Pending` (no default StorageClass)

The cluster had no default `StorageClass`, and the only existing PV
(`pv001`, 5Gi) was already bound to a different PVC from
[`06-persistent-volumes.md`](06-persistent-volumes.md). A new 10Gi request
had nothing to bind to.

**Fix:** create a dedicated PV for Prometheus with a matching
`storageClassName`, on the RHEL node:

```bash
sudo mkdir -p /data/kubernetes/prometheus
sudo ls -ld /data/kubernetes/prometheus
```

[`kubernetes/storage/persistent-volumes/prometheus-pv.yaml`](../kubernetes/storage/persistent-volumes/prometheus-pv.yaml):

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
# prometheus-pv   10Gi   RWO   Retain   Available
```

`custom-values.yaml`'s `storageClassName: prometheus-local` ties the
Prometheus PVC to exactly this PV.

### Issue 4 — upgrade, always preview first

```bash
helm upgrade monitoring \
  prometheus-community/kube-prometheus-stack \
  -n default \
  -f custom-values.yaml \
  --dry-run

# no errors → apply for real
helm upgrade monitoring \
  prometheus-community/kube-prometheus-stack \
  -n default \
  -f custom-values.yaml

kubectl get pods -n default -w
```

### Issue 5 — `CrashLoopBackOff`: `permission denied`

Once the PVC bound, the Pod scheduled but crashed:

```bash
kubectl describe pod prometheus-monitoring-kube-prometheus-prometheus-0 -n default
kubectl get pod prometheus-monitoring-kube-prometheus-prometheus-0 \
  -n default -o jsonpath="{.spec.containers[*].name}"
kubectl logs prometheus-monitoring-kube-prometheus-prometheus-0 \
  -n default -c prometheus
```

Log output:

```
open /prometheus/queries.active: permission denied
```

**Root cause:** the `hostPath` directory (`/data/kubernetes/prometheus`)
was created as `root:root` with default permissions, but the Prometheus
container runs as a non-root user (UID 1000 / GID 2000 per its
`securityContext`):

```bash
kubectl get pod prometheus-monitoring-kube-prometheus-prometheus-0 \
  -n default -o jsonpath='{.spec.securityContext}{"\n"}'
```

```
Prometheus UID 1000
      │
      ▼
/data/kubernetes/prometheus   (owner root:root, mode 755)
      │
      ▼
Permission denied
```

**Fix**, on the RHEL node:

```bash
sudo chown -R 1000:2000 /data/kubernetes/prometheus
sudo chmod -R 775 /data/kubernetes/prometheus
sudo ls -ld /data/kubernetes/prometheus

getenforce
# if Enforcing (SELinux):
sudo chcon -Rt container_file_t /data/kubernetes/prometheus
```

Restart just the Pod (the StatefulSet recreates it):

```bash
kubectl delete pod prometheus-monitoring-kube-prometheus-prometheus-0 -n default
kubectl get pods -n default -w
kubectl logs prometheus-monitoring-kube-prometheus-prometheus-0 \
  -n default -c prometheus --tail=50
```

Result: `2/2 Running`, no more permission errors.

```
After the fix:
Prometheus UID 1000
      │
      ▼
/data/kubernetes/prometheus  (owner 1000:2000, mode 775)
      │
      ▼
Write allowed
```

---

## Final verification

```bash
kubectl get pods -n default
kubectl get pvc -A
kubectl get pv
kubectl get svc monitoring-grafana -n default
```

Expected:

```
Prometheus Pod:   2/2 Running
Prometheus PVC:   Bound
prometheus-pv:    Bound
Grafana Service:  NodePort  (e.g. 31441)
```

## Access Grafana

```bash
# admin password (falls back to a generated one if the override didn't
# apply — always verify against the live Secret rather than assuming)
kubectl get secret monitoring-grafana \
  -n default \
  -o jsonpath='{.data.admin-password}' \
  | base64 --decode
echo

# confirm the NodePort
kubectl get svc monitoring-grafana -n default

# from Ubuntu Management
curl http://192.168.100.20:<nodeport>

# quick in-cluster check
kubectl run grafana-test \
  --rm -it --restart=Never \
  --image=curlimages/curl \
  -n default \
  -- curl -I http://monitoring-grafana
# expect: HTTP/1.1 302 Found (redirect to login — this is normal)
```

Open `http://192.168.100.20:<nodeport>` in a browser, log in with
`admin` / the password above. `kube-prometheus-stack` auto-provisions
Prometheus as a Grafana data source and ships a set of default dashboards
(Kubernetes / Compute Resources, Kubernetes / Networking, Kubernetes / API
Server, Node Exporter, Prometheus) — no manual data-source setup needed.

```
RHEL Kubernetes Node
        │
        ├── Node Exporter
        ├── kube-state-metrics
        ├── Prometheus Operator
        ├── Prometheus (+ persistent storage)
        ├── Alertmanager
        └── Grafana
                  │
                  ▼
       192.168.100.20:<nodeport>
```

## Screenshots needed

- [ ] `docs/images/kubernetes/09-helm-repo-search.png` — `helm version`,
      `helm repo list`, `helm search repo prometheus`.
- [ ] `docs/images/kubernetes/09-monitoring-pods-running.png` — `kubectl get pods -n
      default` with every `monitoring-*` Pod `Running`.
- [ ] `docs/images/kubernetes/09-permission-denied-log.png` — the `permission denied`
      log line, captured *before* the `chown`/`chmod` fix (for the
      troubleshooting writeup).
- [ ] `docs/images/kubernetes/09-storage-fixed.png` — `kubectl get pvc -A` /
      `kubectl get pv` / `kubectl get svc monitoring-grafana` all healthy
      after the fix.
- [ ] `docs/images/kubernetes/09-grafana-login.png` — the Grafana login page loading
      at the NodePort URL.

## Workflow going forward

Every future Helm-based install in this repo follows the same steps:

1. Search for the official chart.
2. `helm show values <chart> > values.yaml`, review it.
3. Write a minimal `custom-values.yaml` override, commit it to git.
4. `helm install`/`helm upgrade -f custom-values.yaml`.
5. Verify with `helm get values <release> --all` — never assume an
   override applied.
6. Validate the actual Kubernetes resources created (Pods, Services, PVCs).

Next: [`10-promql-and-dashboards.md`](10-promql-and-dashboards.md) — using
Prometheus/Grafana, not just installing them.
