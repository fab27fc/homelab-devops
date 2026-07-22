# Lesson 2 — ReplicaSets

## Objective

Answer: **how does Kubernetes automatically recover from a Pod failure?**

## The problem

A standalone Pod has no recovery mechanism:

```
kubectl delete pod nginx-pod
      │
      ▼
No resources found. → website offline.
```

That's unacceptable in production, hence controllers.

## Theory — the reconciliation loop

A ReplicaSet continuously compares desired state vs. actual state:

```
Desired State
      │
      ▼
Current State
      │
      ▼
   Compare
      │
      ▼
Fix Differences
      │
      ▼
  Repeat forever
```

Every Kubernetes controller (ReplicaSet, Deployment, StatefulSet, …) is a
variation of this loop.

Manifest used: [`kubernetes/replicasets/nginx-rs.yaml`](../kubernetes/replicasets/nginx-rs.yaml)
(shown here at `replicas: 3`, the value it ends at after the scaling lab
below — it started at `replicas: 1`).

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
  namespace: applications
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.28
          ports:
            - containerPort: 80
```

### Field-by-field

| Field | Meaning |
|---|---|
| `apiVersion: apps/v1` | ReplicaSets live in the Apps API group (they manage workloads), unlike Pods (`v1`). |
| `kind: ReplicaSet` | We want a controller that manages Pods, not a Pod directly. |
| `spec.replicas` | The desired Pod count. If actual ≠ desired, the ReplicaSet reconciles immediately. |
| `spec.selector.matchLabels` | How the ReplicaSet decides *which* Pods belong to it — by label, never by name or IP, because names/IPs are ephemeral. |
| `spec.template` | The Pod "cookie cutter" — whenever the ReplicaSet needs a new Pod, it stamps out a copy of this template. |
| `template.metadata.labels` | **Must match `selector.matchLabels` exactly**, or the ReplicaSet won't recognize the Pods it just created — the single most common beginner mistake with ReplicaSets. |

```
ReplicaSet
│  Desired Replicas = 1
│
├── Template
│     │
│     ▼
│  +--------------------+
│  | nginx Pod          |
│  | app=nginx          |
│  | nginx:1.28          |
│  +--------------------+
```

## Hands-on lab

```bash
cd ~/enterprise-kubernetes-platform/manifests/replicasets
kubectl apply --dry-run=client -f nginx-rs.yaml
kubectl apply -f nginx-rs.yaml
kubectl get rs -n applications
kubectl get pods -n applications -o wide
```

Expected:

```
NAME       DESIRED   CURRENT   READY
nginx-rs   1         1         1
```

| Column | Meaning |
|---|---|
| DESIRED | How many Pods Kubernetes wants |
| CURRENT | How many Pods currently exist |
| READY | How many are healthy/ready |

Note the Pod name is no longer `nginx-pod` — it's generated, e.g.
`nginx-rs-6d7d8f8b4c-km2fr`, because the ReplicaSet owns it:

```bash
kubectl describe pod <POD_NAME> -n applications
```

Look for:

```
Controlled By:  ReplicaSet/nginx-rs
```

## Lab 1 — self-healing

Terminal 1 (leave running):

```bash
kubectl get pods -n applications -w
```

Terminal 2:

```bash
kubectl delete pod <POD_NAME> -n applications
```

Terminal 1 shows:

```
Running → Terminating → New Pod: Pending → ContainerCreating → Running
```

Different name, different IP, but:

```bash
kubectl get rs -n applications
# DESIRED 1   CURRENT 1   READY 1   (unchanged)
```

**Key takeaway:** a ReplicaSet doesn't keep a *specific* Pod alive — it
keeps the *desired count* of Pods alive.

## Lab 2 — scaling

```bash
nano nginx-rs.yaml       # replicas: 1 → replicas: 3
kubectl apply -f nginx-rs.yaml
kubectl get pods -n applications -w
kubectl get pods -n applications -o wide
kubectl get rs -n applications
```

Expected:

```
NAME       DESIRED   CURRENT   READY
nginx-rs   3         3         3
```

Delete all Pods at once:

```bash
kubectl delete pods --all -n applications
kubectl get pods -n applications -w
```

All 3 come back, because the desired state is still `replicas: 3`.

## The limitation of ReplicaSets

A ReplicaSet is great at "keep N Pods alive." It cannot:

- ❌ perform a rolling update (e.g. `nginx:1.28` → `nginx:1.29`)
- ❌ roll back a bad version
- ❌ guarantee availability during an image upgrade

That's why production workloads use a **Deployment**, which manages
ReplicaSets on your behalf — see [`03-deployments-rollouts-rollbacks.md`](03-deployments-rollouts-rollbacks.md).

```
Deployment
      │
      ▼
ReplicaSet
      │
      ▼
Pods
```

## Screenshots needed

- [ ] `docs/images/kubernetes/02-replicaset-created.png` — `kubectl get rs -n applications`
      showing `1/1/1`.
- [ ] `docs/images/kubernetes/02-replicaset-self-heal.png` — the `-w` terminal capturing
      Pod termination and automatic recreation.
- [ ] `docs/images/kubernetes/02-replicaset-scaled.png` — `kubectl get pods -n applications -o wide`
      with 3 replicas, different names/IPs, same image.

## Mini quiz

1. What is the purpose of a ReplicaSet?
   *Keep a specified number of Pod replicas running at all times.*
2. What does the `replicas` field define?
   *The desired number of Pods.*
3. Why does a ReplicaSet use labels instead of Pod names?
   *Because Pod names and IPs are ephemeral — labels stay consistent
   regardless of how many times Pods are recreated.*
4. What happens when you delete a Pod managed by a ReplicaSet?
   *The ReplicaSet detects `current < desired` and creates a replacement
   immediately.*
5. What's the difference between DESIRED, CURRENT, and READY in
   `kubectl get rs`?
   *DESIRED = target replica count; CURRENT = Pods that exist right now;
   READY = Pods that exist **and** pass readiness checks.*
