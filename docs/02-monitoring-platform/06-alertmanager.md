# 06 — Alertmanager (pending)

This module hasn't been built yet in the lab. Once completed, it will
document:

- How Prometheus evaluates alerting rules and sends them to
  Alertmanager.
- Alerts planned for this homelab:
  - 🚨 CPU > 80%
  - 🚨 Memory > 90%
  - 🚨 Disk > 85%
  - 🚨 Pod in `CrashLoopBackOff`
  - 🚨 Node `NotReady`
- Route and receiver configuration (`route`, `receiver`) in
  Alertmanager.
- How active alerts show up in Grafana
  (`ALERTS{alertstate="firing"}`) and in the Alertmanager UI itself.

> Update this file once the Alertmanager lesson is completed.

## 📸 Suggested screenshots (once completed)

- `images/alertmanager-ui.png`
- `images/alert-rule-cpu.png`
- `images/grafana-active-alerts.png`
