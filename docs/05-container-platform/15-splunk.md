# Splunk Cloud Integration with Amazon EKS

## Overview

This lab demonstrates how to integrate an Amazon EKS Kubernetes cluster with Splunk Cloud for centralized log collection, searching, analysis, and visualization.

The Splunk OpenTelemetry Collector is deployed inside the EKS cluster using Helm. The collector gathers Kubernetes container logs and Kubernetes events and forwards them securely to Splunk Cloud using the HTTP Event Collector (HEC).

After configuring log ingestion, Splunk Search Processing Language (SPL) is used to analyze application logs, Kubernetes metadata, and application errors.

Finally, a Splunk dashboard is created to visualize application errors and log activity by Kubernetes Pod.

---

## Objectives

The objectives of this lab are to:

- Configure Splunk Cloud for Kubernetes log ingestion.
- Create and configure an HTTP Event Collector (HEC) token.
- Store the HEC token securely as a Kubernetes Secret.
- Configure the Splunk OpenTelemetry Collector.
- Deploy the collector to Amazon EKS using Helm.
- Verify that Kubernetes logs are reaching Splunk Cloud.
- Search application logs using SPL.
- Analyze Kubernetes metadata.
- Detect application errors.
- Aggregate errors by Kubernetes Pod.
- Create Splunk visualizations.
- Build a Kubernetes monitoring dashboard.

---

## Architecture

```text
                    AWS Cloud
                       |
                 Amazon EKS
                       |
        +--------------+--------------+
        |                             |
 Application Containers       Kubernetes Events
        |                             |
        +--------------+--------------+
                       |
             Splunk OpenTelemetry
                  Collector
                       |
                       | HTTPS
                       | HEC
                       v
                 Splunk Cloud
                       |
                  index=main
                       |
              Search & Reporting
                       |
                  SPL Queries
                       |
               Visualizations
                       |
                   Dashboard
```

---

## Technologies Used

| Technology | Purpose |
|---|---|
| Amazon EKS | Managed Kubernetes cluster |
| Kubernetes | Container orchestration |
| Helm | Kubernetes package management |
| Splunk Cloud | Centralized logging and analysis |
| Splunk HEC | HTTP-based log ingestion |
| Splunk OpenTelemetry Collector | Kubernetes log collection |
| SPL | Log searching and analysis |
| kubectl | Kubernetes administration |

---

## Prerequisites

Before starting the lab, the following components must be available:

- An operational Amazon EKS cluster.
- `kubectl` configured to access the EKS cluster.
- Helm installed on the management machine.
- Access to a Splunk Cloud environment.
- A Kubernetes application running inside the cluster.
- Internet connectivity from the EKS worker nodes to Splunk Cloud.

Verify access to the Kubernetes cluster:

```bash
kubectl get nodes
```

Verify the application Pods:

```bash
kubectl get pods -n default
```

The application used in this lab has Pods matching:

```text
container-platform-app-*
```

---

# 1. Access Splunk Cloud

Log in to the Splunk Cloud environment.

The Splunk Cloud interface provides access to several components including:

- Search & Reporting
- Dashboards
- Alerts
- Data Management
- Splunk Observability Cloud

For this lab, **Search & Reporting** is primarily used to search and analyze Kubernetes logs.

![Splunk Cloud Home](screenshots/splunk-cloud-home.png)

**Screenshot:** `splunk-cloud-home.png`

This confirms that the Splunk Cloud environment is available and ready to receive Kubernetes log data.

---

# 2. Configure the HTTP Event Collector (HEC)

Splunk HTTP Event Collector (HEC) allows applications and services to send log and event data directly to Splunk over HTTP or HTTPS.

In this lab, HEC is used by the Splunk OpenTelemetry Collector running inside the EKS cluster to forward Kubernetes logs to Splunk Cloud.

---

## 2.1 Create the HEC Token

From Splunk Cloud, navigate to:

```text
Settings
→ Data Inputs
→ HTTP Event Collector
→ New Token
```

Create a new HEC token for the Kubernetes environment.

The token used in this lab was configured for Kubernetes EKS logs.

After completing the configuration, Splunk confirms that the token was successfully created.

![Splunk HEC Token Created](screenshots/splunk-hec-token-created.png)

**Screenshot:** `splunk-hec-token-created.png`

> **Security Note:** Never store or commit the HEC token directly in a Git repository. The token should be stored securely using a Kubernetes Secret or another secrets management solution.

---

## 2.2 Verify the HEC Token

Navigate to:

```text
Settings
→ Data Inputs
→ HTTP Event Collector
```

Verify that the HEC token appears in the list.

The configuration used in this lab includes:

```text
Name: eks-kubernetes-logs
Index: main
Status: Enabled
```

![Splunk HEC Token Enabled](screenshots/splunk-hec-token-enabled.png)

**Screenshot:** `splunk-hec-token-enabled.png`

The **Enabled** status confirms that Splunk Cloud is ready to receive events using this HEC token.

---

# 3. Create the Kubernetes Namespace

A dedicated Kubernetes namespace is used for the Splunk OpenTelemetry Collector.

Create the namespace:

```bash
kubectl create namespace splunk
```

Verify it:

```bash
kubectl get namespaces
```

The Splunk components will be deployed into:

```text
splunk
```

---

# 4. Store the HEC Token as a Kubernetes Secret

Instead of storing the Splunk HEC token directly inside the Helm values file, create a Kubernetes Secret.

Create the secret:

```bash
kubectl create secret generic splunk-hec-secret \
  --namespace splunk \
  --from-literal=splunk_hec_token='<YOUR_HEC_TOKEN>'
```

Verify that the Secret exists:

```bash
kubectl get secrets -n splunk
```

Expected Secret:

```text
splunk-hec-secret
```

The actual token should never be displayed or committed to Git.

---

# 5. Configure the Splunk OpenTelemetry Collector

Navigate to the Splunk directory in the homelab repository:

```bash
cd ~/devops_projects_git/homelab-devops/05-container-platform/splunk
```

Create the Helm configuration file:

```bash
nano splunk-values.yaml
```

Configure the collector:

```yaml
clusterName: "container-platform-eks"
distribution: "eks"

splunkPlatform:
  endpoint: "https://<YOUR-SPLUNK-HEC-ENDPOINT>:443/services/collector/event"
  index: "main"
  logsEnabled: true
  metricsEnabled: false
  tracesEnabled: false
  insecureSkipVerify: true

secret:
  create: false
  name: "splunk-hec-secret"
```

In this configuration:

| Setting | Purpose |
|---|---|
| `clusterName` | Identifies the Kubernetes cluster in Splunk |
| `distribution` | Specifies Amazon EKS |
| `endpoint` | Splunk Cloud HEC endpoint |
| `index` | Splunk index receiving the logs |
| `logsEnabled` | Enables Kubernetes log collection |
| `metricsEnabled` | Disables metric collection for this lab |
| `tracesEnabled` | Disables distributed tracing |
| `secret.name` | References the Kubernetes Secret containing the HEC token |

The HEC token itself is **not stored in this file**.

---

## 5.1 Review the Configuration

Verify the configuration before deploying the collector:

```bash
cat splunk-values.yaml
```

At this point, the EKS cluster is configured to use:

```text
EKS
 |
 | Kubernetes logs
 v
Splunk OpenTelemetry Collector
 |
 | HEC / HTTPS
 v
Splunk Cloud
 |
 v
index=main
```

---

# 6. Deploy the Splunk OpenTelemetry Collector

The Splunk OpenTelemetry Collector is deployed to the EKS cluster using Helm.

The collector runs inside Kubernetes and collects logs from the cluster before forwarding them to Splunk Cloud through the configured HEC endpoint.

---

## 6.1 Install the Splunk OpenTelemetry Collector

Install the collector using the `splunk-values.yaml` configuration file:

```bash
helm install splunk-otel-collector \
  splunk-otel-collector-chart/splunk-otel-collector \
  --namespace splunk \
  -f splunk-values.yaml
```

After the installation completes successfully, Helm should report:

```text
STATUS: deployed
```

---

## 6.2 Verify the Helm Deployment

Verify that the Helm release was successfully installed:

```bash
helm list -n splunk
```

Expected release:

```text
splunk-otel-collector
```

The release should show:

```text
STATUS: deployed
```

---

## 6.3 Verify the OpenTelemetry Collector Pods

Check the Pods created by the Helm chart:

```bash
kubectl get pods -n splunk -o wide
```

The deployment creates OpenTelemetry Collector components across the EKS cluster.

Example:

```text
splunk-otel-collector-agent-xxxxx
splunk-otel-collector-agent-xxxxx
splunk-otel-collector-agent-xxxxx
splunk-otel-collector-k8s-cluster-receiver-xxxxx
```

All Pods should report:

```text
READY   1/1
STATUS  Running
```

![Splunk OpenTelemetry Collector Running](screenshots/splunk-otel-collector-running.png)

**Screenshot:** `splunk-otel-collector-running.png`

This screenshot validates three important components of the deployment:

- The Helm release is deployed successfully.
- The OpenTelemetry Collector Pods are running.
- Collector agents are distributed across the EKS worker nodes.

---

## 6.4 Understand the Collector Components

The Splunk OpenTelemetry deployment contains different components with different responsibilities.

### Collector Agents

The agent Pods run across the Kubernetes worker nodes and collect telemetry from workloads running on those nodes.

In this lab, they are primarily responsible for collecting container logs.

Conceptually:

```text
Worker Node
    |
    +-- Application Pod
    |
    +-- Splunk OTel Agent
             |
             +-- Collect container logs
```

### Kubernetes Cluster Receiver

The Kubernetes cluster receiver collects cluster-level Kubernetes information and events.

```text
EKS Cluster
    |
    +-- Kubernetes API
            |
            v
    K8s Cluster Receiver
```

Together, these components provide Kubernetes telemetry to the Splunk OpenTelemetry Collector pipeline.

---

# 7. Validate Log Ingestion in Splunk Cloud

After deploying the collector, verify that data from the EKS cluster is reaching Splunk Cloud.

Open:

```text
Search & Reporting
```

Run the following SPL query:

```spl
index=main
```

Set the time range to:

```text
Last 15 minutes
```

Splunk should return events collected from the Kubernetes cluster.

![Kubernetes Logs Received](screenshots/splunk-kubernetes-logs-received.png)

**Screenshot:** `splunk-kubernetes-logs-received.png`

The returned events contain Kubernetes and container metadata such as:

```text
cloud.provider
cloud.region
container.id
container.image.name
container.image.tag
host.name
k8s.cluster.name
k8s.namespace.name
k8s.node.name
k8s.pod.name
logtag
logstream
```

The presence of these fields confirms that the OpenTelemetry Collector is enriching the logs with Kubernetes metadata before forwarding them to Splunk Cloud.

---

## 7.1 Validate the End-to-End Logging Pipeline

At this point, the complete logging pipeline can be validated:

```text
Application Pod
      |
      | stdout / stderr
      v
Kubernetes Container Logs
      |
      v
Splunk OpenTelemetry Collector
      |
      | HTTPS / HEC
      v
Splunk Cloud
      |
      v
index=main
```

The successful `index=main` search confirms that the end-to-end integration is operational.

---

## Validation

The following components have now been validated:

- Splunk Cloud HEC is enabled.
- The Kubernetes Secret contains the HEC credentials.
- The Helm release is deployed.
- OpenTelemetry Collector Pods are running.
- Kubernetes logs are being collected.
- Logs are successfully reaching Splunk Cloud.
- Kubernetes metadata is available for SPL searches.

---

# 8. Search Application Logs

After confirming that Kubernetes logs are reaching Splunk Cloud, the next step is to isolate the logs generated by the application deployed in the EKS cluster.

The application Pods use the following naming pattern:

```text
container-platform-app-*
```

Run the following SPL query:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
```

This query filters the events using:

- The `main` Splunk index.
- The Kubernetes `default` namespace.
- Pods whose names begin with `container-platform-app`.

![Container Platform Application Logs](screenshots/splunk-container-platform-app-logs.png)

**Screenshot:** `splunk-container-platform-app-logs.png`

The results confirm that Splunk can identify logs generated specifically by the application running inside the EKS cluster.

The events also contain Kubernetes metadata such as:

```text
k8s.cluster.name
k8s.namespace.name
k8s.node.name
k8s.pod.name
container.image.name
container.image.tag
host.name
sourcetype
```

This metadata allows Splunk searches to correlate application logs with the Kubernetes infrastructure where the containers are running.

---

# 9. Analyze Application Logs by Pod and Node

Splunk can aggregate the collected logs using Kubernetes metadata.

Run:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
| stats count by k8s.pod.name, k8s.node.name, sourcetype
```

The `stats` command groups the events according to:

```text
Pod
Node
Sourcetype
```

![Container Platform Application Log Summary](screenshots/splunk-container-platform-app-log-summary.png)

**Screenshot:** `splunk-container-platform-app-log-summary.png`

Example results include application Pods running across different EKS worker nodes.

The results can also contain multiple Splunk sourcetypes, including:

```text
kube:container:application
kube:events
```

---

## 9.1 Understanding the SPL Query

The first part selects the application logs:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
```

The following command aggregates the events:

```spl
| stats count by k8s.pod.name, k8s.node.name, sourcetype
```

The resulting table makes it possible to determine:

- Which Pods are generating events.
- Which Kubernetes nodes are running those Pods.
- What type of Kubernetes data Splunk received.
- How many events were associated with each combination.

---

## 9.2 Kubernetes Observability with Metadata

Without Kubernetes metadata, a log might only contain application information such as:

```text
Container Platform App running on port 8080
```

With the metadata collected by the Splunk OpenTelemetry Collector, the same event can be associated with infrastructure information:

```text
Application
    |
    v
container-platform-app
    |
    +-- Pod
    |
    +-- Namespace
    |
    +-- Worker Node
    |
    +-- Container
    |
    +-- Container Image
    |
    +-- EKS Cluster
```

This is important when troubleshooting distributed applications because containers and Pods can be dynamically created, terminated, or moved between Kubernetes nodes.

---

# 10. Search for Application Errors

The next step is to identify application errors inside the collected logs.

Run:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
("error" OR "failed" OR "exception")
```

This query searches the application events for common error indicators.

![Kubernetes Application Error Search](screenshots/splunk-kubernetes-error-search.png)

**Screenshot:** `splunk-kubernetes-error-search.png`

The search successfully identifies application error events such as:

```text
npm error
command failed
```

This demonstrates one of the main advantages of centralized logging: application failures can be investigated without connecting directly to individual Kubernetes Pods.

Instead of checking logs individually with:

```bash
kubectl logs <pod-name>
```

Splunk provides a centralized view:

```text
Pod A ----\
Pod B -----\
Pod C ------> Splunk Cloud ---> Search / Analysis
Pod D -----/
```

---

## 10.1 Why Centralized Logging Matters in Kubernetes

Kubernetes workloads are dynamic.

A failed Pod may be deleted and replaced automatically by a new Pod. This makes relying exclusively on local container logs difficult during troubleshooting.

Centralized logging allows logs to remain searchable independently of the lifecycle of an individual Pod.

The workflow becomes:

```text
Application failure
       |
       v
Container log
       |
       v
Splunk OpenTelemetry Collector
       |
       v
Splunk Cloud
       |
       v
SPL Search
       |
       v
Identify affected Pod
```

This provides a more practical troubleshooting workflow for Kubernetes environments.

---


# 11. Aggregate Application Errors by Pod

After identifying application errors, SPL can be used to determine which Kubernetes Pods are generating those errors.

Run:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
("error" OR "failed" OR "exception")
| stats count AS error_count by k8s.pod.name
| sort - error_count
```

This query:

1. Searches the `main` index.
2. Filters events from the `default` namespace.
3. Selects the `container-platform-app` Pods.
4. Searches for common error patterns.
5. Counts the errors generated by each Pod.
6. Sorts the results by error count.

The resulting table provides a simple way to identify which application instances are generating errors.

![Kubernetes Errors by Pod](screenshots/splunk-kubernetes-errors-by-pod.png)

**Screenshot:** `splunk-kubernetes-errors-by-pod.png`

In this example, Splunk identified errors associated with multiple application Pods.

This provides a useful troubleshooting workflow:

```text
Application Error
       |
       v
Splunk Search
       |
       v
Identify Pod
       |
       v
Compare Error Counts
       |
       v
Investigate Workload
```

---

# 12. Create an Error Visualization

The SPL results can be converted into a visualization to make the error distribution easier to understand.

After executing:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
("error" OR "failed" OR "exception")
| stats count AS error_count by k8s.pod.name
| sort - error_count
```

Open:

```text
Visualization
```

Select a:

```text
Column Chart
```

The X-axis represents:

```text
k8s.pod.name
```

The Y-axis represents:

```text
error_count
```

![Application Errors by Pod Visualization](screenshots/splunk-errors-by-pod-visualization.png)

**Screenshot:** `splunk-errors-by-pod-visualization.png`

The visualization makes it possible to quickly compare the number of errors generated by each Kubernetes Pod.

---

# 13. Create the Kubernetes EKS Dashboard

The visualization was saved to a Splunk dashboard.

Create a dashboard named:

```text
Kubernetes EKS Monitoring
```

The dashboard provides a centralized view of application logging information collected from the EKS cluster.

---

## 13.1 Application Errors by Pod

The first dashboard panel displays application errors grouped by Kubernetes Pod.

Panel name:

```text
Application Errors by Pod
```

The panel is based on:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
("error" OR "failed" OR "exception")
| stats count AS error_count by k8s.pod.name
| sort - error_count
```

---

## 13.2 Log Volume by Pod

A second panel was added to display the total number of collected events associated with each application Pod.

The SPL query is:

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
| stats count AS log_count by k8s.pod.name
| sort - log_count
```

Panel name:

```text
Log Volume by Pod
```

This panel helps identify how log activity is distributed across application instances.

---

## 13.3 Configure the Global Time Range

Initially, the dashboard panels were configured with a static time range.

This caused the panels to return:

```text
No search results returned
```

even when the dashboard Global Time Range was changed.

The panel data sources were modified from:

```text
Time Range: Static
```

to:

```text
Time Range: Input
Input: Global Time Range (global_time)
```

This allows both dashboard panels to use the time range selected at the dashboard level.

The final dashboard was validated using:

```text
Last 24 hours
```

![Kubernetes EKS Monitoring Dashboard](screenshots/splunk-kubernetes-dashboard-errors-by-pod.png)

**Screenshot:** `splunk-kubernetes-dashboard-errors-by-pod.png`

The final dashboard contains:

```text
Kubernetes EKS Monitoring
│
├── Application Errors by Pod
│
└── Log Volume by Pod
```

---

# 14. Final End-to-End Validation

At this point, the complete centralized logging architecture has been validated.

```text
Amazon EKS
     |
     v
Kubernetes Pods
     |
     | stdout / stderr
     v
Splunk OpenTelemetry Collector
     |
     | HTTPS
     v
Splunk HTTP Event Collector
     |
     v
Splunk Cloud
     |
     v
index=main
     |
     +---------------------+
     |                     |
     v                     v
 SPL Searches          Dashboard
     |                     |
     v                     v
Troubleshooting       Visualization
```

The lab successfully demonstrated:

- Kubernetes log collection.
- Splunk HEC ingestion.
- Secure HEC token storage using a Kubernetes Secret.
- Splunk OpenTelemetry Collector deployment.
- Kubernetes metadata enrichment.
- Application-specific log filtering.
- SPL log analysis.
- Application error detection.
- Error aggregation by Pod.
- Log volume analysis.
- Splunk visualizations.
- Dashboard creation.
- Dashboard global time filtering.

---

# 15. Troubleshooting Performed

Several real troubleshooting scenarios were encountered during the implementation of the Splunk integration.

## Incorrect HEC Endpoint

The initial HEC hostname could not be resolved.

The collector reported DNS errors similar to:

```text
no such host
```

DNS resolution was tested using:

```bash
nslookup <splunk-hec-hostname>
```

The correct Splunk Cloud input endpoint was then identified and configured.

---

## Validate HEC Connectivity

The HEC health endpoint was tested before troubleshooting the Kubernetes collector further.

Example:

```bash
curl -k \
  -H "Authorization: Splunk <HEC_TOKEN>" \
  https://<SPLUNK-HEC-ENDPOINT>:8088/services/collector/health
```

A healthy HEC endpoint returned:

```json
{"text":"HEC is healthy","code":17}
```

> The real HEC token must never be committed to Git.

---

## Validate HEC Event Ingestion

A test event was manually sent to Splunk:

```bash
curl -k \
  -H "Authorization: Splunk <HEC_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"event":"splunk-hec-test","index":"main","sourcetype":"_json"}' \
  https://<SPLUNK-HEC-ENDPOINT>:8088/services/collector/event
```

A successful request returned:

```json
{"text":"Success","code":0}
```

This isolated the HEC configuration from the Kubernetes collector configuration and confirmed that:

```text
Endpoint + Token + Index = Working
```

---

## Application Logs Initially Missing

The Kubernetes application had been running before the Splunk collector was deployed and was not generating many new application log entries.

The Deployment was restarted:

```bash
kubectl rollout restart deployment/container-platform-app -n default
```

New application Pods were created and generated fresh logs.

Splunk then successfully detected the new application events.

---

## Dashboard Returned No Results

The dashboard initially returned:

```text
No search results returned
```

The problem was caused by individual panel data sources using:

```text
Static → Last 15 minutes
```

instead of the dashboard Global Time Range.

The data sources were changed to:

```text
Input
→ Global Time Range (global_time)
```

After this change, the dashboard successfully displayed data for the selected time range.

---

# 16. Skills Demonstrated

This lab demonstrates practical experience with:

- Splunk Cloud
- Splunk Search & Reporting
- Splunk HTTP Event Collector (HEC)
- Splunk OpenTelemetry Collector
- Amazon EKS
- Kubernetes
- Kubernetes Secrets
- Helm
- Centralized Logging
- Container Log Collection
- Kubernetes Metadata
- SPL (Search Processing Language)
- Log Filtering
- Log Aggregation
- Application Error Analysis
- Kubernetes Troubleshooting
- Splunk Visualizations
- Splunk Dashboard Studio
- Observability
- Cloud-Native Monitoring

The lab also demonstrates the ability to troubleshoot a complete logging pipeline across multiple layers:

```text
Application
    ↓
Kubernetes
    ↓
OpenTelemetry Collector
    ↓
Network / DNS / TLS
    ↓
HEC
    ↓
Splunk Cloud
    ↓
SPL
    ↓
Dashboard
```

---

# 17. Useful Commands

## Verify Splunk Namespace

```bash
kubectl get namespace splunk
```

## Verify Splunk Pods

```bash
kubectl get pods -n splunk
```

For additional information:

```bash
kubectl get pods -n splunk -o wide
```

## Verify Helm Release

```bash
helm list -n splunk
```

## Verify the HEC Secret

```bash
kubectl get secret splunk-hec-secret -n splunk
```

The Secret can be inspected without displaying its actual value:

```bash
kubectl describe secret splunk-hec-secret -n splunk
```

## Check Collector Logs

```bash
kubectl logs -n splunk \
  deployment/splunk-otel-collector-k8s-cluster-receiver \
  --tail=100
```

Search specifically for errors:

```bash
kubectl logs -n splunk \
  deployment/splunk-otel-collector-k8s-cluster-receiver \
  --since=5m \
  | grep -iE "error|failed|unauthorized|forbidden|bad request"
```

## Restart the Application

```bash
kubectl rollout restart deployment/container-platform-app -n default
```

Verify the new Pods:

```bash
kubectl get pods -n default
```

## Check Application Logs Directly

```bash
kubectl logs -n default <POD_NAME> --tail=20
```

---

# 18. Useful SPL Queries

## Search All Kubernetes Logs

```spl
index=main
```

---

## Search Application Logs

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
```

---

## Group Logs by Pod, Node, and Sourcetype

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
| stats count by k8s.pod.name, k8s.node.name, sourcetype
```

---

## Search Application Errors

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
("error" OR "failed" OR "exception")
```

---

## Count Errors by Pod

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
("error" OR "failed" OR "exception")
| stats count AS error_count by k8s.pod.name
| sort - error_count
```

---

## Count Logs by Pod

```spl
index=main k8s.namespace.name="default" k8s.pod.name="container-platform-app*"
| stats count AS log_count by k8s.pod.name
| sort - log_count
```

---

# 19. Cleanup

If the Splunk integration is no longer required, the OpenTelemetry Collector can be removed from the EKS cluster.

Remove the Helm release:

```bash
helm uninstall splunk-otel-collector -n splunk
```

Verify:

```bash
helm list -n splunk
```

Remove the HEC Secret:

```bash
kubectl delete secret splunk-hec-secret -n splunk
```

Remove the namespace:

```bash
kubectl delete namespace splunk
```

> Do not run these commands if the Splunk integration will continue to be used in the homelab.

The Splunk Cloud HEC token can also be disabled or deleted from:

```text
Settings
→ Data Inputs
→ HTTP Event Collector
```

---

# 20. Security Considerations

The Splunk HEC token is a credential and must be protected.

The following practices should be followed:

- Never commit the HEC token to Git.
- Never include the real token in documentation.
- Store credentials using Kubernetes Secrets.
- Avoid displaying Secret values in terminal screenshots.
- Rotate credentials if they are accidentally exposed.
- Disable unused HEC tokens.
- Restrict HEC tokens to only the required indexes.
- Use TLS for communication with Splunk Cloud.

For production environments, secrets should preferably be managed using a dedicated secrets management solution such as:

```text
AWS Secrets Manager
AWS Systems Manager Parameter Store
HashiCorp Vault
External Secrets Operator
```

---

# 21. Interview Questions

## What is Splunk?

Splunk is a platform used to collect, search, analyze, monitor, and visualize machine-generated data such as application logs, infrastructure logs, security events, and operational telemetry.

---

## What is HEC?

HEC stands for:

```text
HTTP Event Collector
```

It allows applications and services to send events to Splunk using HTTP or HTTPS.

In this lab:

```text
Splunk OpenTelemetry Collector
        ↓
       HEC
        ↓
Splunk Cloud
```

---

## What is the Splunk OpenTelemetry Collector?

The Splunk OpenTelemetry Collector is a distribution of the OpenTelemetry Collector that can collect and forward telemetry such as logs, metrics, and traces.

In this lab, it was deployed inside Amazon EKS using Helm and used primarily for Kubernetes log collection.

---

## Why use centralized logging with Kubernetes?

Kubernetes Pods are ephemeral.

A Pod can:

- Restart.
- Fail.
- Be deleted.
- Be replaced.
- Move to another worker node.

Centralized logging allows logs to remain searchable independently of the lifecycle of individual Pods.

---

## What is SPL?

SPL stands for:

```text
Search Processing Language
```

It is Splunk's query language for searching, filtering, transforming, aggregating, and analyzing data.

Example:

```spl
index=main
| stats count by k8s.pod.name
```

---

## What is a Splunk index?

An index is where Splunk stores incoming event data.

This lab used:

```text
index=main
```

The collected Kubernetes logs were sent to this index and queried using SPL.

---

## How did you protect the HEC token?

The HEC token was stored as a Kubernetes Secret instead of being placed directly in the Helm values file or Git repository.

The Helm deployment references the existing Secret.

---

## How did you verify that Splunk HEC was working?

The HEC health endpoint was tested first.

Then a test event was manually submitted to HEC.

A successful request returned:

```json
{"text":"Success","code":0}
```

This confirmed that the endpoint, token, and Splunk index were functioning correctly.

---

## How did you troubleshoot the integration?

The troubleshooting process was performed layer by layer:

```text
1. Verify Kubernetes Pods
        ↓
2. Verify Helm deployment
        ↓
3. Inspect OpenTelemetry Collector logs
        ↓
4. Test DNS resolution
        ↓
5. Test HEC health
        ↓
6. Test HEC token
        ↓
7. Send a manual event
        ↓
8. Search index=main
        ↓
9. Filter application logs
```

This helped isolate problems instead of changing multiple components simultaneously.

---

## What is the difference between Datadog and Splunk in this homelab?

Datadog was primarily used for infrastructure and Kubernetes observability, including metrics, resource monitoring, and alerting.

Splunk was used primarily for centralized logging, log searching, error investigation, SPL analysis, and dashboards.

Together they demonstrate different areas of observability:

```text
Prometheus / Grafana
        ↓
Metrics & Dashboards

Datadog
        ↓
Infrastructure Observability & Alerting

Splunk
        ↓
Centralized Logging & Log Analysis
```

---

# 22. Conclusion

In this lab, Splunk Cloud was successfully integrated with an Amazon EKS cluster to provide centralized Kubernetes logging.

A Splunk HTTP Event Collector token was configured to receive Kubernetes events securely.

The HEC credential was stored as a Kubernetes Secret rather than being embedded directly in configuration files.

The Splunk OpenTelemetry Collector was deployed to Amazon EKS using Helm. Collector agents running across the EKS worker nodes collected Kubernetes container logs and forwarded them to Splunk Cloud.

Log ingestion was validated using:

```spl
index=main
```

Application-specific logs were then isolated using Kubernetes metadata such as:

```text
k8s.namespace.name
k8s.pod.name
k8s.node.name
container.image.name
```

SPL queries were used to identify application errors and aggregate those errors by Kubernetes Pod.

The results were converted into visualizations and added to the:

```text
Kubernetes EKS Monitoring
```

dashboard.

The final dashboard provides visibility into:

```text
Application Errors by Pod
Log Volume by Pod
```

Several real troubleshooting scenarios were also resolved during the implementation, including:

- Incorrect Splunk HEC hostname.
- DNS resolution failures.
- TLS certificate validation.
- HEC configuration validation.
- HEC event ingestion testing.
- Missing application logs.
- Dashboard time-range configuration.

The final architecture successfully demonstrates:

```text
Amazon EKS
     ↓
Kubernetes Workloads
     ↓
Splunk OpenTelemetry Collector
     ↓
HTTP Event Collector
     ↓
Splunk Cloud
     ↓
SPL
     ↓
Centralized Log Analysis
     ↓
Dashboard
```

This lab demonstrates a complete cloud-native centralized logging workflow for Kubernetes using Amazon EKS, OpenTelemetry, Helm, Splunk Cloud, and SPL.