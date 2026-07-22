# Lesson 3 — Deployments, Rolling Updates & Rollbacks

## Objective

From here on, almost every workload in this repo is a **Deployment** — the
resource used ~90% of the time in real Kubernetes environments. Engineers
rarely create ReplicaSets directly; they create Deployments, which manage
ReplicaSets automatically and add rolling updates, rollbacks, and version
history.

## Why Deployments exist

| Object | Gives you | Missing |
|---|---|---|
| Pod | Runs one application | No self-healing |
| ReplicaSet | Maintains N replicas | No version management |
| **Deployment** | Rolling updates, rollbacks, scaling, self-healing, version history | — |

```
Deployment
      │
      ▼
ReplicaSet
      │
      ▼
Pods
```

Instead of telling Kubernetes "create three Pods," you tell it "I want my
application running with three replicas using version 1.28" — Kubernetes
figures out how to get there and how to change versions safely.

## Cleanup — replacing the manual ReplicaSet

```bash
kubectl delete rs nginx-rs -n applications
kubectl get rs -n applications      # No resources found.
kubectl get pods -n applications    # No resources found.
```

Deleting the ReplicaSet also deletes the Pods it owned.

## Manifest

[`kubernetes/deployments/nginx-deployment.yaml`](../kubernetes/deployments/nginx-deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: applications
spec:
  replicas: 3
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

This is nearly identical to the ReplicaSet manifest — the only functional
difference is `kind: Deployment`. Internally, Kubernetes creates the whole
chain (Deployment → ReplicaSet → Pods) for you.

## Theory — object responsibilities

```
                Deployment
                     │
                     ▼
                ReplicaSet
                     │
                     ▼
              Pod  Pod  Pod
```

- **Deployment** owns the application lifecycle: which version, how many
  replicas, how to upgrade, whether to roll back.
- **ReplicaSet** just guarantees the replica count.
- **Pod** just runs the container. It knows nothing about Deployments or
  ReplicaSets.

## Hands-on lab — create and verify

```bash
cd ~/enterprise-kubernetes-platform/manifests/deployments
kubectl apply --dry-run=client -f nginx-deployment.yaml
kubectl apply -f nginx-deployment.yaml

kubectl get deployments -n applications
kubectl get rs -n applications
kubectl get pods -n applications -o wide
kubectl describe deployment nginx-deployment -n applications
```

Expected:

```
NAME               READY   UP-TO-DATE   AVAILABLE
nginx-deployment   3/3     3            3
```

| Column | Meaning |
|---|---|
| READY | Pods that passed readiness checks |
| UP-TO-DATE | Pods running the latest Deployment revision |
| AVAILABLE | Pods actively serving traffic |

Prove the ownership chain:

```bash
kubectl describe pod <POD_NAME> -n applications
# Controlled By: ReplicaSet/nginx-deployment-<hash>

kubectl describe rs <REPLICASET_NAME> -n applications
# Controlled By: Deployment/nginx-deployment
```

Pod naming convention: `<deployment-name>-<replicaset-hash>-<random-id>`.

## Rolling update strategy

```
kubectl describe deployment nginx-deployment -n applications
```

```
StrategyType: RollingUpdate
RollingUpdateStrategy: 25% max unavailable, 25% max surge
```

With `replicas: 3`:

- **max unavailable 25%** → `ceil(0.25 × 3) = 1` — at most 1 Pod can be down
  during the rollout.
- **max surge 25%** → Kubernetes may temporarily create up to 1 extra Pod
  (4 total) so a new Pod is healthy *before* an old one is removed.

```
Old Pods: 1  2  3
   │
   ▼ create new Pod
Pods: 1  2  3  4
   │
   ▼ new Pod healthy → delete an old Pod
Pods: 2  3  4
   │
   ▼ repeat...
```

This is why users never see downtime during an upgrade.

## Lab — perform a rolling update

Terminal 1 (leave running):

```bash
kubectl get pods -n applications -w
```

Terminal 2:

```bash
kubectl describe deployment nginx-deployment -n applications | grep Image
# Image: nginx:1.28

nano nginx-deployment.yaml     # image: nginx:1.28 → nginx:1.29
kubectl apply -f nginx-deployment.yaml
```

Terminal 1 shows the interleaved replace sequence:

```
Old Pod    Running
New Pod    Pending → ContainerCreating → Running
Old Pod    Terminating
... repeated until all 3 are on the new version
```

What's really happening: the Deployment creates a **new ReplicaSet** for
`nginx:1.29` and gradually scales it up while scaling the old ReplicaSet
(`nginx:1.28`) down to zero — for a short window, both ReplicaSets exist:

```
Deployment
      │
      ├──────────────┐
      ▼              ▼
Old ReplicaSet    New ReplicaSet
(v1.28, →0)       (v1.29, →3)
```

Verify:

```bash
kubectl rollout status deployment/nginx-deployment -n applications
# deployment "nginx-deployment" successfully rolled out

kubectl describe deployment nginx-deployment -n applications | grep Image
# Image: nginx:1.29

kubectl get rs -n applications
```

```
NAME                            DESIRED CURRENT READY
nginx-deployment-59688fc659     0       0       0
nginx-deployment-5fc8b94db6     3       3       3
```

The old ReplicaSet is kept around at `0` replicas — that's the mechanism
that makes rollback instant.

## Lab — rollback

Scenario: `nginx:1.30` ships broken and users start seeing errors.

```bash
kubectl rollout history deployment/nginx-deployment -n applications
kubectl get rs -n applications
kubectl rollout undo deployment/nginx-deployment -n applications
```

Expected: `deployment.apps/nginx-deployment rolled back`.

Watch it happen (another rolling update, in reverse):

```bash
kubectl get pods -n applications -w
kubectl rollout status deployment/nginx-deployment -n applications
kubectl get rs -n applications
kubectl describe deployment nginx-deployment -n applications | grep Image
# Image: nginx:1.28
```

The rollback doesn't hand-pick or recreate individual Pods — it just tells
the Deployment "make the old ReplicaSet the active one," and the same
rolling-update machinery runs in reverse.

## Screenshots needed

- [ ] `docs/images/kubernetes/03-deployment-created.png` — `kubectl get deployments -n applications`
      + `kubectl get rs -n applications` proving Deployment → ReplicaSet.
- [ ] `docs/images/kubernetes/03-rolling-update-watch.png` — the `-w` terminal mid
      rolling update, old and new Pods visible together.
- [ ] `docs/images/kubernetes/03-rollout-status.png` — successful rollout status +
      `grep Image` showing `nginx:1.29`.
- [ ] `docs/images/kubernetes/03-rollback.png` — `kubectl rollout undo` output and
      `kubectl get rs -n applications` with counts flipped back.

## Interview answer — "what happens internally when you update a Deployment?"

> The Deployment creates a new ReplicaSet based on the updated Pod
> template. It gradually scales up the new ReplicaSet while scaling down
> the old one according to the RollingUpdate strategy (`maxSurge` and
> `maxUnavailable`). Once the rollout completes, the old ReplicaSet is kept
> at zero replicas so it can be used for a rollback if necessary.

## Mini quiz

1. **What is a Deployment revision?** A saved version of a Deployment's
   Pod template; Kubernetes creates a new one each time the spec changes.
2. **What is a Rolling Update?** The default strategy that replaces Pods
   gradually instead of all at once, avoiding downtime.
3. **What command shows rollout history?**
   `kubectl rollout history deployment <name>`
4. **What command rolls back to the previous revision?**
   `kubectl rollout undo deployment <name>`
5. **Does a rollback recreate Pods manually or trigger another rolling
   update?** Another rolling update — Pods from the previous revision
   gradually replace the current ones.
6. **Why does Kubernetes keep old ReplicaSets?** So a rollback is instant
   and doesn't require rebuilding anything from scratch.
