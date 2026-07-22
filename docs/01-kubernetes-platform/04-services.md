# Lesson 4 — Services

## Objective

Answer: **if Pod IPs are temporary, how can clients reliably reach an
application?**

## The problem

Every Pod recreation changes the IP:

```
nginx-pod v1   → 10.244.53.137
(deleted, recreated)
nginx-pod v2   → 10.244.53.143
(rolling update)
nginx-pod v3   → 10.244.53.145
```

Anything hardcoding a Pod IP breaks the moment that Pod is replaced.

## Theory

A **Service** is a stable address in front of a changing set of Pods —
conceptually a small load balancer:

```
Frontend
      │
      ▼
   Service
      │
  ┌───┼───┐
  ▼   ▼   ▼
 Pod Pod Pod
```

A Service doesn't create Pods — it only forwards traffic to whatever Pods
currently match its `selector`, using the exact same labeling mechanism as
ReplicaSets:

```yaml
selector:
  app: nginx
```

### Service types

| Type | Scope | Use case |
|---|---|---|
| `ClusterIP` (default) | Internal only | Backend APIs, databases, internal comms |
| `NodePort` | `<NodeIP>:<30000-32767>` | Labs, simple external access |
| `LoadBalancer` | Cloud provider LB | AWS/Azure/GCP |
| `ExternalName` | DNS CNAME | Mapping to an external hostname |

This lesson uses `NodePort`.

## Manifest

[`kubernetes/services/nginx-service.yaml`](../kubernetes/services/nginx-service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: applications
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

| Field | Meaning |
|---|---|
| `type: NodePort` | Expose outside the cluster. |
| `selector.app: nginx` | Route to every Pod labeled `app=nginx`. |
| `port` | The Service's internal port. |
| `targetPort` | The container port NGINX actually listens on. |
| `nodePort` | The port opened on the node, reachable at `<node-ip>:30080`. |

## Hands-on lab

```bash
cd ~/enterprise-kubernetes-platform/manifests/services
kubectl apply --dry-run=client -f nginx-service.yaml
kubectl apply -f nginx-service.yaml

kubectl get svc -n applications
kubectl describe svc nginx-service -n applications
kubectl get endpoints -n applications
kubectl get pods -n applications -o wide
```

Expected:

```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx-service   NodePort   10.xxx.xxx.xxx  <none>        80:30080/TCP
```

Compare the `Endpoints` output against the Pods' IPs — they should match
exactly:

```
Service
      │
      ▼
Endpoints
      │
      ▼
Pods
```

### Test the Service

```bash
# from the RHEL node
curl http://192.168.100.20:30080

# from Ubuntu Management
curl http://192.168.100.20:30080

# from a laptop browser
http://192.168.100.20:30080
```

Expected: `Welcome to nginx!`.

```
                    Client
                      │
                      ▼
        http://192.168.100.20:30080
                      │
                      ▼
               NodePort Service
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
        Pod 1       Pod 2       Pod 3
        nginx       nginx       nginx
```

## Lab — Service self-healing demonstration

This is the experiment that ties Deployments + ReplicaSets + Services
together, and is one of the best live demos for a DevOps/SRE interview.

Terminal 1:

```bash
kubectl get pods -n applications -w
```

Terminal 2:

```bash
watch kubectl get endpoints -n applications
```

Terminal 3:

```bash
kubectl get pods -n applications
kubectl delete pod <POD_NAME> -n applications
```

What you should see:

- Terminal 1: `Running → Terminating`, then a new Pod
  `Pending → ContainerCreating → Running`.
- Terminal 2: the deleted Pod's IP drops out of the endpoint list, and the
  new Pod's IP appears a few seconds later — automatically, no manual step.
- `curl http://192.168.100.20:30080` (run repeatedly from Ubuntu
  Management) keeps returning `Welcome to nginx!` throughout, because the
  Service routes to whichever Pods are currently healthy, not to a fixed
  Pod.

```
Client
   │
   ▼
Service
   │
   ▼
Current Healthy Pods
   │
   ▼
Deployment → ReplicaSet
```

## Interview answer — "what happens when a Pod behind a Service dies?"

> The Deployment detects the desired replica count is no longer met, so
> the ReplicaSet creates a replacement Pod. Simultaneously, the Service
> removes the terminated Pod from its endpoints and adds the new healthy
> Pod once it passes readiness checks. Clients keep using the same Service
> address without ever knowing a Pod was replaced.

## Screenshots needed

- [ ] `docs/images/kubernetes/04-service-created.png` — `kubectl get svc -n applications`
      + `kubectl describe svc nginx-service -n applications`.
- [ ] `docs/images/kubernetes/04-endpoints-match-pods.png` — `kubectl get endpoints`
      next to `kubectl get pods -o wide`, IPs matching.
- [ ] `docs/images/kubernetes/04-browser-nodeport.png` — browser showing
      "Welcome to nginx!" at `http://192.168.100.20:30080`.
- [ ] `docs/images/kubernetes/04-self-healing-endpoints.png` — the `watch` terminal
      before/after deleting a Pod, showing the endpoint list update itself.
