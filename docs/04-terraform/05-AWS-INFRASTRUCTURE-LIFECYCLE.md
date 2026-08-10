# AWS Infrastructure Lifecycle

## Overview

This document describes the procedure used to create, validate, and safely destroy the AWS infrastructure used by the Container Platform Homelab.

The goal is to provide a repeatable process for rebuilding the AWS environment when needed while minimizing unnecessary AWS costs when the lab is not in use.

The environment includes:

- Amazon VPC
- Public and private subnets
- Internet Gateway
- NAT Gateway
- Elastic IP
- Route tables
- Network ACLs
- Security Groups
- Amazon EKS
- EKS Managed Node Group
- Kubernetes workloads
- AWS Load Balancer
- Monitoring components

---

## Architecture Lifecycle

The infrastructure follows this lifecycle:

```text
Terraform Infrastructure
        |
        v
VPC / Subnets / Routing
        |
        v
Amazon EKS
        |
        v
EKS Managed Node Group
        |
        v
Kubernetes Workloads
        |
        v
Load Balancer
        |
        v
Monitoring
```

When the lab is no longer required, the environment should be destroyed in approximately the reverse order:

```text
Kubernetes LoadBalancer
        |
        v
EKS Managed Node Group
        |
        v
EKS Cluster
        |
        v
Terraform Infrastructure
        |
        v
AWS Resource Verification
```

---

# Part 1 — Terraform Infrastructure

Terraform manages the base AWS networking infrastructure used by the lab.

Navigate to the Terraform directory:

```bash
cd ~/devops_projects_git/homelab-devops/04-terraform
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Review the infrastructure that Terraform will create:

```bash
terraform plan
```

Optionally save the execution plan:

```bash
terraform plan -out=tfplan
```

Apply the saved plan:

```bash
terraform apply tfplan
```

Verify the resources managed by Terraform:

```bash
terraform state list
```

The Terraform infrastructure includes resources such as:

- VPC
- Public subnets
- Private subnets
- Internet Gateway
- NAT Gateway
- Elastic IP
- Route tables
- Network ACLs
- Security Groups

---

## Important Cost Consideration

The NAT Gateway is one of the resources in this lab that can continue generating charges while it exists.

For this reason, the AWS environment should be destroyed when the cloud lab is not actively being used.

Other resources that should be verified after completing the lab include:

- EKS clusters
- EKS worker nodes
- EC2 instances
- Load Balancers
- Elastic IP addresses
- EBS volumes
- RDS databases


# Part 2 — Recreating Amazon EKS

The Amazon EKS cluster and Managed Node Group were created separately from the Terraform-managed networking infrastructure.

Because these resources are not currently managed by Terraform, they must be recreated after the base networking infrastructure is available.

---

## 2.1 Verify the AWS Infrastructure

Before creating the EKS cluster, verify that the Terraform infrastructure is available.

```bash
terraform state list
```

Verify the VPC:

```bash
aws ec2 describe-vpcs \
  --region us-east-1 \
  --query 'Vpcs[].{VpcId:VpcId,CIDR:CidrBlock}' \
  --output table
```

Verify the subnets:

```bash
aws ec2 describe-subnets \
  --region us-east-1 \
  --query 'Subnets[].{SubnetId:SubnetId,VpcId:VpcId,AZ:AvailabilityZone,CIDR:CidrBlock}' \
  --output table
```

The private subnets will be used by the EKS Managed Node Group.

---

## 2.2 Create the EKS Cluster

The cluster used by this homelab is:

```text
container-platform-eks
```

The cluster can be created using the AWS Console or AWS CLI.

When recreating the cluster, configure it to use the VPC and subnets created by Terraform.

Important configuration:

```text
Cluster name: container-platform-eks
Region: us-east-1
Kubernetes: Amazon EKS supported version
Networking: Terraform VPC
Subnets: Terraform-created subnets
IAM role: EKS cluster IAM role
```

Wait until the cluster reaches:

```text
ACTIVE
```

Verify:

```bash
aws eks describe-cluster \
  --name container-platform-eks \
  --region us-east-1 \
  --query 'cluster.status' \
  --output text
```

Expected result:

```text
ACTIVE
```

---

## 2.3 Configure kubectl

After the EKS cluster becomes active, update the local kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name container-platform-eks
```

Verify the Kubernetes context:

```bash
kubectl config current-context
```

Test connectivity:

```bash
kubectl get nodes
```

At this point, no worker nodes may appear if the Managed Node Group has not been created yet.

---

## 2.4 Create the Managed Node Group

Create the Managed Node Group:

```text
container-platform-nodegroup
```

The node group should use the private subnets created by Terraform.

Configuration used by the lab:

```text
Cluster:
container-platform-eks

Node Group:
container-platform-nodegroup

Capacity Type:
ON_DEMAND

Scaling:
Minimum: 2
Desired: 3
Maximum: 3
```

The worker nodes require an IAM role with the necessary EKS worker-node permissions.

Wait until the node group reaches:

```text
ACTIVE
```

Verify:

```bash
aws eks describe-nodegroup \
  --cluster-name container-platform-eks \
  --nodegroup-name container-platform-nodegroup \
  --region us-east-1 \
  --query 'nodegroup.status' \
  --output text
```

Expected result:

```text
ACTIVE
```

---

## 2.5 Verify the EKS Nodes

Run:

```bash
kubectl get nodes
```

For additional information:

```bash
kubectl get nodes -o wide
```

All worker nodes should report:

```text
Ready
```

Example:

```text
NAME                          STATUS   AGE
ip-10-0-x-x.ec2.internal     Ready    ...
ip-10-0-x-x.ec2.internal     Ready    ...
ip-10-0-x-x.ec2.internal     Ready    ...
```

---

## 2.6 Verify the EKS Environment

Check all Kubernetes workloads:

```bash
kubectl get pods -A
```

Check services:

```bash
kubectl get svc -A
```

Check Helm releases:

```bash
helm list -A
```

At this point, the EKS platform is ready for application deployment and observability components.

---

## Important

The EKS control plane and worker nodes can generate AWS charges.

When the lab is finished, both the Managed Node Group and the EKS cluster should be deleted as described in the destruction procedure later in this document.

# Part 3 — Deploying the Container Platform Application

After the EKS cluster and Managed Node Group are running, the Container Platform application can be deployed.

The application is packaged as a Docker image, stored in Amazon ECR, and deployed to Amazon EKS.

The deployment flow is:

```text
Application Source Code
        |
        v
Docker Image
        |
        v
Amazon ECR
        |
        v
Kubernetes Deployment
        |
        v
Kubernetes Pods
        |
        v
LoadBalancer Service
        |
        v
Application
```

---

## 3.1 Verify the ECR Repository

List the available ECR repositories:

```bash
aws ecr describe-repositories \
  --region us-east-1 \
  --query 'repositories[].repositoryName' \
  --output table
```

Identify the repository containing the Container Platform application.

Then list the available images:

```bash
aws ecr list-images \
  --repository-name <ECR_REPOSITORY_NAME> \
  --region us-east-1
```

The application image used during the lab was:

```text
container-platform-app:1.1.0
```

> The exact ECR repository name and account-specific registry URL should be verified before redeploying the application.

---

## 3.2 Verify Kubernetes Access

Before deploying the application:

```bash
kubectl get nodes
```

Expected result:

```text
STATUS
Ready
Ready
Ready
```

Verify the current Kubernetes context:

```bash
kubectl config current-context
```

---

## 3.3 Deploy the Application

Apply the Kubernetes manifests used by the Container Platform project.

Navigate to the directory containing the Kubernetes manifests and run:

```bash
kubectl apply -f <manifest-file>.yaml
```

If the Deployment and Service are stored separately:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

## 3.4 Verify the Deployment

Check the Deployment:

```bash
kubectl get deployment container-platform-app \
  -n default
```

Expected state:

```text
READY   UP-TO-DATE   AVAILABLE
2/2     2            2
```

Check the application Pods:

```bash
kubectl get pods \
  -n default \
  -o wide
```

The Pods should report:

```text
Running
```

---

## 3.5 Verify the Container Image

Verify which image is currently running:

```bash
kubectl get deployment container-platform-app \
  -n default \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Example:

```text
<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/container-platform-app:1.1.0
```

This confirms that the Kubernetes Deployment is using the expected image from Amazon ECR.

---

## 3.6 Verify the LoadBalancer Service

Check the application Service:

```bash
kubectl get svc container-platform-service \
  -n default
```

The Service should have:

```text
TYPE
LoadBalancer
```

Wait until AWS assigns an external hostname.

Retrieve it with:

```bash
LB=$(kubectl get svc container-platform-service \
  -n default \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo $LB
```

---

## 3.7 Test Application Health

Test the application's health endpoint:

```bash
curl -s http://$LB/health
```

Expected response:

```json
{
  "status": "healthy"
}
```

This confirms that:

- The AWS Load Balancer is reachable.
- The Kubernetes Service is routing traffic.
- The application Pods are responding.
- The application health endpoint is working.

---

## 3.8 Verify Service Endpoints

Check the Kubernetes endpoints:

```bash
kubectl get endpoints container-platform-service \
  -n default
```

> Kubernetes may display a deprecation warning for the legacy Endpoints API. Newer Kubernetes versions use EndpointSlice.

The modern command is:

```bash
kubectl get endpointslices \
  -n default
```

The Service should have endpoints corresponding to the running application Pods.

---

## 3.9 Test Kubernetes Scaling

The Deployment can be scaled manually:

```bash
kubectl scale deployment container-platform-app \
  --replicas=4 \
  -n default
```

Verify:

```bash
kubectl get pods \
  -n default \
  -o wide
```

Four application Pods should eventually report:

```text
Running
```

Verify that the LoadBalancer still works:

```bash
curl -s http://$LB/health
```

Expected:

```json
{
  "status": "healthy"
}
```

This demonstrates that Kubernetes can increase the number of application replicas while the Service continues exposing the application through the same AWS Load Balancer.

---

## 3.10 Application Validation

The application deployment is considered successful when:

- EKS nodes are `Ready`.
- Application Pods are `Running`.
- The Deployment has the expected number of replicas.
- The expected ECR image is running.
- The LoadBalancer receives an external hostname.
- The `/health` endpoint returns `healthy`.
- Kubernetes Service endpoints point to the application Pods.

# Part 4 — Safe Infrastructure Destruction

AWS resources should be removed when the cloud lab is not being used to minimize unnecessary costs.

Because the EKS cluster was created separately from the Terraform infrastructure, the environment must be destroyed in the correct order.

The destruction sequence is:

```text
Kubernetes LoadBalancer
        |
        v
EKS Managed Node Group
        |
        v
EKS Cluster
        |
        v
Terraform Infrastructure
        |
        v
AWS Resource Verification
```

---

## 4.1 Delete the Kubernetes LoadBalancer

Before deleting the EKS cluster, remove the Kubernetes `LoadBalancer` Service.

This allows Kubernetes and AWS to properly remove the associated AWS Load Balancer.

Verify the Service:

```bash
kubectl get svc container-platform-service \
  -n default
```

Delete it:

```bash
kubectl delete svc container-platform-service \
  -n default
```

Verify:

```bash
kubectl get svc -n default
```

The `container-platform-service` should no longer appear.

---

## 4.2 Verify AWS Load Balancer Removal

Check whether any AWS Load Balancers remain:

```bash
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName}' \
  --output table
```

No lab Load Balancer should remain before continuing.

---

## 4.3 Delete the EKS Managed Node Group

List the node groups:

```bash
aws eks list-nodegroups \
  --cluster-name container-platform-eks \
  --region us-east-1
```

Delete the Managed Node Group:

```bash
aws eks delete-nodegroup \
  --cluster-name container-platform-eks \
  --nodegroup-name container-platform-nodegroup \
  --region us-east-1
```

The node group will enter:

```text
DELETING
```

Check its status:

```bash
aws eks describe-nodegroup \
  --cluster-name container-platform-eks \
  --nodegroup-name container-platform-nodegroup \
  --region us-east-1 \
  --query 'nodegroup.status' \
  --output text
```

---

## 4.4 Wait for the Node Group to Be Deleted

Instead of repeatedly checking the status manually, use the AWS CLI waiter:

```bash
aws eks wait nodegroup-deleted \
  --cluster-name container-platform-eks \
  --nodegroup-name container-platform-nodegroup \
  --region us-east-1
```

Verify:

```bash
aws eks list-nodegroups \
  --cluster-name container-platform-eks \
  --region us-east-1
```

Expected result:

```json
{
  "nodegroups": []
}
```

At this point, the EKS worker nodes have been removed.

---

## 4.5 Delete the EKS Cluster

Delete the EKS control plane:

```bash
aws eks delete-cluster \
  --name container-platform-eks \
  --region us-east-1
```

The cluster will enter:

```text
DELETING
```

Wait for the deletion to complete:

```bash
aws eks wait cluster-deleted \
  --name container-platform-eks \
  --region us-east-1
```

Verify:

```bash
aws eks list-clusters \
  --region us-east-1
```

Expected result:

```json
{
  "clusters": []
}
```

---

## 4.6 Review the Terraform Destruction Plan

Navigate to the Terraform directory:

```bash
cd ~/devops_projects_git/homelab-devops/04-terraform
```

Check the resources currently managed by Terraform:

```bash
terraform state list
```

Create a saved destruction plan:

```bash
terraform plan -destroy -out=destroy.tfplan
```

Review the summary carefully.

Example from this lab:

```text
Plan: 0 to add, 0 to change, 32 to destroy.
```

Saving the plan ensures that the exact reviewed destruction plan is used during the next step.

---

## 4.7 Destroy the Terraform Infrastructure

Apply the saved destruction plan:

```bash
terraform apply destroy.tfplan
```

Terraform will remove the resources managed by the configuration.

These may include:

- NAT Gateway
- Elastic IP
- Internet Gateway
- Public subnets
- Private subnets
- Route tables
- Network ACLs
- Security Groups
- VPC

Wait until Terraform reports:

```text
Destroy complete!
```

---

## 4.8 Verify the Terraform State

After destruction:

```bash
terraform state list
```

A successful complete destruction should return no managed resources.

This is an important validation because it confirms that Terraform no longer tracks infrastructure from the lab.

---

## Why the Destruction Order Matters

Deleting resources in the correct order helps avoid AWS dependency errors.

For example:

```text
LoadBalancer
     ↓
depends on Kubernetes/EKS

EKS Nodes
     ↓
depend on networking

EKS Cluster
     ↓
uses VPC networking

VPC
     ↓
cannot be removed while dependent resources exist
```

Destroying the Terraform VPC before removing EKS-related resources could cause deletion failures because AWS resources may still reference subnets, security groups, or other networking components.

---

## Cost Control

The environment should not remain running unnecessarily.

Particular attention should be given to resources such as:

- NAT Gateway
- EKS control plane
- EC2 worker nodes
- AWS Load Balancers
- EBS volumes
- Public IPv4 addresses

The next section performs a post-destruction audit to verify that these resources are no longer present.


# Part 5 — Post-Destroy AWS Resource Verification

After destroying the EKS environment and Terraform infrastructure, perform a final AWS resource audit.

The purpose of this validation is to identify resources that could remain active and continue generating charges.

The following resources should be checked:

```text
Terraform State
EKS
EC2
NAT Gateway
Load Balancers
Elastic IP Addresses
EBS Volumes
RDS
```

---

## 5.1 Verify Terraform State

Check whether Terraform still manages any resources:

```bash
terraform state list
```

Expected result:

```text
No resources returned
```

An empty Terraform state confirms that all resources managed by the current Terraform configuration were successfully destroyed.

---

## 5.2 Verify EKS Clusters

Check for remaining EKS clusters:

```bash
aws eks list-clusters \
  --region us-east-1
```

Expected result:

```json
{
  "clusters": []
}
```

This confirms that the EKS control plane has been removed.

---

## 5.3 Verify EC2 Instances

Check for EC2 instances that are not terminated:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[].Instances[?State.Name!=`terminated`].[InstanceId,State.Name,InstanceType]' \
  --output table
```

Expected result:

```text
No instances returned
```

This confirms that the EKS worker nodes and other EC2 instances from the lab are no longer running.

---

## 5.4 Verify NAT Gateways

NAT Gateways should always be checked after destroying the environment because they can continue generating charges while provisioned.

Run:

```bash
aws ec2 describe-nat-gateways \
  --region us-east-1 \
  --filter Name=state,Values=available,pending \
  --query 'NatGateways[].{ID:NatGatewayId,State:State,VPC:VpcId}' \
  --output table
```

Expected result:

```text
No NAT Gateways returned
```

This confirms that no active or pending NAT Gateway remains.

---

## 5.5 Verify Load Balancers

Check for remaining Application, Network, or Gateway Load Balancers:

```bash
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName}' \
  --output table
```

Expected result:

```text
No Load Balancers returned
```

This validates that the Kubernetes-created Load Balancer was successfully removed.

---

## 5.6 Verify Elastic IP Addresses

Check for allocated Elastic IP addresses:

```bash
aws ec2 describe-addresses \
  --region us-east-1 \
  --query 'Addresses[].{PublicIP:PublicIp,AllocationId:AllocationId}' \
  --output table
```

Expected result:

```text
No Elastic IP addresses returned
```

This is particularly important after deleting a NAT Gateway because an Elastic IP may remain allocated if it is not managed or released correctly.

---

## 5.7 Verify EBS Volumes

Check for remaining EBS volumes:

```bash
aws ec2 describe-volumes \
  --region us-east-1 \
  --query 'Volumes[].{ID:VolumeId,State:State,Size:Size,Type:VolumeType}' \
  --output table
```

Expected result:

```text
No EBS volumes returned
```

Unused EBS volumes can continue generating storage charges even when no EC2 instance is running.

---

## 5.8 Verify RDS Instances

Check for remaining RDS database instances:

```bash
aws rds describe-db-instances \
  --region us-east-1 \
  --query 'DBInstances[].{DB:DBInstanceIdentifier,Status:DBInstanceStatus,Class:DBInstanceClass}' \
  --output table
```

Expected result:

```text
No RDS instances returned
```

---

## 5.9 Final Resource Audit

The final audit performed after this lab produced the following result:

| Resource | Final State |
|---|---|
| Terraform State | Empty |
| EKS Cluster | Deleted |
| EKS Managed Node Group | Deleted |
| EC2 Instances | None |
| NAT Gateways | None |
| Load Balancers | None |
| Elastic IP Addresses | None |
| EBS Volumes | None |
| RDS Instances | None |

This confirms that the main AWS resources associated with the lab were successfully removed.

---

## 5.10 Billing Verification

Deleting AWS resources stops future resource usage, but AWS billing information may not update immediately.

After destroying the environment, AWS Billing and Cost Management should also be reviewed.

Recommended services to review include:

```text
Amazon EKS
Amazon EC2
EC2 - Other
Elastic Load Balancing
Amazon VPC
Amazon RDS
```

Particular attention should be given to:

```text
NAT Gateway
Public IPv4
EBS
EKS
EC2
Load Balancers
```

The objective is to confirm that no unexpected resources continue generating usage after the lab has been destroyed.

---

# Part 6 — Lessons Learned

This infrastructure lifecycle exercise demonstrated that provisioning infrastructure is only one part of operating a cloud environment.

A complete DevOps workflow should consider the entire resource lifecycle:

```text
Plan
  ↓
Provision
  ↓
Deploy
  ↓
Validate
  ↓
Operate
  ↓
Destroy
  ↓
Verify
```

Important lessons from this lab include:

### Terraform only destroys resources it manages

The EKS cluster and Managed Node Group were created separately from the Terraform configuration.

Therefore:

```bash
terraform destroy
```

would not automatically delete those resources.

Before destroying an environment, always verify the Terraform state:

```bash
terraform state list
```

---

### Kubernetes can create AWS resources

A Kubernetes Service configured as:

```yaml
type: LoadBalancer
```

can provision an AWS Load Balancer.

For this reason, the Kubernetes LoadBalancer Service should be removed while the EKS cluster is still operational.

---

### Resource dependencies determine destruction order

The infrastructure was safely removed using:

```text
Kubernetes LoadBalancer
        ↓
EKS Managed Node Group
        ↓
EKS Cluster
        ↓
Terraform Networking
        ↓
AWS Resource Audit
```

This minimizes dependency problems during deletion.

---

### Destruction must be validated

A successful:

```text
Destroy complete!
```

message from Terraform does not necessarily mean the entire AWS environment is empty.

Resources created outside Terraform must be checked separately.

The final audit therefore validated:

```text
EKS
EC2
NAT Gateway
Load Balancers
Elastic IPs
EBS
RDS
Terraform State
```

---

### Cost management is part of cloud engineering

Cloud labs should be designed with both deployment and destruction procedures.

A repeatable workflow makes it possible to:

```text
Create environment
        ↓
Practice
        ↓
Destroy environment
        ↓
Stop unnecessary resource usage
        ↓
Recreate when needed
```

This allows the AWS environment to be used as an on-demand learning platform instead of keeping expensive infrastructure running continuously.

---

# Conclusion

This document provides a repeatable lifecycle for the AWS Container Platform environment.

The infrastructure can be provisioned when required for testing and learning, validated after deployment, and safely destroyed when it is no longer needed.

The final workflow is:

```text
Terraform Apply
      ↓
AWS Networking
      ↓
Amazon EKS
      ↓
Managed Node Group
      ↓
Kubernetes Application
      ↓
Load Balancer
      ↓
Observability / Testing
      ↓
Remove Load Balancer
      ↓
Delete Node Group
      ↓
Delete EKS
      ↓
Terraform Destroy
      ↓
AWS Cost Resource Audit
```

This approach provides a repeatable and cost-conscious method for operating the cloud homelab.

