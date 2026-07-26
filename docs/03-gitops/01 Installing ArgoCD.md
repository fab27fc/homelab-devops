# 01 — Installing ArgoCD
 
## Objective
 
Install ArgoCD on the cluster, and check it works from both the web UI
and the command line. Later steps need this to register a repository
and deploy an app.
 
## What ArgoCD needs to run
 
ArgoCD is not one program. It's a group of parts that each do one job:
 
| Component | Job |
|---|---|
| `argocd-server` | Runs the web UI and the API the CLI talks to. |
| `argocd-repo-server` | Downloads the Git repo and reads the manifests (plain YAML, Helm, Kustomize). |
| `argocd-application-controller` | Keeps checking: does each `Application` match Git? |
| `argocd-applicationset-controller` | Creates `Application` resources from templates (not used in this basic setup). |
| `argocd-dex-server` | Handles login (local users by default, SSO optional). |
| `argocd-redis` | A cache used internally by the other parts. |
 
## Where each part runs
 
ArgoCD has two separate pieces, and they run in two different places.
Mixing them up is a common cause of `connection refused` or
`server address unspecified` errors later:
 
```
ArgoCD server (the parts in the table above)
   → Runs as Pods inside the Kubernetes cluster
 
argocd CLI
   → Installed on the management machine you use to run
     kubectl, Helm, Terraform, and Ansible
```
 
The Helm install below sets up the cluster side. The CLI install in
[Step 11](#step-11--install-the-argocd-cli) is a separate, extra install
on the management machine — Helm does not install the CLI for you.
 
## Where the files live
 
`values.yaml` and `custom-values.yaml` live inside the Git repo, not in
some other folder outside of Git. This way, every change to ArgoCD's
setup is tracked, just like the apps ArgoCD will manage:
 
```
homelab-devops/
└── 03-gitops/
    └── argocd/
        ├── values.yaml
        ├── custom-values.yaml
        ├── README.md
        └── images/
```
 
Installing with Helm follows the same steps used for other apps on
this cluster: find the official chart, download its default values,
change only what's needed, install, then check it worked.
 
## Step 1 — Create the namespace
 
```bash
kubectl create namespace argocd
```
 
## Step 2 — Add the Argo Helm repository
 
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm search repo argo/argo-cd
```
 
## Step 3 — Download the default values
 
```bash
cd ~/homelab-devops/03-gitops/argocd
 
helm show values argo/argo-cd > values.yaml
```
 
## Step 4 — Check the required ports are free
 
This setup uses two fixed ports, `30081` and `30444` (set in the next
step). Before installing, check nothing else is already using them:
 
```bash
kubectl get svc -A \
  -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,NODEPORTS:.spec.ports[*].nodePort' \
  | grep -E '30081|30444'
```
 
No output means both ports are free. If one shows up, pick a different
port number in `custom-values.yaml` before continuing. Reusing a port
another Service already uses will make the Helm install fail.
 
## Step 5 — Edit `custom-values.yaml`
 
For a homelab, the settings worth changing are:
 
- The service type, so the UI can be reached without `port-forward`.
- Fixed ports, so the URL stays the same every time.
- Insecure mode, so the browser doesn't warn about the self-signed
  certificate. In production, a real certificate would be used instead
  of turning this off.
```yaml
server:
  extraArgs:
    - --insecure
 
  service:
    type: NodePort
    nodePortHttp: 30081
    nodePortHttps: 30444
```
 
## Step 6 — Install
 
```bash
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f custom-values.yaml
```
 
`helm upgrade --install` is used instead of plain `helm install`. It
installs ArgoCD if it's not there yet, or upgrades it if it already is.
This means the same command can be run again any time
`custom-values.yaml` changes — no separate repair step needed.
 
## Step 7 — Check the Helm release
 
```bash
helm status argocd -n argocd
```
 
Expected:
 
```
STATUS: deployed
```
 
If it says `STATUS: failed`, the install didn't finish — see
[06-troubleshooting.md](06-troubleshooting.md#1-helm-release-stuck-in-failed-status)
before moving on.
 
## Step 8 — Check the installation
 
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```
 
All of these Pods should be `Running`:
 
- `argocd-server`
- `argocd-repo-server`
- `argocd-application-controller`
- `argocd-applicationset-controller`
- `argocd-dex-server`
- `argocd-redis`
- `argocd-notifications-controller`
The `argocd-server` Service should look like:
 
```
argocd-server   NodePort   ...   80:30081/TCP,443:30444/TCP
```
 
> 📸 **Screenshot: `images/argocd-pods-running.png`**
> Place here, right after this step.
> Command to capture: `kubectl get pods -n argocd`
>
> ![All ArgoCD pods running](images/argocd-pods-running.png)
 
## Step 9 — Get the initial admin password
 
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```
 
Username: `admin`.
 
This password is only meant for the first login, in
[Step 10](#step-10--open-the-ui) and [Step 12](#step-12--log-in-with-the-cli).
[Step 13](#step-13--change-the-admin-password) replaces it with
a permanent one, once the CLI is installed and logged in.
 
## Step 10 — Open the UI
 
`custom-values.yaml` sets `--insecure` and a fixed HTTP port, so the UI
can be opened over plain HTTP:
 
```
http://<node-ip>:30081
```
 
> 📸 **Screenshot: `images/argocd-ui-login.png`**
> Place here, right after this step.
> Command to capture: none — open the URL above in a browser and take
> a screenshot of the login page.
>
> ![ArgoCD web UI login screen](images/argocd-ui-login.png)
 
## Step 11 — Install the ArgoCD CLI
 
Run these commands on the **management machine**, not on the
Kubernetes node. The CLI just talks to `argocd-server` over the
network — it doesn't need to run inside the cluster.
 
Check the CPU type first, since the right file to download depends on
it:
 
```bash
dpkg --print-architecture
```
 
On a normal Intel/AMD machine, this returns:
 
```
amd64
```
 
Download and install the CLI:
 
```bash
curl -sSL -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
 
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
 
rm argocd-linux-amd64
```
 
Check it worked:
 
```bash
argocd version --client
```
 
The CLI is needed for commands like `argocd login`, `argocd app sync`,
and `argocd account update-password`, used through the rest of this
module.
 
## Step 12 — Log in with the CLI
 
```bash
argocd login <node-ip>:30081 --insecure
```
 
Enter `admin` and the password from Step 9.
 
If this or a later command shows
`Argo CD server address unspecified`, this login step was skipped, or
the session expired — see
[06-troubleshooting.md](06-troubleshooting.md#3-argo-cd-server-address-unspecified).
 
## Step 13 — Change the admin password
 
The password from Step 9 is temporary. It should be replaced with a
permanent one right after the first login. Loading it into a variable,
instead of typing it by hand, avoids the most common mistake here — a
typo in the current password.
 
Load the current password into a variable:
 
```bash
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)
```
 
Check it loaded:
 
```bash
test -n "$ARGO_PASSWORD" && echo "Initial password loaded"
```
 
Ask for a new password, without showing it on screen:
 
```bash
read -s -p "New ArgoCD password: " NEW_ARGO_PASSWORD
echo
```
 
Change it:
 
```bash
argocd account update-password \
  --current-password "$ARGO_PASSWORD" \
  --new-password "$NEW_ARGO_PASSWORD"
```
 
Expected:
 
```
Password updated
```
 
Check the new password works by logging out and back in:
 
```bash
argocd logout <node-ip>:30081
 
argocd login <node-ip>:30081 \
  --username admin \
  --password "$NEW_ARGO_PASSWORD" \
  --insecure
```
 
Expected:
 
```
'admin:login' logged in successfully
```
 
Once this works, the old Secret isn't needed anymore. Delete it so it
can't be used to log in again:
 
```bash
kubectl delete secret argocd-initial-admin-secret -n argocd
```
 
## Command reference
 
```bash
# Namespace
kubectl create namespace argocd
 
# Repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
 
# Values
helm show values argo/argo-cd > values.yaml
 
# Check ports are free
kubectl get svc -A \
  -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,NODEPORTS:.spec.ports[*].nodePort' \
  | grep -E '30081|30444'
 
# Install / repair (safe to re-run)
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f custom-values.yaml
 
# Check it worked
helm status argocd -n argocd
kubectl get pods -n argocd
kubectl get svc -n argocd
 
# Admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
 
# CLI (on the management machine)
dpkg --print-architecture
curl -sSL -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
argocd version --client
 
# CLI login
argocd login <node-ip>:30081 --insecure
 
# Change the admin password
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)
read -s -p "New ArgoCD password: " NEW_ARGO_PASSWORD; echo
argocd account update-password \
  --current-password "$ARGO_PASSWORD" \
  --new-password "$NEW_ARGO_PASSWORD"
 
# Check the new password, then remove the old secret
argocd logout <node-ip>:30081
argocd login <node-ip>:30081 --username admin --password "$NEW_ARGO_PASSWORD" --insecure
kubectl delete secret argocd-initial-admin-secret -n argocd
```