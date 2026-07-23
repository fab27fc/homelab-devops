# 07 — Troubleshooting

Log of real issues found while installing the monitoring stack, their
cause, and the fix applied.

---

## 1. `bash: syntax error near unexpected token 'newline'`

**Failing command:**

```bash
helm status monitoring -n <namespace>
```

**Cause:** `<namespace>` was a placeholder in the explanation, not a
literal value. Bash interpreted `<` as input redirection.

**Fix:** replace `<namespace>` with the real name, e.g. `default`.

---

## 2. Grafana still `ClusterIP` after installing

**Symptom:** `kubectl get svc monitoring-grafana -n default` showed
`ClusterIP` instead of `NodePort`, even though `custom-values.yaml`
had:

```yaml
grafana:
  service:
    type: NodePort
```

**Possible causes:**
1. `custom-values.yaml` wasn't actually used in the original install.
2. Incorrect YAML indentation.
3. The release was installed before the custom file existed.

**Fix:** verify the values actually applied and run `helm upgrade`
with the corrected file:

```bash
helm get values monitoring
helm get values monitoring --all > running-values.yaml
grep -n "grafana:" running-values.yaml
grep -n "storageSpec" running-values.yaml
```

---

## 3. File created with an extra trailing dot in the name

**Command:**

```bash
helm get values monitoring --all > running-values.yaml.
```

**Cause:** an extra period at the end of the command created a file
literally named `running-values.yaml.` (with a dot), so
`grep ... running-values.yaml` failed with `No such file or
directory`.

**Fix:**

```bash
mv running-values.yaml. running-values.yaml
# or simpler, regenerate it without the dot:
rm running-values.yaml.
helm get values monitoring --all > running-values.yaml
```

---

## 4. `storageSpec: {}` — Prometheus storage wasn't applied

**Cause:** the configuration path used
(`prometheus.prometheusSpec...`) didn't match the actual structure of
that version of the `kube-prometheus-stack` chart (chart structures
change between versions).

**Fix:** check `helm get values monitoring --all` for the correct path
before assuming an override took effect, and fix `custom-values.yaml`
accordingly.

---

## 5. Prometheus PVC stuck in `Pending`

**Cause:** the cluster had no dynamic `StorageClass`, and the existing
manual PV (`pv001`, 5Gi) didn't match what was requested (10Gi).

**Fix:** create a dedicated `PersistentVolume` (`prometheus-pv`,
`storageClassName: prometheus-local`) that exactly matched what
`custom-values.yaml` requested, then run `helm upgrade` again.

---

## 6. Prometheus `CrashLoopBackOff`: `permission denied`

**Log:**

```
open /prometheus/queries.active: permission denied
```

**Cause:** the `hostPath` volume (`/data/kubernetes/prometheus`) was
created as `root:root`, but the Prometheus container runs as an
unprivileged user (`runAsUser: 1000`, `fsGroup: 2000`).

**Fix:**

```bash
sudo chown -R 1000:2000 /data/kubernetes/prometheus
sudo chmod -R 775 /data/kubernetes/prometheus

# If SELinux is Enforcing:
sudo chcon -Rt container_file_t /data/kubernetes/prometheus

# Restart just the Pod (the StatefulSet recreates it):
kubectl delete pod prometheus-monitoring-kube-prometheus-prometheus-0 -n default
```

---

## 7. Grafana panels showing `No data`

**Example:**

```promql
count(kube_pod_status_phase{phase="Pending"} == 1)
```

**Cause:** when no series matches the condition, Prometheus returns an
empty result and Grafana shows it as `No data`, even though the real
value is `0`.

**Fix:** append `or vector(0)`:

```promql
count(kube_pod_status_phase{phase="Pending"} == 1) or vector(0)
```

---

## 8. "PVC Usage %" panel with no data

**Affected queries:**

```promql
kubelet_volume_stats_used_bytes
kubelet_volume_stats_capacity_bytes
```

**Cause:** kubelet on this cluster doesn't expose those volume metrics
(depends on the kubelet/cAdvisor configuration and version).

**Fix:** confirmed by running both queries directly in Prometheus
(both returned `No data`) and dropped the panel for now, documenting
it as a known limitation.

## 📸 Suggested screenshots

- `images/error-permission-denied-logs.png` — container logs showing
  `permission denied`.
- `images/prometheus-no-data-example.png` — example of a query
  returning `No data` in Prometheus (namespaces with no data in the
  selected time range).