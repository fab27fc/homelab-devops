# Lesson 5 — Ingress

## Objective

Move from `http://192.168.100.20:30080` (one NodePort per app — doesn't
scale past a handful of services) to `http://nginx.lab.local` — a single
entry point that routes by hostname/path, the way production clusters do.

## Theory

A **Service** load-balances traffic to Pods. An **Ingress** decides *where*
HTTP(S) requests should go before they even reach a Service — an HTTP
reverse proxy / router in front of your Services.

```
Without Ingress                  With Ingress
Laptop                           Laptop
  │                                │
  ▼                                ▼
NodePort                    Ingress Controller
  │                                │
  ▼                                ▼
Service                     Ingress Rules
  │                                │
  ▼                                ▼
Pods                           Service
                                    │
                                    ▼
                                  Pods
```

Two separate pieces:

1. **Ingress Controller** — the actual software that processes requests
   (NGINX Ingress Controller, Traefik, HAProxy, AWS LB Controller, …).
   Without a controller running, `Ingress` objects do nothing.
2. **Ingress resource** — a YAML object with routing rules, e.g. "if
   `Host == nginx.lab.local`, send to `nginx-service`."

Ingress does **not** replace Services — the correct chain is always
`Ingress → Service → Pods`.

## Step 1 — install the NGINX Ingress Controller (via Helm)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx

kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## Step 2 — create the Ingress resource

[`kubernetes/ingress/nginx-ingress.yaml`](../kubernetes/ingress/nginx-ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: applications
spec:
  ingressClassName: nginx
  rules:
    - host: nginx.lab.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

Note the backend points at `nginx-service` — never directly at Pods.

```bash
cd ~/enterprise-kubernetes-platform/manifests/ingress
kubectl apply --dry-run=client -f nginx-ingress.yaml
kubectl apply -f nginx-ingress.yaml

kubectl get ingress -n applications
kubectl describe ingress nginx-ingress -n applications
```

`describe` should show the rule:

```
Host: nginx.lab.local  →  Service: nginx-service:80
```

## Step 3 — local DNS via hosts file

The cluster now knows how to route `nginx.lab.local`, but your laptop
doesn't know what IP that hostname maps to — that needs a `/etc/hosts`
entry (or real DNS in a non-lab environment).

**Windows** (`C:\Windows\System32\drivers\etc\hosts`) or **Ubuntu**
(`sudo nano /etc/hosts`):

```
192.168.100.20 nginx.lab.local
```

Verify:

```bash
ping nginx.lab.local
# PING nginx.lab.local (192.168.100.20)
```

## Step 4 — test

```bash
curl http://nginx.lab.local
```

or open `http://nginx.lab.local` in a browser. Expected: `Welcome to
nginx!`.

```
                 Browser
                     │
                     ▼
          http://nginx.lab.local
                     │
                     ▼
          Ingress Controller
                     │
                     ▼
            nginx-ingress
                     │
                     ▼
             nginx-service
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
        Pod 1      Pod 2      Pod 3
```

## Platform convention going forward

Every future application in this repo gets its own hostname behind the
**same** Ingress Controller — one controller reused across the whole
platform, exactly like production:

- `nginx.lab.local` → NGINX
- `grafana.lab.local` → Grafana
- `prometheus.lab.local` → Prometheus
- `argocd.lab.local` → ArgoCD

## Screenshots needed

- [ ] `docs/images/kubernetes/05-ingress-controller-pods.png` — `kubectl get pods -n ingress-nginx`
      + `kubectl get svc -n ingress-nginx`.
- [ ] `docs/images/kubernetes/05-ingress-describe.png` — `kubectl describe ingress
      nginx-ingress -n applications` showing the host → service mapping.
- [ ] `docs/images/kubernetes/05-browser-hostname.png` — browser showing "Welcome to
      nginx!" at `http://nginx.lab.local`.
