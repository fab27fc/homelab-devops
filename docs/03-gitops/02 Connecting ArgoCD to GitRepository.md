# 02 — Connecting ArgoCD to a Git Repository
 
## Objective
 
Register a Git repository with ArgoCD, so it can be used as the source
for `Application` files. Then check the connection works before
depending on it in later steps.
 
## What this step is for
 
ArgoCD can't read a repository unless you tell it to first. Registering
a repo saves the URL and the login details ArgoCD should use, so the
`argocd-repo-server` part (see
[01-installing-argocd.md](01-installing-argocd.md)) can pull files
without asking for credentials every time.
 
## What ArgoCD does once a repository is registered
 
Once registered, ArgoCD keeps comparing the files in the repo (what you
**want**) against what's actually running in the cluster (what you
**have**):
 
```
Git repository
      │
      ▼
 Read the manifest
      │
      ▼
Compare with the live cluster resource
      │
      ▼
   Are they the same?
```
 
Example, using a Deployment with `replicas: 3` saved in Git:
 
| Situation | Git (what you want) | Cluster (what's live) | Result |
|---|---|---|---|
| No drift | `replicas: 3` | `replicas: 3` | `Synced` / `Healthy` — nothing happens. |
| Drift (e.g. someone runs `kubectl scale deployment nginx --replicas=10`) | `replicas: 3` | `replicas: 10` | `OutOfSync` — if auto-sync is on, ArgoCD reapplies the file and puts it back to `replicas: 3`. |
 
This is what makes Git the real source of truth, not just a place
where changes get written down after the fact. The repo registered in
this step is how ArgoCD knows what "correct" looks like. A hands-on
demo of this drift/fix cycle is in
[05-sync-policies.md](05-sync-policies.md#self-healing).
 
## Key idea: how ArgoCD logs in to Git
 
ArgoCD can connect to a repo two ways: HTTPS with a username/token, or
SSH with a key. This guide uses HTTPS with a Personal Access Token
(PAT), because it's the simplest to set up, and it works the same way
whether the repo is public or private. The token is what ArgoCD shows
GitHub instead of a password when it runs `git clone` or `git fetch`.
 
## Step 1 — Create a GitHub Personal Access Token (PAT)
 
Using a token is the normal approach, even for public repos. It avoids
GitHub's limits on unauthenticated requests, and it's required for
private repos.
 
1. On GitHub, open the profile menu (top right) → **Settings**.
2. In the left menu, scroll down to **Developer settings**.
3. Open **Personal access tokens → Fine-grained tokens**.
4. Click **Generate new token**.
Recommended settings:
 
| Field | Value |
|---|---|
| Token name | Something clear, e.g. `ArgoCD Homelab` |
| Expiration | 90 days (or shorter) |
| Repository access | `Only select repositories` |
| Selected repository | The one repo being registered |
| Repository permissions | `Contents: Read-only` |
 
`Contents: Read-only` is enough — ArgoCD only reads files, it never
writes to the repo.
 
5. Click **Generate token**.
6. GitHub shows the token once, in a format like:
```
   github_pat_11ABCDEFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
 
7. Copy it right away. GitHub won't show it again — if it's lost, a
   new one has to be created.
## Step 2 — Register the repository
 
Load the token into a variable instead of typing it straight into the
command. This keeps it out of the shell history:
 
```bash
read -s -p "GitHub token: " GITHUB_TOKEN
echo
```
 
Nothing shows on screen while typing or pasting — that's normal.
 
Register the repo with the CLI:
 
```bash
argocd repo add https://github.com/<user>/<repo>.git \
  --username <user> \
  --password "$GITHUB_TOKEN"
```
 
Or from the UI: **Settings → Repositories → Connect Repo → HTTPS**.
 
## Step 3 — Check the connection
 
```bash
argocd repo list
```
 
Expected: a `Successful` status for the repo.
 
> 📸 **Screenshot: `images/argocd-repo-connected.png`**
> Place here, right after this step.
> Command to capture: `argocd repo list` (CLI output), or go to
> **Settings → Repositories** in the UI and screenshot the connection
> status.
>
> ![Repository connected successfully](images/argocd-repo-connected.png)
 
## Public vs. private repositories
 
Whether a token is needed depends on the repo's visibility:
 
| Repo visibility | What's needed |
|---|---|
| Private | A PAT (or SSH key) is required — ArgoCD can't clone a private repo without it. |
| Public | No credentials are strictly required. |
 
For a public repo, it can be registered without a token:
 
```bash
argocd repo add https://github.com/<user>/<repo>.git
```
 
```bash
argocd repo list
```
 
A `Successful` status confirms it worked, with no PAT involved.
 
**Using a PAT even for a public repo is still the better choice**, for
three reasons:
 
- It's the exact same process needed for private repos — no rework
  later if the repo becomes private.
- It avoids GitHub's lower limits for requests without a token.
- It matches how ArgoCD connects to Git in most companies, where repos
  are private and access uses a PAT, SSH key, or GitHub App.
This is why
[Step 1](#step-1--create-a-github-personal-access-token-pat) and
[Step 2](#step-2--register-the-repository) use a PAT by default, even
though it's not strictly required for a public repo.
 
## What's next
 
With the repo registered, changes no longer reach the cluster through
`kubectl apply`. The new workflow is:
 
```
Edit manifest
   │
   ▼
git add / commit / push
   │
   ▼
ArgoCD sees the change in the repository
   │
   ▼
Cluster is synced to match
```
 
[03-first-application.md](03-first-application.md) creates the first
`Application` and puts this workflow into practice.
 
## Command reference
 
```bash
read -s -p "GitHub token: " GITHUB_TOKEN
echo
 
argocd repo add https://github.com/<user>/<repo>.git \
  --username <user> \
  --password "$GITHUB_TOKEN"
 
argocd repo list
```
 









