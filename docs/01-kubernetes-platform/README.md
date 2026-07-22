# Kubernetes Platform — Documentation

Homelab documentation for the Kubernetes portion of this repo: a
production-style progression from a single Pod to a self-healing,
upgradeable, configurable application, exposed via Ingress with
persistent storage, monitored by a Helm-installed Prometheus/Grafana
stack.

Every doc here follows the same shape: **theory** (why the object exists,
with diagrams), **hands-on lab** (exact commands run, in order), the
**manifest** used (linked to `kubernetes/` or `monitoring/`), **real
troubleshooting** hit along the way where applicable, and a **screenshots**
checklist with the exact filename expected under `docs/images/kubernetes/`.

## Contents

1. [`01-cluster-overview.md`](01-cluster-overview.md) — management
   workflow, environment, cluster audit commands.
2. [`02-workloads.md`](02-workloads.md) — Pods, ReplicaSets, Deployments,
   Rolling Updates, Rollbacks, ConfigMaps, Secrets.
3. [`03-networking.md`](03-networking.md) — Services (NodePort,
   self-healing demo), Ingress.
4. [`04-storage.md`](04-storage.md) — PersistentVolumes, Claims, and
   proving data survives Pod recreation.
5. [`05-helm.md`](05-helm.md) — Helm, the kube-prometheus-stack install
   (with the real permission/StorageClass troubleshooting it took to get
   right), PromQL, and building a Grafana dashboard.

## Roadmap

- [x] Cluster setup & workflow
- [x] Pods, ReplicaSets, Deployments, rolling updates, rollbacks
- [x] ConfigMaps, Secrets
- [x] Services, Ingress
- [x] Persistent Volumes / Claims
- [x] Helm + Prometheus/Grafana install
- [x] PromQL + Grafana dashboards
- [ ] Grafana variables & Alertmanager rules
- [ ] MetalLB
- [ ] ArgoCD / GitOps
- [ ] Datadog
- [ ] Splunk
- [ ] Terraform integration
- [ ] Ansible automation
