# 00 — Architecture & Workflow

## Objective

Establish the permanent management workflow for the rest of this homelab:
all `kubectl`/`helm`/Git work happens from the Ubuntu management
workstation, never directly on the Kubernetes node.

## Step 1 — Connect to the management workstation

```bash
ssh ffernandez@192.168.100.30
```

Verify you're on the correct machine:

```bash
hostnamectl --static
hostname -I
```

Expected:

```
Hostname: LAB-UBUNTU-MGMT-01
IP:       192.168.100.30
```

## Step 2 — Verify communication with Kubernetes

```bash
kubectl get nodes
```

Expected:

```
NAME              STATUS
lab-rhel-k8s-01   Ready
```

## Step 3 — Project structure (local scratch copy)

```bash
mkdir -p ~/kubernetes
cd ~/kubernetes
mkdir pods replicasets deployments services ingress configmaps secrets storage helm
tree ~/kubernetes
```

This first structure was superseded by the git-tracked project below — kept
here for history.

## Step 4 — Git-tracked project structure

```bash
mkdir -p ~/enterprise-kubernetes-platform
cd ~/enterprise-kubernetes-platform
mkdir -p manifests/{pods,replicasets,deployments,services,configmaps,secrets,ingress,storage}
mkdir docs
mkdir screenshots
tree
```

Expected:

```
enterprise-kubernetes-platform/
│
├── docs
├── manifests
│   ├── pods
│   ├── replicasets
│   ├── deployments
│   ├── services
│   ├── configmaps
│   ├── secrets
│   ├── ingress
│   └── storage
│
└── screenshots
```

## Step 5 — Create the `applications` namespace

```bash
kubectl create namespace applications
kubectl get ns
```

You should see `applications` in the list.

## Final verification

| Component | Value | Status |
|---|---|---|
| Management workstation | `LAB-UBU-MGMT-01` @ `192.168.100.30` | ✅ |
| API Server | `https://192.168.100.20:6443` | ✅ |
| Current context | `kubernetes-admin@kubernetes` | ✅ |
| Cluster status (`lab-rhel-k8s-01`) | `Ready` | ✅ |

## The permanent workflow

```
Ubuntu Management (192.168.100.30)
│
├── kubectl
├── Helm
├── Git
├── Terraform
├── Ansible
├── AWS CLI
└── YAML files
        │
        ▼
RHEL Kubernetes (192.168.100.20)
│
├── API Server
├── Scheduler
├── Controller Manager
├── etcd
├── containerd
├── Calico
├── Applications
└── Monitoring
```

From this point on, this architecture doesn't change: every subsequent
lesson assumes you're `ssh`'d into the Ubuntu management box, inside
`~/enterprise-kubernetes-platform`.

## Bonus: auditing a Kubernetes cluster you've never seen

Useful for interviews and for onboarding onto an unfamiliar cluster — the
systematic way to build a mental map of a cluster in under two minutes:

```bash
# 1. Verify connectivity
kubectl cluster-info

# 2. Inspect the nodes
kubectl get nodes -o wide

# 3. List every namespace
kubectl get ns

# 4. Cluster-wide resource inventory
kubectl get all -A

# 5. Where are the workloads?
kubectl get deployments -A

# 6. Networking
kubectl get svc -A
kubectl get ingress -A

# 7. Storage
kubectl get pvc -A
```

**Interview framing:** "First I verify connectivity with `cluster-info`,
check node health with `get nodes -o wide`, list namespaces to see how the
cluster is segmented, then get a cluster-wide inventory with `get all -A`,
and finally drill into Deployments, Services, Ingress, and storage to
understand how the applications are organized."

## Quality-of-life: default namespace per context

Instead of typing `-n applications` on every command:

```bash
kubectl config set-context --current --namespace=applications
```

From then on:

```bash
kubectl get pods
kubectl get svc
kubectl describe svc nginx-service
```

all implicitly target the `applications` namespace.

When you hit a `NotFound` error, the debugging checklist as an engineer is
always the same three questions:

1. Does the resource actually exist?
2. Am I in the right namespace?
3. Am I using the right context (`kubectl config current-context`)?

That habit matters a lot once you're managing clusters with dozens of
namespaces.

## Screenshots needed

- [ ] `docs/images/kubernetes/00-cluster-info.png` — `kubectl cluster-info` and
      `kubectl get nodes` run from the Ubuntu management workstation,
      proving SSH + kubectl connectivity.
