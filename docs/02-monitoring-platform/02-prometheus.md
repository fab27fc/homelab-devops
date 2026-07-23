# 02 — Prometheus: access, Targets, and the `up` metric

## Accessing the web UI

Prometheus was not exposed via NodePort, so it's accessed with
`port-forward`:

```bash
kubectl get svc -n default | grep prometheus

kubectl port-forward \
  svc/monitoring-kube-prometheus-prometheus \
  9090:9090 \
  -n default
```

Then open in the browser:

```
http://192.168.100.20:9090
```

## First query: `up`

```
up
```

Returns one line per monitored endpoint, for example:

```
up{job="kubernetes-service-endpoints"} 1
up{job="node-exporter"} 1
up{job="prometheus"} 1
```

- `1` = the service is responding.
- `0` = the service is down.

This metric is the foundation of most availability alerts.

## What is a Target?

A **Target** is any HTTP endpoint (`/metrics`) that Prometheus scrapes
periodically, every 30 seconds by default.

```
Prometheus
   │
   ▼
Node Exporter → GET /metrics
```

Components exposing metrics in this homelab:

- `kubernetes-apiservers`
- `node-exporter`
- `kube-state-metrics`
- `prometheus`
- `alertmanager`

Reviewed under **Status → Targets**. The ideal state is `UP`; `DOWN`
means Prometheus couldn't reach that endpoint.

## Browsing metrics

```
node_
```

Shows hundreds of metrics exposed by Node Exporter, for example:

- `node_cpu_seconds_total`
- `node_memory_MemAvailable_bytes`
- `node_filesystem_avail_bytes`
- `node_load1`

## Full flow

```
Node Exporter
   │
   ▼
/metrics
   │
   ▼
Prometheus (scrape + storage in TSDB)
   │
   ▼
PromQL query
   │
   ▼
Grafana
```

Grafana **never** queries Node Exporter directly: it always goes
through Prometheus.

## 📸 Suggested screenshots

- `images/prometheus-targets.png` — the **Status → Targets** screen
  with all targets `UP`.
- `images/prometheus-query-up.png` — result of the `up` query.