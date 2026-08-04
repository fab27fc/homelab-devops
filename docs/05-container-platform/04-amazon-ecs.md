# Lab 04 - Amazon Elastic Container Service (ECS)

## Lab Overview

In this lab, a Dockerized Node.js application stored in Amazon Elastic Container Registry (ECR) was deployed to Amazon Elastic Container Service (ECS) using AWS Fargate.

The deployment demonstrates a production-style container platform where AWS manages the underlying infrastructure while the application runs inside serverless containers.

The lab also validates:

- ECS Cluster creation
- ECS Task Definition
- ECS Service deployment
- Amazon ECR image integration
- AWS Fargate
- CloudWatch Logs
- Application validation
- ECS self-healing capability

---

# Architecture

```
Developer
     │
     ▼
Amazon ECR
     │
     ▼
ECS Task Definition
     │
     ▼
Amazon ECS Service
     │
     ▼
AWS Fargate
     │
     ▼
Running Container
     │
     ├────────► CloudWatch Logs
     │
     └────────► Public IP
                     │
                     ▼
            Node.js Application
```

---

# Technologies Used

- Amazon ECS
- AWS Fargate
- Amazon ECR
- Amazon CloudWatch Logs
- Docker
- Node.js
- IAM
- Amazon VPC
- Security Groups

---

# Objectives

The objectives of this lab were:

- Create an Amazon ECS Cluster.
- Configure an ECS Task Definition.
- Deploy a container from Amazon ECR.
- Create an ECS Service.
- Validate application endpoints.
- Configure centralized logging with CloudWatch.
- Demonstrate ECS self-healing capabilities.

---

# Deployment Process

## Step 1

Create the ECS Cluster using AWS Fargate.

---

## Step 2

Create the Task Definition.

Configuration included:

- CPU allocation
- Memory allocation
- Execution Role
- Container Image
- Port Mapping
- CloudWatch Logging

---

## Step 3

Deploy the ECS Service.

The service continuously maintains the desired number of running tasks.

---

## Step 4

Validate the application.

The application became accessible through its public IP address.

---

## Step 5

Validate CloudWatch Logs.

Container logs were successfully collected and centralized in Amazon CloudWatch Logs.

---

## Step 6

Test ECS Self-Healing.

The running task was manually stopped.

Amazon ECS automatically detected the failure and launched a replacement task, ensuring the desired service state remained available.

---

# Validation

The following application endpoints were successfully tested.

## Home Page

```
/
```

---

## Health Endpoint

```
/health
```

Example Response

```json
{
    "status":"healthy",
    "timestamp":"..."
}
```

---

## Version Endpoint

```
/version
```

Example Response

```json
{
    "version":"1.0.0"
}
```

---

## Hostname Endpoint

```
/hostname
```

Example Response

```json
{
    "hostname":"ip-10-0-x-xxx.ec2.internal"
}
```

---

## Environment Endpoint

```
/environment
```

Example Response

```json
{
    "environment":"development",
    "port":8080
}
```

---

# Self-Healing Test

The following procedure was performed:

1. Verify the running ECS Task.
2. Manually stop the running task.
3. Observe the task entering the stopped state.
4. Wait for Amazon ECS to detect the failure.
5. Verify that ECS automatically launches a replacement task.
6. Confirm the application remains available.

Result:

- Service availability maintained.
- Desired task count restored automatically.
- No manual intervention required.

---

# CloudWatch Logging

The application was configured to send logs directly to Amazon CloudWatch Logs.

The following startup logs were successfully collected:

- Application startup
- Node.js execution
- Listening port

This provides centralized logging for monitoring and troubleshooting.

---

# Screenshots

## ecs-create-cluster.png

![ecs-create-cluster](images/ecs-create-cluster.png)

---

## ecs-cluster-created.png

![ecs-cluster-created](images/ecs-cluster-created.png)

---

## ecs-task-definition-created.png

![ecs-task-definition-created](images/ecs-task-definition-created.png)

---

## ecs-task-definition-configuration.png

![ecs-task-definition-configuration](images/ecs-task-definition-configuration.png)

---

## ecs-service-deploying.png

![ecs-service-deploying](images/ecs-service-deploying.png)

---

## ecs-service-running.png

![ecs-service-running](images/ecs-service-running.png)

---

## ecs-application-home-page.png

![ecs-application-home-page](images/ecs-application-home-page.png)

---

## ecs-application-health-endpoint.png

![ecs-application-health-endpoint](images/ecs-application-health-endpoint.png)

---

## ecs-application-version-endpoint.png

![ecs-application-version-endpoint](images/ecs-application-version-endpoint.png)

---

## ecs-application-hostname-endpoint.png

![ecs-application-hostname-endpoint](images/ecs-application-hostname-endpoint.png)

---

## ecs-application-environment-endpoint.png

![ecs-application-environment-endpoint](images/ecs-application-environment-endpoint.png)

---

## ecs-cloudwatch-logs.png

![ecs-cloudwatch-logs](images/ecs-cloudwatch-logs.png)

---

## ecs-self-healing-before.png

![ecs-self-healing-before](images/ecs-self-healing-before.png)

---

## ecs-task-stopped.png

![ecs-task-stopped](images/ecs-task-stopped.png)

---

## ecs-task-recreated.png

![ecs-task-recreated](images/ecs-task-recreated.png)

---

# Best Practices

The following best practices were implemented during this lab:

- Store container images in Amazon ECR.
- Use AWS Fargate to avoid managing EC2 instances.
- Use Task Definitions to version container deployments.
- Configure centralized logging using CloudWatch Logs.
- Assign IAM Execution Roles following the principle of least privilege.
- Validate application health using dedicated endpoints.
- Deploy services instead of standalone tasks for automatic recovery.
- Keep container images versioned for future rolling deployments.

---

# Skills Demonstrated

- Amazon ECS
- AWS Fargate
- Amazon ECR
- CloudWatch Logs
- Docker
- Container orchestration
- Task Definitions
- ECS Services
- IAM Roles
- VPC Networking
- Security Groups
- Self-Healing Containers
- Application Validation