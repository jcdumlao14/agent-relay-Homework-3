# Homework 4: DevOps and Observability for AI-Built Apps

**Project:** Agent Relay
**Course:** DataTalksClub AI Dev Tools Zoomcamp 2026
**Homework:** 4 — DevOps and Observability for AI-Built Apps
**Branch:** `homework-4`
**Final commit:** `716e77b` — `Complete HW4 security observability and incident response`

---

## Overview

Homework 4 extends the Agent Relay application from Homework 3 with an operational and security layer for detecting, investigating, responding to, and auditing production incidents.

The implementation follows the complete incident-response loop:

```text
change
  ↓
observe user impact
  ↓
alert with context
  ↓
collect bounded evidence
  ↓
investigate with a read-only responder
  ↓
apply an explicit autonomy policy
  ↓
authorize or escalate a bounded response
  ↓
verify recovery
  ↓
audit the code and response trail
```

The responder is intentionally **read-only by default**. Model confidence is treated as information rather than authorization. Any mutating recovery action must be explicitly allowlisted and approved outside the model.

---

# Homework Questions

## Question 1 — Instrumentation

### Correct answer

**Metrics, logs, and traces**

The Agent Relay application was instrumented with OpenTelemetry-compatible telemetry covering the three core observability signals:

* **Metrics** — request counts, errors, latency, and application-level operational measurements
* **Logs** — structured application events suitable for incident investigation
* **Traces** — request-level traces connecting application activity across the telemetry pipeline

The implementation also avoids exposing credentials or sensitive authentication material through application logs.

The main application instrumentation is implemented in:

```text
observability.py
```

---

# Question 2 — The Telemetry Pipeline

### Correct answer

**OpenTelemetry**

The observability stack uses OpenTelemetry as the vendor-neutral instrumentation and collection layer.

The implemented telemetry architecture is:

```text
                    ┌─────────────────┐
                    │   Agent Relay   │
                    │                 │
                    │ Metrics         │
                    │ Logs            │
                    │ Traces          │
                    └────────┬────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ OpenTelemetry       │
                  │ Collector           │
                  └──────┬──────┬───────┘
                         │      │
              ┌──────────┘      └──────────┐
              ▼                            ▼
        ┌───────────┐                ┌───────────┐
        │ Prometheus│                │   Tempo   │
        │  Metrics  │                │   Traces  │
        └───────────┘                └───────────┘
              │                            │
              └────────────┬───────────────┘
                           ▼
                     ┌───────────┐
                     │  Grafana  │
                     │  Observe  │
                     └───────────┘
```

Relevant configuration is located under:

```text
observability/
├── collector.yaml
├── prometheus.yaml
├── tempo.yaml
├── compose.yaml
├── dashboard.json
├── alerts.yaml
└── grafana/
    └── provisioning/
```

---

# Question 3 — Dashboards

### Correct answer

**Grafana**

Grafana provides the unified operational view for the telemetry stack.

The project includes a Grafana dashboard configuration:

```text
observability/dashboard.json
```

Grafana is used to correlate operational signals rather than relying on a single infrastructure metric such as CPU utilization.

---

# Question 4 — Alerts

### Correct answer

**Real user impact, with context to start investigating**

The implementation includes an application-level alert for Agent Relay claim failures.

The alert focuses on the actual user-facing operation:

```text
POST /api/v1/tasks/claim
```

rather than using a generic infrastructure threshold such as CPU utilization.

The alert configuration is stored in:

```text
observability/alerts.yaml
```

The incident used for the Homework 4 evidence packet is:

```text
INC-20260924-CLAIM-001
```

The corresponding alert is:

```text
AgentRelayClaimFailures
```

with:

```text
severity: critical
impact classification: user
```

The incident metadata identifies the affected route as:

```text
POST /api/v1/tasks/claim
```

---

# Question 5 — Evidence First

### Correct answer

**With read-only, allowlisted queries**

The responder does not receive general production credentials.

Evidence collection is bounded to explicitly allowlisted read-only sources.

The collection process can inspect:

```text
GET /health
GET /ready
GET /api/v1/alerts
GET /api/v1/rules
GET /api/v1/query
GET /api/v1/query_range
GET /api/search
```

The evidence collector is:

```text
incident-response/collect-evidence.sh
```

The incident evidence packet is stored under:

```text
incident-response/incidents/INC-20260924-CLAIM-001/
```

It contains:

```text
claim-failure-increase.json
claim-failures.json
health.json
http-requests.json
metadata.json
prometheus-alerts.json
prometheus-rules.json
ready.json
```

The collection mode recorded in the incident metadata is:

```text
read_only
```

and:

```text
credentials_included: false
```

This creates a bounded evidence boundary before the model is involved.

---

# Question 6 — The Agent Responder

### Correct answer

**The autonomy policy and allowlists — code outside the model**

The responder operates as a read-only first responder.

Its responsibilities are limited to:

1. Inspecting the supplied evidence
2. Identifying observed symptoms
3. Identifying plausible causes
4. Recommending an action
5. Requesting escalation when necessary

The responder must not independently:

* modify the database
* claim tasks
* complete tasks
* fail tasks
* register agents
* execute arbitrary shell commands
* execute arbitrary HTTP mutations
* rotate credentials
* use credentials supplied inside evidence
* perform a recovery action merely because its confidence is high

The responder specification is:

```text
incident-response/responder-task.md
```

The structured response schema is:

```text
incident-response/response.schema.json
```

---

# Autonomy and Authorization

The autonomy policy is defined in:

```text
incident-response/autonomy-policy.yaml
```

Three operational levels are defined.

### Read-only

Allowed:

```text
observe
verify
summarize
recommend
```

Mutation:

```text
not allowed
```

Human approval:

```text
not required
```

### Proposed

Allowed:

```text
observe
verify
summarize
recommend
propose_rollback
```

Mutation:

```text
not allowed
```

Human approval:

```text
required for proposed mutation
```

### Approved

Allowed:

```text
observe
verify
rollback
```

Mutation:

```text
allowed only for explicitly allowlisted recovery actions
```

Human approval:

```text
required
```

The central authorization rule is:

```text
Model confidence is not permission.
```

A high confidence score does not grant the model authority to perform a mutation.

---

# Question 7 — Security Audit

### Correct answer

**Semgrep**

A deterministic Semgrep security scan was performed as part of the security audit.

The initial audit identified security issues including:

* mutable GitHub Actions references
* container execution as root
* Kubernetes security-context weaknesses
* privilege escalation configuration
* dependency freshness/cooldown concerns
* potential credential disclosure through worker logging

These findings were addressed.

The final Semgrep scan produced:

```text
Findings: 0
Rules run: 350
Targets scanned: 65
Parsed lines: ~100%
Results: 0
Errors: 0
```

The final scan artifact is:

```text
security-audit/runs/semgrep-results-final.json
```

The original audit result is intentionally preserved as:

```text
security-audit/runs/semgrep-results.json
```

The security audit documentation is located in:

```text
security-audit/
├── audit-brief.md
├── capability-table.md
├── findings.schema.json
└── runs/
    ├── provenance.json
    ├── scanner-provenance.json
    ├── semgrep-results.json
    └── semgrep-results-final.json
```

> The Semgrep result represents the executed Semgrep OSS scan. It should not be interpreted as coverage from unavailable Semgrep Pro rules.

---

# Security Hardening

The Docker image was hardened to run the application as an unprivileged user.

The final Docker configuration uses:

```text
USER 1000:1000
```

Runtime verification confirmed:

```text
uid=1000(appuser)
gid=1000(appuser)
groups=1000(appuser)
```

The Kubernetes Agent Relay deployment uses:

```yaml
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
```

and the container uses:

```yaml
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
```

PostgreSQL was also configured with a non-root security context and restricted capabilities.

---

# GitHub Actions Security

GitHub Actions dependencies were changed from mutable version references to full commit SHA references.

The pinned actions include:

```text
actions/checkout
actions/setup-python
astral-sh/setup-uv
helm/kind-action
```

Full commit SHA pinning makes workflow dependencies deterministic and reduces the risk associated with mutable action references.

---

# Dependency Reproducibility

The project uses `uv` for Python dependency management.

The project configuration includes a dependency freshness constraint:

```toml
[tool.uv]
package = false
exclude-newer = "7 days"
```

The lock file was regenerated and validated.

The following verification passed:

```text
uv lock --check
```

---

# Incident: INC-20260924-CLAIM-001

## Incident type

```text
task_claim_failure
```

## Service

```text
agent-relay
```

## Affected operation

```text
POST /api/v1/tasks/claim
```

## Impact

Workers may be unable to claim tasks.

The alert associated with the incident was:

```text
AgentRelayClaimFailures
```

with critical severity.

---

## Evidence

The incident packet contains evidence from:

```text
Agent Relay /health
Agent Relay /ready
Prometheus /api/v1/alerts
Prometheus /api/v1/rules
Prometheus /api/v1/query
```

The observed claim-error metric initially reported:

```text
agent_relay_claim_errors_total = 2
```

A subsequent increase query reported:

```text
increase = 0
```

This evidence indicates that the observed claim-error count was not continuing to increase during the later verification period.

---

# Recovery Runbooks

The incident-response package includes bounded recovery runbooks:

```text
incident-response/runbooks/rollback.sh
incident-response/runbooks/verify-recovery.sh
```

Rollback is not automatically authorized merely because the responder recommends it.

The authorization chain is:

```text
Responder recommendation
        ↓
Autonomy policy
        ↓
Allowlist check
        ↓
Human approval
        ↓
Approval token
        ↓
Bounded runbook execution
        ↓
Independent recovery verification
```

If the required authorization is unavailable, the responder stops at recommendation/escalation.

---

# Agent Capability Inventory

The responder capability table is maintained in:

```text
security-audit/capability-table.md
```

Read-only capabilities include:

```text
Read health
Read readiness
Read Prometheus alerts
Read Prometheus rules
Read Prometheus metrics
Read Tempo evidence
Summarize incident
Recommend recovery
```

Mutating or privileged capabilities remain restricted.

The following operations are explicitly denied to the responder:

```text
Create task
Claim task
Complete task
Fail task
Register agent
Modify database
Delete database data
Database schema changes
Arbitrary shell execution
Arbitrary HTTP mutation
Credential rotation
```

---

# Docker and Kubernetes Verification

The final Docker image was built as:

```text
agent-relay:q4
```

The image was tested for:

* successful build
* non-root execution
* application health
* application readiness

The resulting application responded successfully to:

```text
/health
/ready
```

with:

```json
{"status":"ok"}
```

and:

```json
{"status":"ready"}
```

The Kubernetes deployment was also verified with Agent Relay and PostgreSQL pods running successfully.

---

# Testing

The application test suite passed:

```text
4 passed
```

The test command was:

```powershell
pytest -q
```

The suite produced one Starlette/httpx deprecation warning, but no test failures.

---

# Repository Structure

The main Homework 4 additions are organized as follows:

```text
agent-relay/
│
├── incident-response/
│   ├── autonomy-policy.yaml
│   ├── collect-evidence.sh
│   ├── responder-task.md
│   ├── response.schema.json
│   ├── incidents/
│   │   └── INC-20260924-CLAIM-001/
│   │       ├── claim-failure-increase.json
│   │       ├── claim-failures.json
│   │       ├── health.json
│   │       ├── http-requests.json
│   │       ├── metadata.json
│   │       ├── prometheus-alerts.json
│   │       ├── prometheus-rules.json
│   │       └── ready.json
│   └── runbooks/
│       ├── rollback.sh
│       └── verify-recovery.sh
│
├── observability/
│   ├── alerts.yaml
│   ├── collector.yaml
│   ├── compose.yaml
│   ├── dashboard.json
│   ├── prometheus.yaml
│   ├── tempo.yaml
│   └── grafana/
│       └── provisioning/
│
├── security-audit/
│   ├── audit-brief.md
│   ├── capability-table.md
│   ├── findings.schema.json
│   └── runs/
│       ├── provenance.json
│       ├── scanner-provenance.json
│       ├── semgrep-results.json
│       └── semgrep-results-final.json
│
├── observability.py
├── Dockerfile
├── compose.yaml
├── k8s/
├── worker.py
├── pyproject.toml
└── uv.lock
```

---

# Reproducibility

## Run tests

```powershell
pytest -q
```

## Validate the dependency lock

```powershell
uv lock --check
```

## Build the Docker image

```powershell
docker build -t agent-relay:q4 .
```

## Check the image user

```powershell
docker image inspect agent-relay:q4 --format '{{.Config.User}}'
```

Expected:

```text
1000:1000
```

## Run the security scan

```powershell
semgrep scan --config=auto --json --output=security-audit/runs/semgrep-results-final.json .
```

## Inspect Kubernetes resources

```powershell
kubectl get pods -n agent-relay
kubectl get services -n agent-relay
kubectl get deployments -n agent-relay
```

---

# Final Git State

Homework 4 was committed and pushed to the dedicated branch:

```text
Branch:
homework-4
```

Final commit:

```text
716e77b Complete HW4 security observability and incident response
```

The final verification confirmed:

```text
## homework-4...origin/homework-4
```

with no ahead/behind indicator.

Therefore the local branch and GitHub branch are synchronized.

---

# Homework 4 Question Summary

| Question | Topic              | Implemented Result                                |
| -------- | ------------------ | ------------------------------------------------- |
| Q1       | Instrumentation    | Metrics, logs, and traces                         |
| Q2       | Telemetry pipeline | OpenTelemetry                                     |
| Q3       | Dashboards         | Grafana                                           |
| Q4       | Alerts             | Real user impact with investigation context       |
| Q5       | Evidence           | Read-only, allowlisted queries                    |
| Q6       | Agent responder    | Autonomy policy and allowlists                    |
| Q7       | Security audit     | Semgrep                                           |
| Q8       | Incident report    | Incident evidence and response artifacts prepared |

---

# Security Principle

The central design principle of this implementation is:

```text
A model can recommend an action,
but the model does not authorize the action.
```

Authorization is enforced outside the model through:

```text
policy
+ allowlists
+ approval requirements
+ bounded runbooks
+ independent recovery verification
```

This separates **reasoning** from **execution authority** and keeps the AI responder within a controlled operational boundary.

---

# Final Result

Homework 4 extends Agent Relay from a deployed application into an observable and auditable operational system.

The resulting workflow can:

```text
detect
  ↓
measure user impact
  ↓
alert
  ↓
collect evidence
  ↓
investigate
  ↓
propose
  ↓
authorize or escalate
  ↓
recover
  ↓
verify
  ↓
audit
```

The implementation demonstrates that AI-assisted incident response can be integrated into DevOps workflows while keeping credentials, authorization, mutation, and recovery controls outside the model.
