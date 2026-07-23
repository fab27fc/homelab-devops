# 05 — "Enterprise Kubernetes Platform" Dashboard

## Design principles

A good dashboard isn't the one with the most graphs — it's the one that
quickly answers: **is my cluster healthy?**

Recommended order (top to bottom):

1. **Overall health** of the cluster (targets, nodes, pods, restarts).
2. **Resource usage** (CPU, memory, disk, network).
3. **Diagnostic detail** (top pods, events, alerts) — only checked once
   a problem has been spotted above.

```
┌─────────────────────────────────────────────────────────┐
│ Targets │ Nodes │ Running │ Pending │ Failed │ Restarts │
├─────────────────────────────────────────────────────────┤
│ CPU │ Memory │ Disk │ Network RX │ Network TX │ PVC     │
├─────────────────────────────────────────────────────────┤
│ Top CPU Pods              │ Top Memory Pods             │
├─────────────────────────────────────────────────────────┤
│ Top Restarting Pods       │ CrashLoop │ Alerts          │
└─────────────────────────────────────────────────────────┘
```

## Panels

### Row 1 — Overall health

| Panel | Visualization | Query |
|---|---|---|
| Prometheus Targets Up | Stat | `count(up == 1)` |
| Running Pods | Stat | `count(kube_pod_status_phase{phase="Running"} == 1)` |
| Pending Pods | Stat | `count(kube_pod_status_phase{phase="Pending"} == 1) or vector(0)` |
| Failed Pods | Stat | `count(kube_pod_status_phase{phase="Failed"} == 1) or vector(0)` |
| Unknown Pods | Stat | `count(kube_pod_status_phase{phase="Unknown"} == 1) or vector(0)` |
| Succeeded Pods | Stat | `count(kube_pod_status_phase{phase="Succeeded"} == 1) or vector(0)` |
| Total Nodes | Stat | `count(kube_node_info)` |
| Pod Restarts (total) | Stat | `sum(kube_pod_container_status_restarts_total)` |
| CrashLoopBackOff Pods | Stat | `count(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} == 1) or vector(0)` |

### Row 2 — Node resources

| Panel | Visualization | Query |
|---|---|---|
| Node CPU Usage % | Stat/Gauge, unit `Percent (0-100)` | `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| Node Memory Usage % | Stat/Gauge, unit `Percent (0-100)` | `100 * (1 - (node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))` |
| Disk Usage % | Stat/Gauge, unit `Percent (0-100)` | `100 * (1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}/node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}))` |
| Network Receive (MB/s) | Stat, unit `Data rate → MiB/s` | `sum(rate(node_network_receive_bytes_total{device!~"lo|veth.*|cali.*"}[5m])) / 1024 / 1024` |
| Network Transmit (MB/s) | Stat, unit `Data rate → MiB/s` | `sum(rate(node_network_transmit_bytes_total{device!~"lo|veth.*|cali.*"}[5m])) / 1024 / 1024` |
| Cluster CPU Usage % | Gauge, unit `Percent (0-100)` | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |

Suggested thresholds for CPU/memory/disk:
🟢 Green &lt; 70% · 🟡 Yellow ≥ 70% · 🔴 Red ≥ 90%.

> ℹ️ **PVC Usage %** (`kubelet_volume_stats_used_bytes /
> kubelet_volume_stats_capacity_bytes`) didn't work on this cluster
> because kubelet doesn't expose those metrics — see
> [07-troubleshooting.md](07-troubleshooting.md). It was left out of
> the dashboard.

### Row 3 — Applications (tables)

| Panel | Visualization | Query |
|---|---|---|
| Top CPU Pods | Table | `topk(10, sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{container!="",container!="POD",pod!=""}[5m])))` |
| Top Memory Pods | Table, unit `Bytes (IEC)` | `topk(10, sum by (namespace, pod) (container_memory_working_set_bytes{container!="",container!="POD",pod!=""}))` |
| Top Restarting Pods | Table | `topk(10, kube_pod_container_status_restarts_total)` |

### Row 4 — Infrastructure

| Panel | Visualization | Query |
|---|---|---|
| Active Alerts | Stat | `count(ALERTS{alertstate="firing"}) or vector(0)` |
| Namespaces | Stat | `count(count by(namespace) (kube_pod_info))` |
| Total Pods | Stat | `count(kube_pod_info)` |
| Containers | Stat | `count(container_last_seen)` |
| Running Containers | Stat | `count(container_last_seen > 0)` |
| Kubernetes Events (if available) | Stat | `sum(increase(kube_event_count[1h]))` |

## Variables (dynamic dashboard)

To avoid duplicating the dashboard per namespace/node/pod, a
**variable** is used. Example already in use: `namespace`, set to
`applications`, which automatically filters every panel.

Planned variables:

- `namespace`
- `node`
- `pod`

Benefit: 1 maintainable dashboard instead of 20 separate dashboards.

## Saving the dashboard

Suggested name: **Enterprise Kubernetes Platform**.

## 📸 Suggested screenshots

- `images/dashboard-namespace-overview.png` — full dashboard filtered
  by `namespace = applications` (Running Pods, Pending,
  CrashLoopBackOff, Restarts, CPU/Memory Usage, Top CPU/Memory Pods,
  CPU/Memory Trend, Pod Restart).
- `images/dashboard-full-layout.png` — full layout of all 4 rows.