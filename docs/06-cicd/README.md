# GitHub Actions

## Overview

GitHub Actions is GitHub's built-in automation platform. It allows developers to execute automated workflows whenever specific events occur in a repository, such as a push, pull request, release, or scheduled task.

GitHub Actions is commonly used to implement Continuous Integration (CI) and Continuous Delivery/Deployment (CD) pipelines.

---

# Objectives

After completing this section, you will understand:

- What GitHub Actions is
- How CI/CD pipelines work
- GitHub Actions architecture
- Core GitHub Actions components
- GitHub workflow structure
- How GitHub Actions integrates with Kubernetes and ArgoCD
- Best practices for building CI/CD pipelines

---

# Continuous Integration (CI)

Continuous Integration is the practice of automatically validating every code change committed to a repository.

Typical CI tasks include:

- Build applications
- Run automated tests
- Validate YAML files
- Validate Kubernetes manifests
- Scan for vulnerabilities
- Build Docker images

CI focuses on ensuring code quality before deployment.

---

# Continuous Delivery (CD)

Continuous Delivery prepares an application for deployment after all validations succeed.

Deployment is still a manual decision.

---

# Continuous Deployment

Continuous Deployment automatically deploys the application whenever the pipeline succeeds.

No manual approval is required.

---

# GitHub Actions Architecture

```
Developer
      │
      ▼
Git Push
      │
      ▼
GitHub Repository
      │
      ▼
GitHub Actions
      │
      ▼
Workflow
      │
      ▼
Jobs
      │
      ▼
Steps
      │
      ▼
Runner
      │
      ▼
Result
```

---

# Core Components

## Workflow

A YAML file that defines an automation process.

Location:

```
.github/workflows/
```

---

## Event

An event triggers a workflow.

Examples:

- push
- pull_request
- workflow_dispatch
- release
- schedule

---

## Job

A Job is a collection of related tasks executed on the same Runner.

Examples:

- Build
- Test
- Deploy

---

## Step

A Step is an individual task inside a Job.

Examples:

- Checkout repository
- Install kubectl
- Validate YAML
- Execute tests

---

## Runner

A Runner is the machine that executes the Workflow.

Types:

- GitHub-hosted Runner
- Self-hosted Runner

---

## Action

An Action is a reusable component that performs a specific task.

Example:

```yaml
uses: actions/checkout@v4
```

---

# Workflow Structure

Every GitHub Actions workflow follows the same basic structure.

```yaml
name:

on:

jobs:

runs-on:

steps:

uses:

run:
```

---

# Git Workflow

```
Working Directory
        │
git add
        ▼
Staging Area
        │
git commit
        ▼
Local Repository
        │
git push
        ▼
Remote Repository (GitHub)
```

---

# GitHub Actions in this Homelab

The CI/CD pipeline for this homelab will be:

```
Developer
      │
      ▼
git push
      │
      ▼
GitHub Actions
      │
      ├── Validate YAML
      ├── Validate Kubernetes
      ├── Build Docker Image
      ├── Push Docker Image
      ▼
Git Repository
      ▼
ArgoCD
      ▼
Kubernetes
      ▼
Prometheus
      ▼
Grafana
```

GitHub Actions is responsible for the **Continuous Integration** stage.

ArgoCD is responsible for the **Continuous Deployment** stage using GitOps.

---

# Best Practices

- Keep workflows simple and modular.
- Use descriptive names for Workflows, Jobs, and Steps.
- Reuse official GitHub Actions whenever possible.
- Store sensitive information using GitHub Secrets.
- Validate code before deploying.
- Keep CI fast and reliable.

---

# Learning Roadmap

This section includes the following labs:

1. Introduction to GitHub Actions
2. First Workflow
3. Using GitHub Actions
4. Multiple Jobs
5. Variables and Secrets
6. Kubernetes Validation
7. Docker Build
8. Docker Publish
9. GitOps Pipeline

---

# Key Takeaways

- GitHub Actions automates development workflows.
- CI validates code before deployment.
- CD automates application delivery.
- Workflows are composed of Jobs.
- Jobs are composed of Steps.
- Runners execute Workflows.
- Actions provide reusable automation.
- GitHub Actions integrates naturally with ArgoCD to build a complete GitOps pipeline.