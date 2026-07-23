# 04 — Introduction to PromQL

PromQL (Prometheus Query Language) is Prometheus's query language —
similar to SQL, but for metrics.

## Anatomy of a metric

```
node_memory_MemAvailable_bytes{instance="192.168.100.20:9100"} 6.83e+09
```

- **Name**: `node_memory_MemAvailable_bytes`
- **Labels**: `instance="192.168.100.20:9100"` — used to filter among
  thousands of series of the same metric.

## Basic queries used in the lab

| Query | What it answers |
|---|---|
| `up` | Which endpoints are alive (1) or down (0). |
| `node_memory_MemAvailable_bytes{instance="..."}` | Available memory for a specific server. |
| `node_cpu_seconds_total` | Accumulated CPU time by mode/core. |
| `avg(node_memory_MemAvailable_bytes)` | Average available memory. |
| `count(up)` | Number of monitored targets. |
| `sum(node_memory_MemAvailable_bytes)` | Total available memory. |
| `rate(node_cpu_seconds_total[5m])` | Rate of change over the last 5 minutes (heavily used for CPU and network). |
| `topk(5, node_memory_MemAvailable_bytes)` | The 5 highest values. |

## Handling "No data"

When no series matches the condition inside a `count(...)`, Prometheus
returns an empty result and Grafana displays it as `No data` — this
does **not** mean the query is wrong, it means the real value is `0`.

Fix: append `or vector(0)`:

```promql
count(kube_pod_status_phase{phase="Pending"} == 1) or vector(0)
```

## 📸 Suggested screenshots

- `images/prometheus-query-node-cpu.png` — the
  `node_cpu_seconds_total` query in Graph mode.
