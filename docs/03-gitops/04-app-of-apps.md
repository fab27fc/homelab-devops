# 04 — App of Apps Pattern
 
## Objective
 
Manage the list of ArgoCD `Application` files through Git too, so
adding, removing, or changing which apps ArgoCD manages doesn't need a
manual `kubectl apply` anymore — just a commit to a folder in the repo.
 
## The problem this solves
 
Managing one `Application` file with `kubectl apply` works fine for a
single app, but it doesn't scale. It also leaves the *list* of
Applications outside Git — each app's content is tracked, but the set
of apps ArgoCD manages is not. The **App of Apps** pattern fixes this:
one root Application whose only job is to deploy other Application
files.
 
## Concept
 
```
Git repository
      │
      ▼
apps-root  (its own file lives in 03-gitops/applications/root-app.yaml)
      │
      ▼
03-gitops/argocd-apps/  (the folder apps-root watches)
      │
      ├── nginx-demo-app.yaml
      ├── monitoring-app.yaml   (future: bring 02-monitoring under GitOps)
      └── ...
```
 
With this pattern, adding a new app to the cluster just means
committing a new `Application` file to `03-gitops/argocd-apps/` —
nothing else needed.
 
## File locations
 
- `root-app.yaml` lives in `03-gitops/applications/root-app.yaml`.
- The folder it watches is `03-gitops/argocd-apps/`, which holds the
  other Application files (such as `nginx-demo-app.yaml`).
- These are two different folders on purpose: `apps-root` is set to
  `path: 03-gitops/argocd-apps`, so keeping its own file outside that
  folder means it never tries to manage itself.
## Step 1 — Create the root Application
 
`03-gitops/applications/root-app.yaml`:
 
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<user>/<repo>.git
    targetRevision: main
    path: 03-gitops/argocd-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
 
The root Application uses automatic sync. Since it only contains other
Application files, this is lower risk than auto-syncing actual workload
changes.
 
## Step 2 — Bootstrap it (one-time step)
 
```bash
kubectl apply -f 03-gitops/applications/root-app.yaml
```
 
## Step 3 — Confirm the child apps were picked up
 
```bash
argocd app list
```
 
Expected: both `apps-root` and `nginx-demo` (from
[03-first-application.md](03-first-application.md)) show up, with
`nginx-demo` now managed by `apps-root` instead of applied by hand.
 
> 📸 **Screenshot: `images/argocd-app-of-apps-tree.png`**
> Place here, right after this step.
> Command to capture: none — open the ArgoCD web UI, select the
> `apps-root` application, and screenshot the tree view showing
> `nginx-demo` nested under it.
>
> ![App of Apps tree view](images/argocd-app-of-apps-tree.png)
 
## Adding a new application from here on
 
From this point on, deploying a new app doesn't need a manual
`kubectl apply` at all:
 
```
Create a new *-app.yaml in 03-gitops/argocd-apps/
      │
      ▼
git add / commit / push
      │
      ▼
apps-root notices the new file
      │
      ▼
ArgoCD creates the Application automatically
```
 
## Why this pattern is used
 
Platform teams use this to add new services without giving every team
direct cluster access — new apps are added through Git, and ArgoCD
enforces what actually gets deployed.