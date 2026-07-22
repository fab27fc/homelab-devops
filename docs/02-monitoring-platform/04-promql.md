# Lesson 10 — PromQL & Building a Grafana Dashboard

## Objective

Move from "the monitoring stack is installed" to actually using it:
understand how Grafana and Prometheus relate, learn PromQL, and hand-build
a Kubernetes overview dashboard panel by panel.

## Theory — how Grafana and Prometheus relate

**Grafana never stores metrics.** It only queries a data source (here,
Prometheus) and renders the result.

```
Grafana
   │  query (PromQL)
   ▼
Prometheus
   │
   ▼
Time-series database (TSDB)
```

## Data source

In Grafana: `Connections → Data Sources` — should already show
`Prometheus`, auto-configured by the `kube-prometheus-stack` chart.

## Prometheus targets — who is being scraped

A **Target** is any endpoint Prometheus scrapes on an interval (default
~30s), e.g. `http://node-exporter:9100/metrics`.

```bash
kubectl port-forward \
  svc/monitoring-kube-prometheus-prometheus \
  9090:9090 -n default
```

Open `http://192.168.100.20:9090`, then `Status → Targets`. Expect
`kubernetes-apiservers`, `node-exporter`, `kube-state-metrics`,
`prometheus`, `alertmanager` all `UP`.

Every Target exposes raw metrics at `/metrics` (thousands of lines like
`node_cpu_seconds_total`, `node_memory_MemAvailable_bytes`); Prometheus
scrapes and stores them, then PromQL queries them.

```
Node Exporter → /metrics → Prometheus → PromQL query → Grafana
```

**Key fact for interviews:** Grafana never talks to Node Exporter directly
— it only ever talks to Prometheus.

## PromQL basics

PromQL is Prometheus's query language — conceptually SQL for time series.

```promql
node_memory_MemAvailable_bytes
```

returns one line **per label combination**, e.g.:

```
node_memory_MemAvailable_bytes{instance="192.168.100.20:9100"} 6.83e+09
```

- **Metric name**: `node_memory_MemAvailable_bytes`
- **Labels**: `instance="192.168.100.20:9100"` — the same metric can exist
  many times over, once per label combination (per CPU core, per mode, per
  node, …).

Filter by label:

```promql
node_memory_MemAvailable_bytes{instance="192.168.100.20:9100"}
```

Aggregate functions:

```promql
avg(node_memory_MemAvailable_bytes)      # average
sum(node_memory_MemAvailable_bytes)      # sum
count(up)                                 # how many targets exist
topk(5, node_memory_MemAvailable_bytes)   # top 5 by value
```

`rate()` — how fast a counter is changing over a window, essential for
CPU/network metrics (which are cumulative counters, not gauges):

```promql
rate(node_cpu_seconds_total[5m])
```

### Handling empty results ("No data")

A query like `count(kube_pod_status_phase{phase="Pending"} == 1)` returns
**no series at all** (not zero) when nothing matches — Grafana renders
that as "No data," which is misleading (it looks broken, but it actually
means the count is 0). Fix with `or vector(0)`:

```promql
count(kube_pod_status_phase{phase="Pending"} == 1) or vector(0)
```

## Dashboard design principles

A good dashboard isn't the one with the most graphs — it's the one that
answers **"is my cluster healthy?"** in the first 10 seconds.

1. **Row 1 — is anything broken?** (before resource usage, before
   anything else)
2. **Row 2 — resource usage** (CPU/memory/disk/network)
3. **Row 3+ — diagnostic detail**, only useful once row 1/2 flagged a
   problem.

```
┌─────────────────────────────────────────────────────────────┐
│ Row 1 — Cluster health                                       │
│ Targets Up │ Ready Nodes │ Running Pods │ Pending │ Failed   │
│ Restarts                                                     │
├─────────────────────────────────────────────────────────────┤
│ Row 2 — Resources                                             │
│ CPU │ Memory │ Disk │ Network RX │ Network TX                │
├─────────────────────────────────────────────────────────────┤
│ Row 3 — Application detail                                    │
│ Top CPU Pods           │ Top Memory Pods                      │
├─────────────────────────────────────────────────────────────┤
│ Row 4 — Diagnostics                                            │
│ CrashLoopBackOff │ Active Alerts │ Namespaces │ Top Restarts  │
└─────────────────────────────────────────────────────────────┘
```

## Panel reference — "Enterprise Kubernetes Overview"

All panels below were built in Grafana's panel editor (`Add → Visualization
→ Prometheus`, query in **Code** mode, not **Builder**).

### Row 1 — Cluster health

| Panel | Query | Viz |
|---|---|---|
| Prometheus Targets Up | `count(up == 1)` | Stat |
| Running Pods | `count(kube_pod_status_phase{phase="Running"} == 1)` | Stat |
| Pending Pods | `count(kube_pod_status_phase{phase="Pending"} == 1) or vector(0)` | Stat |
| Failed Pods | `count(kube_pod_status_phase{phase="Failed"} == 1) or vector(0)` | Stat |
| Unknown Pods | `count(kube_pod_status_phase{phase="Unknown"} == 1) or vector(0)` | Stat |
| Succeeded Pods | `count(kube_pod_status_phase{phase="Succeeded"} == 1) or vector(0)` | Stat |
| CrashLoopBackOff Pods | `count(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} == 1) or vector(0)` | Stat |
| Total Nodes | `count(kube_node_info)` | Stat |
| Pod Restarts (cumulative) | `sum(kube_pod_container_status_restarts_total)` | Stat |

### Row 2 — Node resources

| Panel | Query | Viz / Unit |
|---|---|---|
| Node CPU Usage % | `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | Stat/Gauge, Percent (0-100) |
| Cluster CPU Usage % | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` | Gauge, Percent (0-100) |
| Node Memory Usage % | `100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))` | Stat, Percent (0-100) |
| Disk Usage % | `100 * (1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}))` | Stat, Percent (0-100) |
| Network Receive (MB/s) | `sum(rate(node_network_receive_bytes_total{device!~"lo|veth.*|cali.*"}[5m])) / 1024 / 1024` | Stat, Data rate MiB/s |
| Network Transmit (MB/s) | `sum(rate(node_network_transmit_bytes_total{device!~"lo|veth.*|cali.*"}[5m])) / 1024 / 1024` | Stat, Data rate MiB/s |

Thresholds used on CPU/Memory/Disk %: 🟢 0–70, 🟡 70, 🔴 90.

> **Known gap:** `PVC Usage %` (`kubelet_volume_stats_used_bytes /
> kubelet_volume_stats_capacity_bytes`) returned **No data** in this
> cluster — `kubelet_volume_stats_*` metrics weren't being exposed. Query
> each half separately (`kubelet_volume_stats_used_bytes`,
> `kubelet_volume_stats_capacity_bytes`) in the Prometheus UI to confirm
> before spending time debugging the combined panel; if both are empty,
> it's a kubelet/cAdvisor exposition gap, not a query bug, and the panel
> is dropped until it's resolved.

### Row 3 — Application detail (Table panels)

| Panel | Query |
|---|---|
| Top CPU Pods | `topk(10, sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{container!="",container!="POD",pod!=""}[5m])))` |
| Top Memory Pods | `topk(10, sum by (namespace, pod) (container_memory_working_set_bytes{container!="",container!="POD",pod!=""}))` |
| Top Restarting Pods | `topk(10, kube_pod_container_status_restarts_total)` |

Unit for Top Memory Pods: **Bytes (IEC)** — Grafana auto-converts to
MiB/GiB.

### Row 4 — Diagnostics

| Panel | Query |
|---|---|
| Active Alerts | `count(ALERTS{alertstate="firing"}) or vector(0)` |
| Namespaces | `count(count by(namespace) (kube_pod_info))` |
| Total Pods | `count(kube_pod_info)` |
| Containers | `count(container_last_seen)` |
| Running Containers | `count(container_last_seen > 0)` |
| Kubernetes Events (1h) | `sum(increase(kube_event_count[1h]))` — not available on every cluster/chart version |

## Building the dashboard (workflow used)

1. `+ → New Dashboard → Add visualization → Prometheus`.
2. Switch the query editor from **Builder** to **Code**, paste the PromQL.
3. `Run queries`, then pick a visualization (`Stat` for single numbers,
   `Table` for top-N lists, `Gauge` for percentages with thresholds).
4. Set **Standard options → Unit** appropriately (Percent (0-100),
   Bytes (IEC), Data rate, …) and configure **Thresholds** for color
   coding.
5. Title the panel, `Apply`, then `Save dashboard` — name it
   `Enterprise Kubernetes Overview` (or `Enterprise Kubernetes Platform`).
6. Repeat per panel, arranging rows by the layout in "Dashboard design
   principles" above.

## Screenshots needed

- [ ] `docs/images/kubernetes/10-prometheus-targets.png` — Prometheus
      **Status → Targets** page, all `UP`.
- [ ] `docs/images/kubernetes/10-promql-up-query.png` — Prometheus graph UI running
      the `up` query.
- [ ] `docs/images/kubernetes/10-grafana-first-panel.png` — Grafana panel editor with
      `count(up == 1)` configured as a Stat panel.
- [ ] `docs/images/kubernetes/10-dashboard-full.png` — the final assembled
      "Enterprise Kubernetes Overview" dashboard with all rows.

## Mini quiz

1. **What is a Prometheus Target?** An endpoint that exposes metrics for
   Prometheus to scrape.
2. **What does it mean if a Target is `DOWN`?** Prometheus can't reach or
   scrape it — network issue, the app is stopped, or misconfiguration.
3. **Does Grafana collect metrics directly from Node Exporter?** No —
   Grafana only ever queries Prometheus; Prometheus scrapes Node Exporter.
4. **What endpoint usually exposes Prometheus-compatible metrics?**
   `/metrics`.
5. **Which component stores the metrics?** Prometheus, in its TSDB.
6. **What is PromQL?** Prometheus's query language for selecting and
   aggregating time-series metrics.
7. **What are labels used for?** Distinguishing multiple series under the
   same metric name (per instance, per CPU core, per mode, etc.) and for
   filtering/grouping queries.
8. **What does `count(up)` return?** The number of scrape targets
   Prometheus currently knows about.
9. **What does `avg()` do?** Averages a metric across all matching series.
10. **What's the purpose of `rate()`?** Computes the per-second average
    rate of increase of a counter over a time window — required for
    counters like `_seconds_total` / `_bytes_total`, which only ever go up.

## What's next

- **Variables** (`Dashboard settings → Variables`) — turn hardcoded values
  like a namespace or node into a dropdown, so one dashboard covers every
  namespace/node/pod instead of duplicating dashboards per target.
- **Alertmanager rules** — `CPU > 80%`, `Memory > 90%`, `Disk > 85%`,
  `Pod CrashLoopBackOff`, `Node NotReady`.
- **Namespace reorganization** — moving workloads out of `default` into
  purpose-built namespaces (`monitoring`, `argocd`, `applications`,
  `ingress-nginx`, `datadog`, `splunk`) as each new component is
  installed, rather than retrofitting existing ones.

Those pick up in the next phase of the platform (ArgoCD/GitOps, MetalLB,
Datadog, Splunk, Terraform, Ansible) — not yet documented here.
