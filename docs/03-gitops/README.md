# 🔁 Phase 3a — GitOps with ArgoCD
 
## Objective
 
Stop running `kubectl apply` and `helm install` by hand. Instead, use
**GitOps**: Git holds the setup you want, and a tool called ArgoCD
makes the cluster match it. By the end of this module, an app will be
deployed and updated only through Git commits — not through `kubectl`.
 
## What is ArgoCD
 
ArgoCD is a **continuous delivery (CD) controller for Kubernetes**. It
runs inside the cluster, watches one or more Git repositories, and
continuously compares what is defined in Git against what is actually
running. When the two differ, ArgoCD reports the difference and — if
configured to — automatically applies the change so the cluster matches
Git again.
 
```
Git repository (what you want)
      │
      ▼
   ArgoCD  ──── checks Git against the live cluster
      │
      ▼
Kubernetes API Server
      │
      ▼
 Live cluster resources
```
 
## Why use GitOps
 
- Every change is a Git commit, so you can see who changed what, and
  when.
- You describe the end result you want, not the list of commands to
  get there.
- If someone changes something by hand in the cluster, ArgoCD notices
  and can undo it.
- This is the standard way most companies deploy to Kubernetes today.
## Key terms
 
| Term | Meaning |
|---|---|
| **Declarative deployment** | You describe what you want (e.g. "3 copies of this app"), not the steps to get there. |
| **Reconciliation loop** | ArgoCD keeps checking: does Git match the cluster? If not, it fixes it. |
| **Drift** | Any time Git and the cluster don't match. Usually caused by someone changing the cluster by hand. |
| **Sync** | Making the cluster match Git. Can be done manually or automatically. |
| **Synced / OutOfSync** | Do Git and the cluster match right now? This has nothing to do with whether the app is working. |
| **Healthy / Progressing / Degraded** | Is the app actually working (Pods running, Service reachable)? This has nothing to do with whether it matches Git. |
| **Application (CRD)** | ArgoCD's own object. It tells ArgoCD what to deploy (a Git repo + folder) and where (a cluster + namespace). |
 
`Synced` and `Healthy` are two different questions. An app can be:
 
- `Healthy` but `OutOfSync` — it works fine, but someone changed
  something in the cluster without using Git.
- `Synced` but `Degraded` — Git and the cluster match, but the app is
  broken anyway (e.g. the container is crashing).
## Contents
 
| File | What it covers |
|---|---|
| [01-installing-argocd.md](01-installing-argocd.md) | Installing ArgoCD with Helm, opening the UI, setting up the CLI. |
| [02-connecting-to-git.md](02-connecting-to-git.md) | Connecting ArgoCD to a Git repository. |
| [03-first-application.md](03-first-application.md) | Deploying an app with an `Application` file. |
| [04-app-of-apps.md](04-app-of-apps.md) | Managing many apps with the App of Apps pattern. |
| [05-sync-policies.md](05-sync-policies.md) | Manual vs. automatic sync, self-healing, pruning. |
| [06-troubleshooting.md](06-troubleshooting.md) | Problems found while building this module, and how to fix them. |
 
## Architecture
 
```
Git repository (source of truth)
      │
      ▼
   ArgoCD  ──── watches the repo, finds drift
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
- A Git repository (GitHub, GitLab, etc.) with the Kubernetes files to
  manage.
## Screenshots
 
Save screenshots to `images/` with clear names, for example:
`images/argocd-ui-login.png`, `images/argocd-app-synced.png`.