# Lesson 7 — ConfigMaps

## Objective

Separate configuration from application code — one of the
[12-Factor App](https://12factor.net/config) principles, and standard
practice for every real Kubernetes deployment.

## The problem

Hardcoding values like a database host, database name, or log level inside
an application image means every config change requires a rebuild and
redeploy.

## Theory

```
Application
      │
      ▼
   ConfigMap
      │
      ▼
Configuration Values (non-sensitive)
```

Real-world examples of things commonly stored in ConfigMaps: `prometheus.yml`,
`grafana.ini`, `argocd-cm`, `nginx.conf`.

Two ways applications consume a ConfigMap:

1. **Environment variables** — `ConfigMap → env vars → application` (used
   in this lesson).
2. **Mounted files** — `ConfigMap → volume → /etc/config/...` (common for
   NGINX, Prometheus, Grafana, Fluentd config files).

## Manifest

[`kubernetes/configmaps/app-config.yaml`](../kubernetes/configmaps/app-config.yaml)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: applications
data:
  APP_NAME: Enterprise Kubernetes Platform
  ENVIRONMENT: Development
  LOG_LEVEL: INFO
```

Everything under `data:` becomes a config value; `APP_NAME` becomes
`APP_NAME=Enterprise Kubernetes Platform` once injected into a container.

```bash
cd ~/enterprise-kubernetes-platform/manifests/configmaps
kubectl apply --dry-run=client -f app-config.yaml
kubectl apply -f app-config.yaml

kubectl get configmaps -n applications
kubectl describe configmap app-config -n applications
```

### Creating a ConfigMap imperatively (CLI, no YAML)

```bash
kubectl create configmap miconfig \
  --from-literal=app-color=blue \
  --from-literal=app-mode=production

kubectl get configmap miconfig
kubectl get configmap miconfig -o yaml
```

Useful for quick one-offs; for anything checked into git, prefer a
declarative manifest like `app-config.yaml` above.

## Using the ConfigMap inside a Pod

[`kubernetes/pods/configmap-pod.yaml`](../kubernetes/pods/configmap-pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
  namespace: applications
spec:
  containers:
    - name: busybox
      image: busybox
      command:
        - sleep
        - "3600"
      envFrom:
        - configMapRef:
            name: app-config
```

`envFrom.configMapRef` imports **every** key in the ConfigMap as an
environment variable — the application has no idea Kubernetes exists; it
just sees env vars.

```bash
cd ~/enterprise-kubernetes-platform/manifests/pods
kubectl apply --dry-run=client -f configmap-pod.yaml
kubectl apply -f configmap-pod.yaml
kubectl get pods -n applications

kubectl exec -it configmap-pod -n applications -- sh
printenv | grep APP
printenv | grep ENV
printenv | grep LOG
exit
```

Expected:

```
APP_NAME=Enterprise Kubernetes Platform
ENVIRONMENT=Development
LOG_LEVEL=INFO
```

```
ConfigMap
      │
      ▼
Environment Variables
      │
      ▼
Container
      │
      ▼
Application
```

Same pattern real frameworks rely on — Spring Boot's `DATABASE_URL`,
Node's `NODE_ENV`/`PORT`, ASP.NET Core's `ASPNETCORE_ENVIRONMENT`, etc.

## Screenshots needed

- [ ] `docs/images/kubernetes/07-configmap-describe.png` — `kubectl describe
      configmap app-config -n applications`.
- [ ] `docs/images/kubernetes/07-configmap-printenv.png` — `printenv` inside
      `configmap-pod` showing the three injected variables.

## Interview answer — "why store config in a ConfigMap instead of
hardcoding it?"

> Configuration changes frequently, while application code shouldn't.
> ConfigMaps let you update configuration independently of the container
> image, making deployments more flexible and the image reusable across
> environments (dev/staging/prod) without a rebuild.

## Next

ConfigMaps are for **non-sensitive** values only. Passwords, tokens, and
keys go in [`08-secrets.md`](08-secrets.md).
