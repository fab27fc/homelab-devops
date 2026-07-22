# Lesson 8 — Secrets

## Objective

Learn how Kubernetes stores and delivers sensitive information: database
passwords, API keys, OAuth tokens, TLS certs, SSH keys.

## ConfigMap vs. Secret

```
                 Application
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
   ConfigMap                 Secret
```

| Use a ConfigMap for | Use a Secret for |
|---|---|
| Application name, environment, log level, feature flags, URLs, ports | Passwords, API keys, tokens, certificates, private keys |

This distinction is one of the most common Kubernetes interview questions.

### Important: Secrets are base64, not encrypted

```
Password → Base64 → stored in etcd
```

Base64 is an *encoding*, not encryption — anyone with API access to read
the Secret can trivially decode it. In production, pair Secrets with:

- etcd encryption at rest
- RBAC restricting who/what can `get`/`list` Secrets
- A dedicated secrets manager (AWS Secrets Manager, HashiCorp Vault, Azure
  Key Vault, …) for anything beyond lab use

## Manifest

[`kubernetes/secrets-templates/database-secret.example.yaml`](../kubernetes/secrets-templates/database-secret.example.yaml)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
  namespace: applications
type: Opaque
stringData:
  DATABASE_USER: admin
  DATABASE_PASSWORD: SuperSecret123
```

> ⚠️ **Security note:** the credentials above are lab-only dummy values,
> intentionally committed as a *documented example* of the manifest shape.
> Never commit real credentials to any git repository — even a private
> one. If you reuse this repo as a template, swap these for placeholder
> values and inject real secrets at deploy time (Vault, Sealed Secrets,
> `kubectl create secret` run out-of-band, CI/CD secret injection, etc.).

`stringData` is easier to read/write than pre-encoding to `data:` —
Kubernetes base64-encodes it automatically on creation.

`type: Opaque` is the default, arbitrary key/value Secret type. Other
built-in types: `kubernetes.io/tls`, `kubernetes.io/dockerconfigjson`,
`kubernetes.io/basic-auth`.

```bash
cd ~/enterprise-kubernetes-platform/manifests/secrets
kubectl apply --dry-run=client -f database-secret.yaml
kubectl apply -f database-secret.yaml

kubectl get secrets -n applications
kubectl describe secret database-secret -n applications
```

`describe` only shows key names and byte sizes — never the actual values.

## Using a ConfigMap **and** a Secret together in a Pod

[`kubernetes/pods/config-secret-pod.yaml`](../kubernetes/pods/config-secret-pod.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-secret-pod
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
        - secretRef:
            name: database-secret
```

```
                  Pod
                   │
      ┌────────────┴────────────┐
      ▼                         ▼
 ConfigMap                  Secret
      │                         │
      ▼                         ▼
Environment Variables      Environment Variables
      │                         │
      └────────────┬────────────┘
                    ▼
              Application
```

```bash
cd ~/enterprise-kubernetes-platform/manifests/pods
kubectl apply --dry-run=client -f config-secret-pod.yaml
kubectl apply -f config-secret-pod.yaml
kubectl get pods -n applications

kubectl exec -it config-secret-pod -n applications -- sh
printenv | grep APP
printenv | grep ENV
printenv | grep LOG
printenv | grep DATABASE_USER
printenv | grep DATABASE_PASSWORD
exit
```

Expected:

```
APP_NAME=Enterprise Kubernetes Platform
ENVIRONMENT=Development
LOG_LEVEL=INFO
DATABASE_USER=admin
DATABASE_PASSWORD=SuperSecret123
```

The application sees a flat set of environment variables and has no idea
which came from a ConfigMap vs. a Secret — that separation exists purely
for how *Kubernetes* stores and protects the data, not for the app.

## Screenshots needed

- [ ] `docs/images/kubernetes/08-secret-describe.png` — `kubectl describe secret
      database-secret -n applications` (sizes only, no plaintext values).
- [ ] `docs/images/kubernetes/08-secret-printenv.png` — `printenv` inside
      `config-secret-pod` showing both ConfigMap and Secret-derived vars.

## Interview answer — "why shouldn't passwords live in a ConfigMap?"

> ConfigMaps are meant for non-sensitive configuration. Sensitive data —
> passwords, API keys, tokens, certificates — belongs in Secrets so it can
> be managed and access-controlled separately (RBAC, encryption at rest,
> external secret managers) from ordinary configuration.

## Foundation complete ✅

At this point the core Kubernetes objects used in almost every cluster are
covered: Namespaces, Pods, ReplicaSets, Deployments, Rolling Updates,
Rollbacks, Services, Ingress, PersistentVolumes/Claims, ConfigMaps, Secrets.

Next: Phase 2 — deploying real, production-grade software via Helm. See
[`09-helm-prometheus-grafana.md`](09-helm-prometheus-grafana.md).
