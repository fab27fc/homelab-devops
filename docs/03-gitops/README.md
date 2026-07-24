
Readme · MD
# 🔁 Phase 3a — GitOps with ArgoCD
 
## Objective
 
Replace manual `kubectl apply` / `helm install` operations with a
**GitOps** workflow, where Git becomes the single source of truth for
what should be running in the cluster, and a controller (ArgoCD)
continuously makes the cluster match it. By the end of this module, an
application will be deployed, updated, and self-healed purely through
Git commits — no direct `kubectl` write operations against the running
resources.
 
## What is ArgoCD
 
ArgoCD is a **continuous delivery (CD) controller for Kubernetes**. It
runs inside the cluster, watches one or more Git repositories, and
continuously compares what is defined in Git against what is actually
running. When the two differ, ArgoCD reports the difference and — if
configured to — automatically applies the change so the cluster matches
Git again.
 
```
Git repository (desired state)
      │
      ▼
   ArgoCD  ──── compares desired state vs. live state
      │
      ▼
Kubernetes API Server
      │
      ▼
 Live cluster resources
```
 
## Why GitOps
 
- Every change to the cluster is traceable through Git history (who
  changed what, when, and why).
- Deployments become declarative and repeatable instead of a sequence
  of manual commands.
- Cluster drift (manual `kubectl edit`, ad-hoc fixes) is automatically
  detected and can be automatically corrected.
- It's the deployment pattern most commonly used alongside CI/CD
  pipelines and Kubernetes in production environments.
## Key concepts
 
| Term | Meaning |
|---|---|
| **Declarative deployment** | Describing the desired end state of a resource (e.g. "3 replicas of this image") instead of the sequence of commands to reach it. Kubernetes manifests are already declarative; GitOps extends this idea to *how* they get applied. |
| **Reconciliation loop** | The continuous process where a controller compares desired state vs. live state and acts to correct any difference. ArgoCD runs its own reconciliation loop on top of the one Kubernetes controllers already run internally. |
| **Drift** | Any difference between what's in Git and what's actually running in the cluster — usually caused by a manual `kubectl` change outside of Git. |
| **Sync** | The act of applying the desired state (Git) to the cluster to resolve drift. Can be manual (a person triggers it) or automated (ArgoCD triggers it on its own). |
| **Application (CRD)** | ArgoCD's own Kubernetes custom resource that defines *what* to deploy (a Git repo + path) and *where* to deploy it (a cluster + namespace). Each application managed by ArgoCD has one. |
 
## Contents
 
| File | Description |
|---|---|
| [01-installing-argocd.md](01-installing-argocd.md) | Installing ArgoCD via Helm, exposing the UI, CLI setup. |
| [02-connecting-to-git.md](02-connecting-to-git.md) | Registering a Git repository with ArgoCD. |
| [03-first-application.md](03-first-application.md) | Deploying an application declaratively with an `Application` manifest. |
| [04-app-of-apps.md](04-app-of-apps.md) | Managing multiple applications with the App of Apps pattern. |
| [05-sync-policies.md](05-sync-policies.md) | Manual vs. automated sync, self-healing, pruning. |
| [06-troubleshooting.md](06-troubleshooting.md) | Common issues found while building this module. |
 
## Architecture
 
```
Git repository (source of truth)
      │
      ▼
   ArgoCD  ──── watches the repo, detects drift
      │
      ▼
Kubernetes API Server
      │
      ▼
 Deployed resources (Deployments, Services, ConfigMaps...)
```
 
## Prerequisites
 
- A working Kubernetes cluster.
- Helm v3 installed.
- A Git repository (GitHub, GitLab, etc.) containing the Kubernetes
  manifests to be managed.