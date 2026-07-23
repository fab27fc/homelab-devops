# 03 — Grafana: access and configuration

## What is a Data Source

Grafana **does not store metrics**; it only queries them.

```
Grafana → queries → Prometheus → Time Series Database
```

When `kube-prometheus-stack` is installed, the Prometheus data source
is configured automatically (visible under **Connections → Data
Sources**).

## Exposing the service

By default the Grafana service is `ClusterIP` (not reachable from
outside the cluster). It was changed to `NodePort` in
`custom-values.yaml`:

```yaml
grafana:
  adminPassword: admin123
  service:
    type: NodePort
```

Verification:

```bash
kubectl get svc monitoring-grafana -n default
```

## Credentials

- Username: `admin`
- Password: whatever was set in `custom-values.yaml` (`admin123`), or
  if it wasn't applied correctly, the auto-generated one stored in the
  Secret:

```bash
kubectl get secret monitoring-grafana \
  -n default \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

## Access

```
http://192.168.100.20:31441
```

(The NodePort may vary; confirm it with
`kubectl get svc monitoring-grafana -n default`.)

## Verifying from inside the cluster

```bash
kubectl run grafana-test \
  --rm -it \
  --restart=Never \
  --image=curlimages/curl \
  -n default \
  -- curl -I http://monitoring-grafana
```

Expected response: `HTTP/1.1 302 Found` (normal redirect to the login
page).

## Dashboards included by the chart

After logging in, several dashboards created by `kube-prometheus-stack`
already exist, for example:

- Kubernetes / Compute Resources
- Kubernetes / Networking
- Kubernetes / API Server
- Node Exporter

## 📸 Suggested screenshots

- `images/grafana-login.png` — Grafana login screen.
- `images/grafana-datasources.png` — **Connections → Data Sources**
  showing Prometheus already configured.