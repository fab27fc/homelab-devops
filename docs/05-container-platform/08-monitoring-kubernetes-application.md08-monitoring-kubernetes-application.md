# Lab 08 - Monitoring a Kubernetes Application

## Objective

In this lab, Prometheus and Grafana are used to monitor a Kubernetes application running in the cluster. We generate traffic to the application and observe CPU, memory, and network metrics in real time.

---

# Architecture

Internet
        │
        ▼
AWS Load Balancer
        │
        ▼
Kubernetes Service
        │
        ▼
Container Platform Pods
        │
        ▼
Prometheus
        │
        ▼
Grafana

---

# Prerequisites

- Kubernetes Cluster running
- Helm installed
- Prometheus installed
- Grafana installed
- Monitoring Stack deployed
- Container Platform application deployed

---

# Step 1 - Verify the Cluster

Verify the current Kubernetes resources.

```bash
kubectl get namespaces

helm list -n monitoring

kubectl get pods -n monitoring

kubectl get svc -n monitoring
```

### Screenshot

```
monitoring-cluster-initial-state.png
```

---

# Step 2 - Install the Monitoring Stack

Install the kube-prometheus-stack Helm Chart.

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace
```

Verify the installation.

```bash
helm list -n monitoring
```

### Screenshot

```
monitoring-stack-installed.png
```

---

# Step 3 - Verify the Installation

Check that all monitoring components are running.

```bash
kubectl get pods -n monitoring

kubectl get svc -n monitoring
```

### Screenshot

```
monitoring-stack-running.png
```

---

# Step 4 - Access Grafana

Start a port-forward.

```bash
kubectl port-forward \
    -n monitoring \
    svc/monitoring-grafana \
    3000:80 \
    --address 0.0.0.0
```

Open:

```
http://192.168.100.30:3000
```

### Screenshot

```
grafana-port-forward.png
```

---

# Step 5 - Login to Grafana

Retrieve the administrator password.

```bash
kubectl get secret monitoring-grafana \
-n monitoring \
-o jsonpath="{.data.admin-password}" | base64 -d
```

Username:

```
admin
```

### Screenshot

```
grafana-login.png
```

---

# Step 6 - Verify the Prometheus Data Source

Navigate to:

Connections

↓

Data Sources

↓

Prometheus

Click:

```
Test
```

You should receive:

```
Successfully queried the Prometheus API.
```

### Screenshot

```
grafana-prometheus-datasource.png
```

---

# Step 7 - Monitor the Kubernetes Cluster

Open the dashboard:

```
Dashboards

    Kubernetes

        Compute Resources

            Cluster
```

Observe:

- CPU Utilization
- Memory Utilization
- Namespace Usage
- Cluster Resources

### Screenshot

```
grafana-kubernetes-cluster-dashboard.png
```

---

# Step 8 - Monitor a Kubernetes Pod

Open:

```
Dashboards

    Kubernetes

        Compute Resources

            Pod
```

Select:

- Namespace: default
- Pod: container-platform-app

Observe:

- CPU Usage
- Memory Usage
- Network Usage

### Screenshot

```
grafana-pod-monitoring.png
```

---

# Step 9 - Monitor the Application Workload

Open:

```
Dashboards

    Kubernetes

        Compute Resources

            Workload
```

Select:

- Namespace: default
- Workload Type: Deployment
- Workload: container-platform-app

Generate traffic:

```bash
while true; do
    curl http://<LOAD_BALANCER_DNS> > /dev/null
    sleep 1
done
```

Observe:

- CPU Usage
- Memory Usage
- Network Usage

### Screenshot

```
grafana-workload-monitoring.png
```

---

# Skills Learned

- Installing Prometheus using Helm
- Installing Grafana
- Accessing Grafana through port-forward
- Configuring Prometheus as a Data Source
- Monitoring Kubernetes clusters
- Monitoring Pods
- Monitoring Deployments
- Monitoring CPU usage
- Monitoring Memory usage
- Monitoring Network traffic
- Using Kubernetes dashboards
- Using Grafana dashboards

---

# Commands Used

```bash
kubectl get namespaces

helm list -n monitoring

kubectl get pods -n monitoring

kubectl get svc -n monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
--namespace monitoring \
--create-namespace

kubectl port-forward \
-n monitoring \
svc/monitoring-grafana \
3000:80 \
--address 0.0.0.0

kubectl get secret monitoring-grafana \
-n monitoring \
-o jsonpath="{.data.admin-password}" | base64 -d

while true; do
curl http://<LOAD_BALANCER_DNS> > /dev/null
sleep 1
done
```
# Best Practices

The following best practices were implemented during this lab:

- Deploy monitoring components in a dedicated Kubernetes namespace.
- Install Prometheus and Grafana using Helm instead of manual manifests.
- Keep monitoring services internal to the cluster whenever possible.
- Use Kubernetes port-forwarding during development instead of exposing dashboards publicly.
- Verify the Prometheus data source before creating dashboards.
- Monitor applications using Workload dashboards rather than individual Pods whenever possible.
- Continuously monitor CPU, memory, and network utilization to identify performance issues early.

# Skills Demonstrated

- Amazon EKS
- Kubernetes
- Helm
- Prometheus
- Grafana
- kube-prometheus-stack
- Kubernetes Monitoring
- Kubernetes Dashboards
- Observability
- Metrics Collection
- Pod Monitoring
- Workload Monitoring
- Resource Utilization Analysis
- Performance Monitoring

# Conclusion

A complete Kubernetes monitoring platform was successfully deployed on Amazon EKS using the kube-prometheus-stack Helm chart.

Prometheus was configured to collect cluster metrics, while Grafana was used to visualize resource utilization across the cluster, namespaces, workloads, and application Pods.

Traffic generated against the sample application demonstrated how CPU, memory, and network metrics can be monitored in real time, providing the foundation for production-grade observability and future alerting implementations.
