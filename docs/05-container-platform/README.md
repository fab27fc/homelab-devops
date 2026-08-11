# Container Platform

## Overview

The Container Platform section focuses on building, packaging, storing, and deploying containerized applications using modern DevOps practices.

The application developed in this section will be reused throughout the remaining labs, serving as the primary workload for Docker, Amazon ECR, Amazon ECS, Amazon EKS, GitHub Actions, and Argo CD.

By the end of this section, the application will be fully automated from development to production deployment.

---

# Objectives

The main objectives of this section are:

- Build a containerized application.
- Learn Docker fundamentals.
- Push container images to Amazon ECR.
- Deploy containers using Amazon ECS.
- Deploy containers using Amazon EKS.
- Automate CI/CD with GitHub Actions.
- Deploy applications using GitOps with Argo CD.

---

# Technologies

- Node.js
- Express.js
- Docker
- Amazon ECR
- Amazon ECS
- Amazon EKS
- GitHub Actions
- Argo CD


# Project Structure

```text
05-container-platform/
│
├── container-platform-app/
│
├── README.md
│
├── 01-build-containerized-application.md
├── 02-docker-fundamentals.md
├── 03-amazon-ecr.md
├── 04-amazon-ecs.md
├── 05-amazon-eks.md
│
└── images/
```

---

# Container Platform Workflow

```text
Build Application
        │
        ▼
Docker Image
        │
        ▼
Amazon ECR
        │
        ▼
Amazon ECS
        │
        ▼
Amazon EKS
```

---

# Expected Outcome

After completing this section, you will have:

- A production-ready containerized application.
- A Docker image stored in Amazon ECR.
- An application deployed on Amazon ECS.
- An application deployed on Amazon EKS.
- A reusable application for future DevOps labs.