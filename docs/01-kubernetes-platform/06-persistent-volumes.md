# Lesson 6 — Persistent Volumes & Claims

## Objective

Create storage that survives Pod deletion, and prove it.

## The problem

```
Pod
 │
 ├── nginx binary
 ├── HTML files
 └── temporary filesystem
```

Delete the Pod → the filesystem is gone. Unacceptable for anything
stateful (databases, Prometheus, Grafana, …).

## Theory

```
                 Pod
                  │
                  ▼
        PersistentVolumeClaim
                  │
                  ▼
          PersistentVolume
                  │
                  ▼
       /data/kubernetes/pv001
```

- **PersistentVolume (PV)** — cluster-wide storage resource. Think "the
  disk." In production this is backed by EBS, Azure Disk, GCE PD, NFS,
  Ceph, Longhorn, vSphere CSI, etc. This lab uses `hostPath` (a directory
  on the RHEL node) purely to keep the concepts visible.
- **PersistentVolumeClaim (PVC)** — a namespaced *request* for storage.
  Applications never bind to a PV directly; they claim one via a PVC, and
  Kubernetes matches the claim to a PV that satisfies it (capacity +
  access mode).

```
PV                                  PVC
"a hard drive"        ⇄       "a request to use that hard drive"
```

### `persistentVolumeReclaimPolicy: Retain`

If the PVC is deleted, the PV — and its data — is **kept**, not destroyed.
Production databases commonly use `Retain` to avoid accidental data loss.

## Step 1 — create the PersistentVolume

On the RHEL node:

```bash
sudo mkdir -p /data/kubernetes/pv001
ls -ld /data/kubernetes/pv001
```

[`kubernetes/storage/persistent-volumes/pv001.yaml`](../kubernetes/storage/persistent-volumes/pv001.yaml)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/kubernetes/pv001
```

| Field | Meaning |
|---|---|
| `capacity.storage` | Disk size, `5Gi`. |
| `accessModes: ReadWriteOnce` | One node can mount it read/write — fine for a single-node lab; compare with `ReadWriteMany` once there are multiple worker nodes. |
| `persistentVolumeReclaimPolicy: Retain` | Data survives PVC deletion. |
| `hostPath.path` | The real directory on the RHEL server backing this volume. |

```bash
cd ~/enterprise-kubernetes-platform/manifests/storage/persistent-volumes
kubectl apply --dry-run=client -f pv001.yaml
kubectl apply -f pv001.yaml
kubectl get pv
```

Expected:

```
NAME    CAPACITY   ACCESS MODES   STATUS      RECLAIM POLICY
pv001   5Gi        RWO            Available   Retain
```

`Available` because no PVC has claimed it yet.

## Step 2 — create the PersistentVolumeClaim

[`kubernetes/storage/persistent-volume-claims/pvc001.yaml`](../kubernetes/storage/persistent-volume-claims/pvc001.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc001
  namespace: applications
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

PVCs are namespaced; PVs are cluster-wide.

```bash
cd ~/enterprise-kubernetes-platform/manifests/storage/persistent-volume-claims
kubectl apply --dry-run=client -f pvc001.yaml
kubectl apply -f pvc001.yaml

kubectl get pvc -n applications
kubectl get pv
```

Both should now read `Bound`:

```bash
kubectl describe pvc pvc001 -n applications   # Volume: pv001
kubectl describe pv pv001                     # Claim: applications/pvc001
```

```
Application
      │
      ▼
PersistentVolumeClaim
      │
      ▼
PersistentVolume
      │
      ▼
/data/kubernetes/pv001
```

## Step 3 — mount the PVC in a Pod and prove persistence

[`kubernetes/pods/pvc-test-pod.yaml`](../kubernetes/pods/pvc-test-pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-test
  namespace: applications
spec:
  containers:
    - name: busybox
      image: busybox
      command:
        - sleep
        - "3600"
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: pvc001
```

The application only ever sees `/data` — it has no idea the storage is a
`hostPath`, or that it lives on a specific RHEL server. That abstraction is
one of Kubernetes' biggest strengths (the same Pod spec works unmodified on
AWS EBS, Azure Disk, Ceph, …).

```bash
cd ~/enterprise-kubernetes-platform/manifests/pods
kubectl apply --dry-run=client -f pvc-test-pod.yaml
kubectl apply -f pvc-test-pod.yaml
kubectl get pods -n applications

kubectl exec -it pvc-test -n applications -- sh
```

Inside the Pod:

```sh
df -h
cd /data
echo "Enterprise Kubernetes Platform" > lab.txt
cat lab.txt
exit
```

Delete and recreate the Pod:

```bash
kubectl delete pod pvc-test -n applications
kubectl get pods -n applications        # wait until gone
kubectl apply -f pvc-test-pod.yaml
kubectl get pods -n applications        # wait until Running
```

Verify persistence:

```bash
kubectl exec -it pvc-test -n applications -- sh
cat /data/lab.txt
# Enterprise Kubernetes Platform
exit
```

🎉 The Pod was destroyed and recreated; the file survived.

```
Without a PVC:  Pod → delete → everything lost
With a PVC:     Pod → delete → new Pod → same data
```

This is the same mechanism Prometheus, Grafana, and PostgreSQL rely on to
survive Pod recreation, node restarts, and upgrades.

## Screenshots needed

- [ ] `docs/images/kubernetes/06-pv-available.png` — `kubectl get pv` showing `pv001`
      as `Available` (before the PVC exists).
- [ ] `docs/images/kubernetes/06-pvc-bound.png` — `kubectl get pvc -n applications`
      and `kubectl get pv` both `Bound`.
- [ ] `docs/images/kubernetes/06-persistence-proof.png` — `cat /data/lab.txt` inside
      the recreated Pod, returning the same content written before deletion.
