# Lesson 1 — Your First Kubernetes Workload (Pods)

## Objective

- Create a first application and deploy it to Kubernetes.
- Understand every field in the YAML.
- Learn how Kubernetes creates a Pod.
- Verify networking, troubleshoot, and document.

## Theory

A **Pod** is the smallest deployable unit in Kubernetes. It wraps one or
more containers that share networking and storage. Today's Pod runs a
single NGINX container.

Manifest used: [`kubernetes/pods/nginx-pod.yaml`](../kubernetes/pods/nginx-pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  namespace: applications
  labels:
    app: nginx
    environment: lab
spec:
  containers:
    - name: nginx
      image: nginx:1.28
      ports:
        - containerPort: 80
```

> **Note:** the very first draft of this file (written with `nano`) had a
> broken indentation — `labels:` wasn't nested under `metadata:`, and
> `image:` wasn't nested under the container list item. Kubernetes YAML is
> whitespace-sensitive; this is one of the most common beginner mistakes and
> `kubectl apply --dry-run=client` is exactly the tool that catches it
> before it reaches the cluster (see Step 3 below).

### Field-by-field

| Field | Meaning |
|---|---|
| `apiVersion: v1` | Pods belong to the Core API group, which uses `v1`. |
| `kind: Pod` | We're creating a single Pod — not a Deployment, not a Service. |
| `metadata.name` | The Pod's name. |
| `metadata.namespace` | Places the Pod in `applications` instead of `default`. |
| `metadata.labels` | Key/value tags used later by Services, Deployments, monitoring, and Network Policies to select this Pod. |
| `spec` | The **desired state** — what we want Kubernetes to create. |
| `spec.containers` | A Pod can hold one or more containers; here just one. |
| `image` | containerd pulls `nginx:1.28` from Docker Hub. |
| `containerPort: 80` | Documentation only — it tells Kubernetes the container listens on port 80. It does **not** expose the Pod outside the cluster (that's what Services are for — see [`04-services.md`](04-services.md)). |

## Hands-on lab

```bash
cd ~/enterprise-kubernetes-platform/manifests/pods
nano nginx-pod.yaml       # paste the manifest above
```

### Validate before applying

```bash
kubectl apply --dry-run=client -f nginx-pod.yaml
```

Expected:

```
pod/nginx-pod created (dry run)
```

Validating first is a habit worth keeping for every manifest in this repo —
it catches YAML/schema errors before they reach the cluster.

### Apply

```bash
kubectl apply -f nginx-pod.yaml
```

### Verify

```bash
kubectl get pods -n applications -o wide
kubectl describe pod nginx-pod -n applications
```

## What happens internally

```
kubectl apply
      │
      ▼
API Server (validates + persists to etcd)
      │
      ▼
Scheduler (picks a node)
      │
      ▼
kubelet on lab-rhel-k8s-01
      │
      ▼
containerd pulls nginx:1.28 and starts the container
```

## Screenshots needed

- [ ] `docs/images/kubernetes/01-pod-dry-run.png` — output of
      `kubectl apply --dry-run=client -f nginx-pod.yaml`.
- [ ] `docs/images/kubernetes/01-pod-running.png` — `kubectl get pods -n applications -o wide`
      showing `nginx-pod` as `Running` with its Pod IP.

## Takeaway

A standalone Pod has no self-healing: `kubectl delete pod nginx-pod` makes
it disappear permanently (`No resources found.`). That gap is exactly what
[`02-replicasets.md`](02-replicasets.md) solves.
