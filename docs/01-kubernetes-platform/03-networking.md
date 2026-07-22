# Kubernetes Networking

## Overview

This document describes the networking components used in the Kubernetes platform.

The cluster uses Calico as the Container Network Interface (CNI), CoreDNS for internal DNS resolution, Kubernetes Services for service discovery, and the NGINX Ingress Controller for HTTP routing.

---

# Network Architecture

```
                Internet
                    │
                    │
        192.168.100.0/24
                    │
         Kubernetes Node
                    │
      ┌────────────────────────┐
      │                        │
  Kubernetes Network      Cluster Services
      │                        │
    Calico                 CoreDNS
      │                        │
      └──────────────┬─────────┘
                     │
               Application Pods
```

---

# Calico

The cluster uses Calico as the CNI plugin.

Responsibilities:

- Pod networking
- Pod-to-Pod communication
- IP allocation
- Network Policies
- Routing

### Validation

```bash
kubectl get pods -n calico-system
```

---

# CoreDNS

CoreDNS provides internal service discovery.

Applications communicate using Service names instead of Pod IP addresses.

Example:

```
nginx-service.applications.svc.cluster.local
```

### Validation

```bash
kubectl get pods -n kube-system
kubectl get svc -n kube-system
```

---

# Services

Applications are exposed internally using Kubernetes Services.

Current Service:

```
nginx-service
```

Validation:

```bash
kubectl get svc -n applications
kubectl describe svc nginx-service -n applications
```

---

# Endpoints

Every Service creates Endpoints that point to the Pods selected by its labels.

Validation:

```bash
kubectl get endpoints -n applications
kubectl get endpointslices -n applications
```

---

# Ingress

The cluster uses the NGINX Ingress Controller.

The Ingress routes HTTP traffic to backend Services.

Current resource:

```
nginx-ingress
```

Validation:

```bash
kubectl get ingress -n applications
kubectl describe ingress nginx-ingress -n applications
```

---

# Network Validation

Useful commands:

```bash
kubectl get svc -A

kubectl get ingress -A

kubectl get endpoints -A

kubectl get endpointslices -A

kubectl get pods -o wide

kubectl get nodes -o wide
```

---

# Lessons Learned

- Every Pod receives its own IP address.
- Services provide stable virtual IP addresses.
- CoreDNS resolves Service names.
- Calico connects Pods across the cluster.
- Ingress exposes HTTP applications.
- Labels and selectors determine traffic routing.