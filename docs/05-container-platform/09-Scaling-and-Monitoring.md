# Lab 09 — Scaling and Monitoring a Kubernetes Application

## Objective

The objective of this lab is to demonstrate how Kubernetes Deployments can be scaled horizontally while monitoring resource utilization in real time using Prometheus and Grafana.

This lab validates that additional Pod replicas are automatically created and that application traffic is distributed across all running instances.

---

# Architecture

User Traffic

↓

AWS Elastic Load Balancer

↓

Kubernetes Service (LoadBalancer)

↓

Deployment

↓

Pods (2 → 5 → 2)

↓

Prometheus

↓

Grafana Dashboards

---

# Prerequisites

- Amazon EKS Cluster running
- kubectl configured
- Sample application deployed
- Prometheus installed
- Grafana installed
- kube-prometheus-stack deployed
- AWS Load Balancer available

---

# Step 1 — Verify the Current Deployment

Check the current deployment status.

```bash
kubectl get deployment
```

Expected output:

```text
READY   UP-TO-DATE   AVAILABLE
2/2     2            2
```

Screenshot:

```

deployment-before-scaling.png

```

---

# Step 2 — Verify Existing Pods

```bash
kubectl get pods
```

Initially the application is running with two Pod replicas.

Screenshot:

```

pods-before-scaling.png

```

---

# Step 3 — Generate Application Traffic

Generate continuous HTTP requests.

```bash
while true; do
    curl -s http://af6c3da5c811a40408d957d93362210c-851262690.us-east-1.elb.amazonaws.com > /dev/null
    sleep 1
done
```

This produces CPU, Memory and Network metrics that Prometheus collects.

---

# Step 4 — Scale the Deployment

Increase the number of replicas.

```bash
kubectl scale deployment container-platform-app \
    --replicas=5
```

Verify:

```bash
kubectl get deployment
```

Expected:

```text
READY   UP-TO-DATE   AVAILABLE
5/5     5            5
```

Screenshot:

```

deployment-5-replicas.png

```

---

# Step 5 — Observe Pod Creation

Watch Kubernetes create additional Pods.

```bash
kubectl get pods -w
```

Kubernetes automatically schedules three additional replicas.

Screenshot:

```

pods-after-scaling.png

```

---

# Step 6 — Monitor the Workload in Grafana

Open:

Dashboard →

Kubernetes /

Compute Resources /

Workload

Select:

- Namespace: default
- Workload Type: Deployment
- Workload:
  container-platform-app

Observe:

- CPU Usage
- Memory Usage
- Network Usage
- Individual Pod metrics

Screenshot:

```

grafana-workload-5pods.png

```

---

# Step 7 — Monitor Cluster Resources

Open:

Dashboard →

Kubernetes /

Compute Resources /

Cluster

Verify that cluster metrics reflect the increased workload.

Observe:

- CPU Utilization
- Memory Utilization
- Namespace Resource Usage

Screenshot:

```

grafana-cluster-scaled.png

```

---

# Step 8 — Scale Back the Deployment

Reduce the number of replicas.

```bash
kubectl scale deployment container-platform-app \
    --replicas=2
```

Watch Pods terminate.

```bash
kubectl get pods -w
```

Screenshot:

```

deployment-scaled-back.png

```

---

# Kubernetes Concepts Demonstrated

- Deployments
- ReplicaSets
- Horizontal Scaling
- Pod Scheduling
- Load Balancing
- Kubernetes Services
- Observability
- Prometheus Metrics
- Grafana Dashboards
- Resource Monitoring

---

# Best Practices

The following best practices were implemented during this lab:

- Scale applications using Deployments instead of creating Pods manually.
- Monitor workloads during scaling events.
- Generate real application traffic to validate metrics.
- Verify Deployment health after scaling operations.
- Observe resource utilization before and after scaling.
- Use Grafana dashboards for real-time infrastructure visibility.
- Keep monitoring tools isolated inside the monitoring namespace.

---

# Skills Demonstrated

- Amazon EKS
- Kubernetes
- Deployments
- ReplicaSets
- Horizontal Scaling
- Pod Lifecycle
- Kubernetes Services
- Prometheus
- Grafana
- Kubernetes Monitoring
- Observability
- Resource Analysis
- Performance Monitoring

---

# Conclusion

The Kubernetes application was successfully scaled from two replicas to five replicas without downtime using a Deployment.

Prometheus collected real-time metrics throughout the scaling operation, while Grafana visualized CPU, memory, and cluster resource utilization across all application replicas.

Finally, the deployment was scaled back to two replicas, demonstrating Kubernetes' ability to dynamically adjust application capacity while maintaining service availability. This lab provides the foundation for implementing rolling updates, rollbacks, and Horizontal Pod Autoscaling (HPA) in subsequent Kubernetes platform labs.
