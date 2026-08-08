# Lab 10 - Rolling Updates

## Objective

Perform a Rolling Update on an existing Kubernetes Deployment running in Amazon EKS by deploying a new application version without downtime.

This lab demonstrates how Kubernetes gradually replaces old Pods with new ones while keeping the application available throughout the deployment process.

---

# Architecture

```
Developer
    │
    ▼
Modify Application Code
    │
    ▼
Docker Build
    │
    ▼
Docker Image v1.1.0
    │
    ▼
Amazon ECR
    │
    ▼
kubectl set image
    │
    ▼
Kubernetes Deployment
    │
    ▼
Rolling Update Strategy
    │
 ┌──┴───────────────┐
 ▼                  ▼
Old ReplicaSet   New ReplicaSet
 ▼                  ▼
Old Pods        New Pods
        │
        ▼
Kubernetes Service
        │
        ▼
Application Available
```

---

# Prerequisites

- Amazon EKS Cluster running
- kubectl configured
- Docker installed
- AWS CLI configured
- Amazon ECR repository
- Existing Deployment running version **1.0.0**
- LoadBalancer Service deployed

---

# Step 1 - Verify the Current Deployment

Verify the Deployment is healthy before performing the update.

```bash
kubectl get deployment container-platform-app

kubectl get pods

kubectl get svc container-platform-service

kubectl get deployment container-platform-app \
-o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

Expected output:

```
651706759989.dkr.ecr.us-east-1.amazonaws.com/homelab/container-platform-app:1.0.0
```

Screenshot:

```
deployment-before-update.png
```

---

# Step 2 - Update the Application Source Code

Open the application source.

```bash
cd ~/devops_projects_git/homelab-devops/05-container-platform/container-platform-app/src

vim app.js
```

Update the application version.

Before:

```javascript
const appVersion = process.env.APP_VERSION || "1.0.0";
```

After:

```javascript
const appVersion = process.env.APP_VERSION || "1.1.0";
```

Update the HTML title.

Before:

```html
<title>Container Platform App v1.0.0</title>
```

After:

```html
<title>Container Platform App v1.1.0</title>
```

Verify the changes.

```bash
grep -n "appVersion\|Container Platform App v" app.js
```

Expected output:

```
appVersion = process.env.APP_VERSION || "1.1.0"

Container Platform App v1.1.0
```

Screenshot:

```
rolling-update-source-modified.png
```

---

# Step 3 - Build the New Docker Image

Return to the project root.

```bash
cd ..
```

Build the image.

```bash
docker build -t container-platform-app:1.1.0 .
```

Verify it exists.

```bash
docker images | grep container-platform-app
```

Expected:

```
container-platform-app 1.1.0
```

Screenshot:

```
rolling-update-image-built.png
```

---

# Step 4 - Push the Image to Amazon ECR

Authenticate Docker.

```bash
aws ecr get-login-password \
--region us-east-1 \
| docker login \
--username AWS \
--password-stdin \
651706759989.dkr.ecr.us-east-1.amazonaws.com
```

Tag the image.

```bash
docker tag \
container-platform-app:1.1.0 \
651706759989.dkr.ecr.us-east-1.amazonaws.com/homelab/container-platform-app:1.1.0
```

Push it.

```bash
docker push \
651706759989.dkr.ecr.us-east-1.amazonaws.com/homelab/container-platform-app:1.1.0
```

Verify the image exists inside ECR.

```bash
aws ecr describe-images \
--repository-name homelab/container-platform-app \
--region us-east-1 \
--image-ids imageTag=1.1.0 \
--query 'imageDetails[0].{Tags:imageTags,Digest:imageDigest,PushedAt:imagePushedAt}' \
--output table
```

Screenshots:

```
rolling-update-new-image-pushed.png

describe-images-ecr.png
```

---

# Step 5 - Update the Deployment

Update the Deployment image.

```bash
kubectl set image deployment/container-platform-app \
application=651706759989.dkr.ecr.us-east-1.amazonaws.com/homelab/container-platform-app:1.1.0
```

Expected output:

```
deployment.apps/container-platform-app image updated
```

Screenshot:

```
rolling-update-image-updated.png
```

---

# Step 6 - Observe the Rolling Update

Watch Pods being replaced.

```bash
kubectl get pods -w
```

Observe:

- New Pods are created.
- Old Pods terminate.
- Application remains available.

Screenshot:

```
rolling-update-pods-replaced.png
```

---

# Step 7 - Verify Rollout Completion

Wait until Kubernetes finishes the rollout.

```bash
kubectl rollout status deployment/container-platform-app
```

Expected output:

```
deployment "container-platform-app" successfully rolled out
```

Screenshot:

```
rolling-update-successfully-rolled-out.png
```

---

# Step 8 - Verify the Deployment Image

Verify the Deployment now references version **1.1.0**.

```bash
kubectl get deployment container-platform-app \
-o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

Expected output:

```
651706759989.dkr.ecr.us-east-1.amazonaws.com/homelab/container-platform-app:1.1.0
```

Screenshot:

```
rolling-update-image-verified.png
```

---

# Step 9 - Verify Running Pods

Confirm every running Pod uses the new image.

```bash
kubectl get pods \
-o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[0].image,STATUS:.status.phase'
```

Expected output:

```
container-platform-app-xxxx

container-platform-app:1.1.0
```

Screenshot:

```
rolling-update-pods-image-1.1.0.png
```

---

# Step 10 - Verify the Application

Retrieve the LoadBalancer endpoint.

```bash
LOAD_BALANCER_DNS=$(kubectl get svc container-platform-service \
-o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

Verify the endpoint.

```bash
echo $LOAD_BALANCER_DNS
```

Check the application version.

```bash
curl http://$LOAD_BALANCER_DNS/version
```

Expected output:

```json
{"version":"1.1.0"}
```

Verify the application page.

```bash
curl http://$LOAD_BALANCER_DNS
```

Screenshot:

```
rolling-update-application-version.png
```

---

# Step 11 - Verify ReplicaSets

Display ReplicaSets.

```bash
kubectl get replicasets
```

Detailed information.

```bash
kubectl get replicasets \
-o custom-columns='REPLICASET:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image'
```

Expected behavior:

- Previous ReplicaSet scaled down.
- New ReplicaSet scaled up.

Screenshot:

```
rolling-update-replicasets.png
```

---

# Step 12 - View Rollout History

Display Deployment revision history.

```bash
kubectl rollout history deployment/container-platform-app
```

Screenshot:

```
rolling-update-history.png
```

---

# Best Practices

The following best practices were implemented during this lab:

- Build immutable Docker images.
- Store container images in Amazon ECR.
- Tag every application release using semantic versioning.
- Verify image availability before updating Kubernetes Deployments.
- Use Rolling Updates instead of recreating Deployments.
- Monitor Pods during every deployment.
- Validate Deployment status after updates.
- Verify ReplicaSets after each rollout.
- Test the application after deployment.
- Keep previous ReplicaSets available for future rollback operations.

---

# Skills Demonstrated

- Amazon EKS
- Kubernetes
- Docker
- Amazon ECR
- Kubernetes Deployments
- Rolling Updates
- ReplicaSets
- Container Images
- Image Versioning
- Zero Downtime Deployments
- Kubernetes Services
- LoadBalancer
- kubectl
- Application Lifecycle Management

---

# Conclusion

The Container Platform application was successfully upgraded from version **1.0.0** to **1.1.0** using Kubernetes Rolling Updates.

A new Docker image was built, published to Amazon ECR, and deployed into the existing Amazon EKS cluster without interrupting service availability. Kubernetes gradually replaced the old Pods with new Pods while maintaining continuous access to the application.

The Deployment, ReplicaSets, Pods, and application endpoint were verified to confirm that the rollout completed successfully and that the new application version was running in production.

This lab demonstrates one of the core deployment strategies used in production Kubernetes environments and establishes the foundation for the next lab covering Deployment Rollbacks.