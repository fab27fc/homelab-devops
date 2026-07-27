# 01 — Introduction to GitHub Actions

## Objective

Learn the fundamental concepts of GitHub Actions, understand how Continuous Integration (CI) and Continuous Deployment (CD) work, and prepare the foundation for building automated CI/CD pipelines integrated with Kubernetes and ArgoCD.

By the end of this lab, you should understand the architecture of GitHub Actions, its core components, and how it fits into a modern GitOps workflow.

---

# What is GitHub Actions?

GitHub Actions is GitHub's built-in automation platform.

It allows developers to automatically execute workflows whenever specific events occur inside a GitHub repository.

Instead of manually performing repetitive tasks, GitHub Actions executes them automatically.

Common examples include:

- Running automated tests
- Validating YAML files
- Building Docker images
- Deploying applications
- Publishing artifacts
- Running security scans
- Sending notifications

---

# Why do we need GitHub Actions?

Without automation, every code change requires manual work.

Typical manual process:

Developer

↓

Modify code

↓

git add

↓

git commit

↓

git push

↓

Login to server

↓

Build application

↓

Deploy application

↓

Verify deployment

As projects grow, this process becomes slow, repetitive, and error-prone.

GitHub Actions automates these repetitive tasks.

---

# Continuous Integration (CI)

Continuous Integration (CI) is the practice of automatically validating every code change committed to the repository.

Typical CI tasks include:

- Compile source code
- Run automated tests
- Validate YAML syntax
- Check Kubernetes manifests
- Build Docker images
- Perform security scans

Example:

Developer

↓

git push

↓

GitHub Actions

↓

Validate

↓

Test

↓

Build

↓

Success or Failure

CI does **not** necessarily deploy the application.

Its primary goal is to verify that changes are safe.

---

# Continuous Delivery (CD)

Continuous Delivery prepares an application for deployment.

Once all validation steps succeed, the application is ready for production, but deployment requires manual approval.

Developer

↓

Pipeline

↓

Validation

↓

Ready for Production

↓

Manual Approval

---

# Continuous Deployment

Continuous Deployment extends Continuous Delivery by removing the manual approval step.

If every validation succeeds, deployment happens automatically.

Developer

↓

Pipeline

↓

Validation

↓

Deploy Automatically

---

# GitHub Actions Architecture

GitHub Actions executes automation based on events occurring inside a GitHub repository.

Developer

↓

Git Push

↓

GitHub Repository

↓

GitHub Actions

↓

Workflow

↓

Jobs

↓

Steps

↓

Runner

↓

Result

---

# Core Components

## Workflow

A Workflow is a YAML file that defines an automation process.

All workflows are stored inside:

```text
.github/workflows/
```

Each workflow contains one or more jobs.

---

## Event

An Event is what starts a Workflow.

Examples include:

- push
- pull_request
- workflow_dispatch
- release
- schedule

Whenever the configured event occurs, GitHub automatically starts the Workflow.

---

## Job

A Job is a group of related tasks.

A Workflow can contain one or multiple Jobs.

Examples:

- Build
- Test
- Deploy

Jobs can run sequentially or in parallel.

---

## Step

A Step is an individual task inside a Job.

Examples:

- Checkout repository
- Install kubectl
- Validate YAML
- Execute tests

A Job is simply a collection of Steps executed in order.

---

## Runner

A Runner is the machine responsible for executing the Workflow.

There are two types of runners.

### GitHub-hosted Runner

GitHub automatically creates a temporary virtual machine.

Example:

- ubuntu-latest
- windows-latest
- macos-latest

The virtual machine is destroyed after the Workflow finishes.

### Self-hosted Runner

A Self-hosted Runner is a machine managed by you.

Examples:

- Physical server
- Virtual Machine
- Kubernetes node

Self-hosted runners allow complete control over the execution environment.

---

## Action

An Action is a reusable task that can be included inside a Workflow.

Instead of writing complex scripts, developers reuse Actions created by GitHub or the community.

Example:

```yaml
uses: actions/checkout@v4
```

Actions reduce complexity and improve consistency.

---

# GitHub Actions in this Homelab

The current GitOps architecture is:

Git

↓

ArgoCD

↓

Kubernetes

After completing the CI/CD section, the architecture will become:

Developer

↓

Git Push

↓

GitHub Actions

↓

Validation

↓

Git Repository

↓

ArgoCD

↓

Kubernetes

GitHub Actions will provide the Continuous Integration stage.

ArgoCD will provide the Continuous Deployment stage using GitOps.

---

# What We Will Build

During this section we will progressively build a complete CI/CD pipeline capable of:

- Running automatically after every Git push
- Validating YAML syntax
- Validating Kubernetes manifests
- Executing quality checks
- Integrating with ArgoCD
- Deploying applications automatically through GitOps

---

# Expected Result

After completing this introductory lab, you should understand:

- What GitHub Actions is
- The difference between CI and CD
- The purpose of Workflows
- The purpose of Events
- The purpose of Jobs
- The purpose of Steps
- The purpose of Runners
- The purpose of Actions
- How GitHub Actions integrates with ArgoCD

---

# Key Takeaways

- GitHub Actions is GitHub's built-in automation platform.
- CI validates every code change automatically.
- CD automates application delivery.
- A Workflow is composed of Jobs.
- Jobs are composed of Steps.
- Events trigger Workflows.
- Runners execute Workflows.
- Actions are reusable automation components.
- GitHub Actions performs the CI stage.
- ArgoCD performs the GitOps deployment stage.
