# 06 — Troubleshooting

## Objective

Keep a running log of problems found while using this module, so the
next time one shows up, it can be fixed fast instead of re-diagnosed
from scratch.

This uses the same format as `02-monitoring-platform/07-troubleshooting.md`:
symptom, cause, fix. The entries below cover the most common problems
at each step. Add more as new ones come up.

---

## 1. Helm release stuck in `failed` status

**Symptom:**

```
helm status argocd -n argocd
```

shows:

```
STATUS: failed
```

even though some ArgoCD Pods look like they're running.

**Cause:** the install stopped partway through — usually because one
of the resources it tried to create clashed with something already in
the cluster (see issue 2 below for the most common case). The Pods
that exist were created before it failed. The rest (like the
`argocd-server` Service) never got created, which is why
`kubectl get svc argocd-server -n argocd` can say
`services "argocd-server" not found` at the same time.

**Fix:** fix the actual cause first, then run the install again with
the corrected `custom-values.yaml`:

```bash
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f custom-values.yaml
```

`helm upgrade --install` is safe to run more than once — it fixes a
broken release, or creates a new one if there isn't one yet. So this is
the right command any time the release needs fixing, not just for the
first install (see
[01-installing-argocd.md, Step 6](01-installing-argocd.md#step-6--install)).

Check it worked:

```bash
helm status argocd -n argocd
kubectl get pods -n argocd
kubectl get svc -n argocd
```

---

## 2. A port is already used by another Service

**Symptom:** the Helm release fails, and either the error message or
`kubectl describe svc argocd-server` points to a port conflict.

**Cause:** `custom-values.yaml` asks for fixed ports (`30081`/`30444`).
If another Service is already using one of them, Kubernetes rejects the
new one.

**Fix:** check which ports are actually free before installing:

```bash
kubectl get svc -A \
  -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,NODEPORTS:.spec.ports[*].nodePort' \
  | grep -E '30081|30444'
```

If either port shows up, pick different numbers in
`custom-values.yaml`, then re-run the install command from issue 1.

---

## 3. `Argo CD server address unspecified`

**Symptom:** any `argocd` CLI command (like `argocd app list`) fails
with:

```
FATA[0000] Argo CD server address unspecified
```

**Cause:** the CLI was never logged in. `argocd login` sets the server
address and session used by every command after it. This has nothing
to do with whether ArgoCD itself is healthy — it just means this
terminal session never logged in.

**Fix:**

```bash
argocd login <node-ip>:30081 --insecure
```

If this also fails, check the Service exists first
(`kubectl get svc argocd-server -n argocd`) — a missing Service usually
means the Helm release is in the state from issue 1.

---

## 4. `argocd account update-password` fails

**Symptom:**

```
FATA[0000] rpc error: code = InvalidArgument desc = ...
```

or a similar login error when running
`argocd account update-password`.

**Cause:** usually a typo in `--current-password` — the first admin
password (from
[01-installing-argocd.md, Step 9](01-installing-argocd.md#step-9--get-the-initial-admin-password))
is long and easy to mistype.

**Fix:** load the password into a variable instead of typing it, so
it's used exactly as it was retrieved:

```bash
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)

argocd account update-password \
  --current-password "$ARGO_PASSWORD" \
  --new-password "$NEW_ARGO_PASSWORD"
```

Full steps in
[01-installing-argocd.md, Step 13](01-installing-argocd.md#step-13--change-the-admin-password).

---

## 5. `argocd repo list` shows the repo as unreachable

**Cause:** the Personal Access Token is missing the right permission,
or it expired.

**Fix:** make a new fine-grained PAT scoped to the repo with
`Contents: Read-only`, then:

```bash
argocd repo rm https://github.com/<user>/<repo>.git
argocd repo add https://github.com/<user>/<repo>.git \
  --username <user> \
  --password <new-token>
```

---

## 6. Application stuck in `Progressing`, never reaches `Healthy`

**Cause:** the resource itself isn't healthy (e.g. the Pod is in
`CrashLoopBackOff`). ArgoCD is just showing Kubernetes' own state —
this isn't a GitOps-specific problem.

**Fix:** debug the resource directly:

```bash
kubectl describe pod <pod-name> -n applications
kubectl logs <pod-name> -n applications
```

---

## 7. ArgoCD still shows an outdated value after a Git push

**Symptom:** `argocd app diff <app-name>` shows a difference (like an
old image tag), even though the file was already committed and pushed,
and both the local file and `origin/main` already show the new value.

**Cause:** `argocd-repo-server` caches the last commit it read, and
doesn't always re-check on every command. This is different from the
file itself being wrong — check where the old value actually lives
first.

**Check these, in order:**

```bash
# 1. What the local file actually says
grep image path/to/deployment.yaml

# 2. What commit last changed that file
git log --oneline -- path/to/deployment.yaml

# 3. What the remote branch actually has, without opening a browser
git show origin/main:path/to/deployment.yaml | grep image
```

If step 3 still shows the old value, it was never pushed — commit and
`git push origin main`, then try again. If steps 1–3 all show the
right value but ArgoCD still shows the old one, it's a stale cache.

**Fix:**

```bash
# Force ArgoCD to re-read the repo instead of using its cache
argocd app get <app-name> --hard-refresh
argocd app diff <app-name>
```

If the diff is correct now:

```bash
argocd app sync <app-name>
argocd app wait <app-name> --sync --health --timeout 120
argocd app get <app-name>
```

Expected result:

```
Sync Status:   Synced
Health Status: Healthy
```

If it still shows an old commit after a hard refresh, restart the part
that reads the repo:

```bash
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd

argocd app get <app-name> --hard-refresh
argocd app sync <app-name>
argocd app wait <app-name> --sync --health --timeout 120
```

To check ArgoCD and Git agree on the exact commit:

```bash
git fetch origin
git rev-parse --short origin/main
argocd app get <app-name>   # compare the revision shown here
```

---

## 8. `OutOfSync` right after a successful sync

**Cause:** something changes a field after ArgoCD applies it (a
mutating webhook, a default value, or an HPA changing `replicas`).
ArgoCD compares live vs. Git field by field, so it notices.

**Fix:** ignore that specific field using `spec.ignoreDifferences` in
the Application file, or just confirm it's expected (e.g. an
HPA-managed `replicas` field is supposed to differ from the file).

---

## 9. Self-healing doesn't trigger

**Cause:** `selfHeal: true` isn't actually set on the running
Application. Check:

```bash
argocd app get nginx-demo -o yaml | grep -A3 automated
```

**Fix:** make sure the change was committed, pushed, and synced. If
the parent app (`apps-root`) is on automatic sync, it can take up to
one polling interval (3 minutes by default) to notice. Force it with:

```bash
argocd app sync apps-root
```

---

## 10. `Sync Policy` still shows `Manual` after enabling automated sync

**Symptom:**

```bash
argocd app get nginx-demo
```

still shows:

```
Sync Policy: Manual
```

even after adding `automated:` to `nginx-demo-app.yaml`, committing,
and pushing.

**Cause:** almost always a YAML indentation mistake — `prune` and
`selfHeal` have to be nested inside `automated:`, which itself has to
be nested inside `syncPolicy:`. A common mistake is putting one of
these keys one level too shallow or too deep, which either gets
ignored or breaks the file silently for that section:

```yaml
# Correct
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

**Fix:** check the file's indentation matches the example above, then
confirm the committed version is what ArgoCD is actually reading:

```bash
git show origin/main:03-gitops/argocd-apps/nginx-demo-app.yaml
```

If the file itself is correct but the Application still shows
`Manual`, the parent app (`apps-root`) may not have picked up the
change yet — see issue 9 above.

---

## 11. Deleting a manifest from Git doesn't remove the resource

**Symptom:** a file (e.g. a Service) is deleted from Git, committed,
and pushed, but the matching resource is still running in the cluster.

**Cause:** one of two things:

- `prune: true` isn't set on the Application, so ArgoCD is intentionally
  leaving resources alone that disappear from Git (the safer default).
- The Application is on manual sync, and no sync has actually run
  since the file was deleted.

**Fix:** confirm pruning is enabled:

```bash
argocd app get nginx-demo -o yaml | grep -A3 automated
```

If `prune: true` is missing, add it (see issue 10 above for the
correct nesting). Then trigger a sync and confirm the resource is
gone:

```bash
argocd app sync nginx-demo
kubectl get svc -n applications
```

---

## Useful commands for finding files in this module

```bash
# Find a specific file anywhere in the home directory
find ~ -name "custom-values.yaml"

# Find any file related to ArgoCD
find ~ -iname "*argocd*"

# Search file contents for a string within a directory
grep -R "text" directory/
```

---

## Additional entries

```
## N. <short description of the issue>

**Symptom:**

**Cause:**

**Fix:**
```