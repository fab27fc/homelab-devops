# Lab 06 - Amazon EKS Managed Node Groups

## Introduction

Amazon Elastic Kubernetes Service (Amazon EKS) separates the Kubernetes control plane from the worker nodes that execute containerized workloads.

While AWS fully manages the control plane, customers are responsible for providing compute resources capable of running Pods. The recommended approach is to use **Amazon EKS Managed Node Groups**, which automate the provisioning, configuration, lifecycle management, and updates of Amazon EC2 worker nodes.

Managed Node Groups significantly reduce operational overhead by integrating EC2 instances with Kubernetes, automatically joining new nodes to the cluster, replacing unhealthy instances, and simplifying Kubernetes version upgrades.

In this lab, we create a Managed Node Group, connect it to the previously created Amazon EKS cluster, validate that worker nodes successfully join the cluster, and examine how Kubernetes schedules workloads across the available nodes.

---

# Learning Objectives

After completing this lab you will be able to:

- Understand the purpose of Amazon EKS Managed Node Groups.
- Explain the relationship between the Kubernetes Control Plane and Worker Nodes.
- Create an EKS Managed Node Group.
- Configure compute, networking, scaling, and node repair settings.
- Understand the IAM permissions required by worker nodes.
- Connect kubectl to an Amazon EKS cluster.
- Verify that worker nodes successfully join the cluster.
- Inspect Kubernetes node information.
- Understand how Kubernetes schedules Pods across multiple nodes.
- Compare Managed Node Groups with Self-Managed Nodes.

---

# Architecture

```
                    Internet
                         │
                         ▼
              Amazon EKS Control Plane
                         │
        ┌────────────────┴────────────────┐
        │                                 │
        ▼                                 ▼
 Managed Node Group                 Managed Node Group
      EC2 Instance                     EC2 Instance
      Worker Node                      Worker Node
        │                                 │
        └──────────────┬──────────────────┘
                       ▼
               Kubernetes Pods
```

---

# Prerequisites

Before starting this lab, ensure the following resources already exist:

- AWS Account
- Amazon VPC
- Public and Private Subnets
- Internet Gateway
- NAT Gateway
- Amazon Elastic Kubernetes Service (EKS) Cluster
- Amazon ECR Repository
- AWS CLI
- kubectl
- IAM Cluster Role
- IAM Node Role

---

# What are Amazon EKS Managed Node Groups?

A Managed Node Group is a collection of Amazon EC2 instances that are automatically managed by Amazon EKS.

Each EC2 instance becomes a Kubernetes Worker Node after joining the cluster.

Unlike Self-Managed Nodes, Amazon EKS performs most lifecycle operations automatically, including:

- Provisioning EC2 instances
- Joining instances to the Kubernetes cluster
- Replacing unhealthy nodes
- Performing rolling updates
- Scaling the Auto Scaling Group
- Draining nodes during upgrades

Managed Node Groups are the recommended deployment model for most production environments because they simplify Kubernetes administration while preserving full control over the underlying EC2 instances.

---

# Kubernetes Worker Nodes

Worker Nodes are the servers responsible for executing containers.

Each Worker Node runs several Kubernetes components:

- kubelet
- kube-proxy
- Container Runtime
- Amazon VPC CNI

The kubelet communicates continuously with the Kubernetes API Server, reports node health, and receives Pod scheduling instructions.

Pods never run on the Control Plane.

Instead, they execute exclusively on Worker Nodes.

---

# Managed Node Group vs Self-Managed Nodes

| Feature | Managed Node Groups | Self-Managed Nodes |
|----------|--------------------|--------------------|
| Node Provisioning | Automatic | Manual |
| Cluster Join | Automatic | Manual |
| Updates | Automatic | Manual |
| Node Replacement | Automatic | Manual |
| Auto Scaling Integration | Native | Manual |
| Recommended by AWS | ✅ Yes | Only for advanced scenarios |

For most environments, Managed Node Groups provide the best balance between operational simplicity and flexibility.


---

# Step 1 - Create the Node IAM Role

Before creating a Managed Node Group, Amazon EKS requires an IAM Role that will be assumed by every EC2 instance launched as a Kubernetes Worker Node.

This role allows the nodes to:

- Join the Kubernetes cluster
- Communicate with the Kubernetes API Server
- Pull container images from Amazon ECR
- Configure networking using the Amazon VPC CNI plugin

Without these permissions, the EC2 instances would launch successfully but would never register as Kubernetes Nodes.

---

## Required IAM Policies

Attach the following AWS managed policies to the Node IAM Role:

| Policy | Purpose |
|----------|---------|
| AmazonEKSWorkerNodePolicy | Allows EC2 instances to join the Kubernetes cluster. |
| AmazonEC2ContainerRegistryPullOnly | Allows pulling container images from Amazon ECR. |
| AmazonEKS_CNI_Policy | Allows the Amazon VPC CNI plugin to configure networking. |

Screenshot

```text
images/eks-node-role-created.png
```

---

# Step 2 - Create the Managed Node Group

Navigate to:

```
Amazon EKS
    └── Clusters
            └── container-platform-eks
                    └── Compute
                            └── Add Node Group
```

Provide the following configuration.

---

## Node Group Name

```
container-platform-nodegroup
```

IAM Role

```
container-platform-eks-node-role
```

Screenshot

```text
images/eks-node-group-create.png
```

---

# Step 3 - Compute Configuration

Configure the Worker Nodes.

### AMI

```
Amazon Linux 2023
```

AWS provides an EKS-optimized Amazon Linux image that already contains:

- kubelet
- containerd
- Amazon VPC CNI
- bootstrap scripts
- required Kubernetes packages

---

### Capacity Type

```
On-Demand
```

On-Demand Instances provide predictable pricing and are recommended while learning Kubernetes.

Spot Instances can significantly reduce costs but may be interrupted at any time by AWS.

---

### Instance Type

```
t3.medium
```

This instance type provides:

- 2 vCPUs
- 4 GB RAM

It is sufficient for small Kubernetes clusters, development environments, and learning labs.

Screenshot

```text
images/eks-node-group-compute.png
```

---

# Step 4 - Scaling Configuration

Configure the desired number of Worker Nodes.

```
Desired Size : 2

Minimum Size : 2

Maximum Size : 2
```

Since Auto Scaling is outside the scope of this lab, the minimum, desired, and maximum sizes are identical.

This guarantees that exactly two Worker Nodes remain active.

Screenshot

```text
images/eks-node-group-scaling.png
```

---

# Step 5 - Networking Configuration

Select the VPC created during the networking lab.

Choose the private subnets where the Worker Nodes will run.

```
Private Subnet 1

Private Subnet 2
```

Using private subnets improves security because the EC2 instances do not receive public IP addresses.

Internet access is provided through the NAT Gateway.

Screenshot

```text
images/eks-node-group-networking.png
```

---

# Step 6 - Node Auto Repair

Enable

```
Node Auto Repair
```

When enabled, Amazon EKS continuously monitors the health of Worker Nodes.

If an EC2 instance becomes unhealthy, Amazon EKS automatically replaces it with a new instance.

This improves cluster availability without requiring manual intervention.

Screenshot

```text
images/eks-node-group-auto-repair.png
```

---

# Step 7 - Review and Create

Review all configuration settings.

Verify:

- Kubernetes Version
- Node IAM Role
- Instance Type
- Capacity Type
- Scaling Configuration
- Networking
- Auto Repair

Click

```
Create
```

Amazon EKS will begin provisioning the Worker Nodes.

Screenshot

```text
images/eks-node-group-review.png
```

---

# Step 8 - Verify the Node Group

After several minutes, the Node Group status should become:

```
Active
```

At this point:

- EC2 instances have been created.
- kubelet has joined the cluster.
- The Worker Nodes are registered with Kubernetes.

Screenshot

```text
images/eks-node-group-active.png
```

# Best Practices

The following best practices were implemented during this lab:

- Use Amazon EKS Managed Node Groups instead of Self-Managed Nodes whenever possible.
- Deploy Worker Nodes across multiple Availability Zones for high availability.
- Place Worker Nodes inside private subnets to improve security.
- Assign a dedicated IAM Role to Worker Nodes following the principle of least privilege.
- Use Amazon Linux 2023 EKS-optimized AMIs.
- Enable Node Auto Repair to automatically replace unhealthy nodes.
- Configure appropriate instance types based on workload requirements.
- Validate cluster connectivity using kubectl after provisioning the Node Group.
- Monitor node health and Kubernetes system Pods before deploying workloads.

---

# Skills Demonstrated

- Amazon EKS Managed Node Groups
- Kubernetes Worker Nodes
- Amazon EC2
- IAM Roles
- Kubernetes Scheduling
- kubelet
- Amazon VPC CNI
- CoreDNS
- kube-proxy
- Metrics Server
- Node Auto Repair
- Kubernetes Cluster Validation
- kubectl
- High Availability

---

# Conclusion

An Amazon EKS Managed Node Group was successfully deployed and integrated with the existing Kubernetes cluster.

The Worker Nodes automatically joined the cluster, Kubernetes system components became fully operational, and cluster connectivity was successfully validated using kubectl.

A containerized application was then deployed using a Kubernetes Deployment and exposed through a LoadBalancer Service, demonstrating how Amazon EKS distributes workloads across multiple Worker Nodes while providing high availability and self-healing capabilities.

The platform is now fully prepared for the next phase, where advanced Kubernetes features such as Helm, application packaging, GitOps, and production-grade deployments will be implemented.