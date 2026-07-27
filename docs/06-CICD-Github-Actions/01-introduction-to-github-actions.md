# 01 — Introduction to GitHub Actions

## Objective

Become familiar with the GitHub Actions interface and understand how it fits into the CI/CD workflow that will be built throughout this homelab.

This lab is an introduction only. No workflows are created yet.

---

# Prerequisites

Before starting this lab, complete the following:

- Read the `README.md` in this section.
- Understand the concepts of:
  - Continuous Integration (CI)
  - Continuous Delivery (CD)
  - Workflow
  - Job
  - Step
  - Runner
  - Action

---

# Lab Overview

In this lab we will explore the GitHub Actions interface and understand where workflow executions are displayed.

GitHub Actions is the automation platform that will perform the Continuous Integration (CI) stage of this homelab.

Later labs will use GitHub Actions to validate Kubernetes manifests, build Docker images, and prepare changes before ArgoCD deploys them.

---

# Open the Actions Tab

Open your GitHub repository.

Select:

```
Actions
```

You should see the GitHub Actions dashboard.

At this point there may not be any workflow executions.

This is expected because no workflow has been created yet.

---

# GitHub Actions Dashboard

Become familiar with the interface.

Main sections include:

- Workflow list
- Workflow runs
- Workflow status
- Execution history
- Runner information
- Logs

These sections will be used throughout the remaining labs.

---

# Relationship with the Homelab

Current architecture:

```
Git
 │
 ▼
ArgoCD
 │
 ▼
Kubernetes
```

Target architecture:

```
Developer
      │
      ▼
Git Push
      │
      ▼
GitHub Actions
      │
      ▼
Git Repository
      │
      ▼
ArgoCD
      │
      ▼
Kubernetes
```

GitHub Actions performs the CI stage.

ArgoCD performs the GitOps deployment stage.

---

# Expected Result

After completing this lab you should:

- Know where GitHub Actions is located.
- Understand its purpose.
- Recognize the main sections of the interface.
- Be ready to create your first workflow.

---


