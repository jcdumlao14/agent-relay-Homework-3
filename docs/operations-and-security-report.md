# Operations and Security Incident Report

## Agent Relay - Homework 4

**Project:** Agent Relay
**Course:** DataTalksClub AI Dev Tools Zoomcamp 2026
**Homework:** 4 - DevOps and Observability for AI-Built Apps
**Branch:** `homework-4`
**Incident ID:** `INC-20260924-CLAIM-001`
**Service:** `agent-relay`
**Service Version:** `0.1.0`
**Incident Type:** `task_claim_failure`

---

## 1. Incident Summary

Incident `INC-20260924-CLAIM-001` represents a task-claim failure condition affecting the Agent Relay task-claim operation.

The affected endpoint was:

```text
POST /api/v1/tasks/claim
```

The operational concern was that workers may be unable to claim tasks.

The incident was detected through application-level observability rather than relying only on infrastructure-level signals.

The associated alert was:

```text
AgentRelayClaimFailures
```

with:

```text
severity: critical
impact classification: user
```

The incident-response workflow was designed around bounded evidence collection, read-only investigation, explicit authorization policy, and independent recovery verification.

---

## 2. Incident Reconstruction

A reader should be able to reconstruct the incident using the incident identifier:

```text
INC-20260924-CLAIM-001
```

The incident metadata identifies:

* service: `agent-relay`
* service version: `0.1.0`
* affected route: `POST /api/v1/tasks/claim`
* incident type: `task_claim_failure`
* alert: `AgentRelayClaimFailures`
* severity: `critical`
* impact classification: `user`
* collection mode: `read_only`
* credentials included: `false`

The evidence packet is stored under:

```text
incident-response/incidents/INC-20260924-CLAIM-001/
```

The packet contains:

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

---

## 3. User Impact

The observed user impact was:

```text
Workers may be unable to claim tasks.
```

The affected operation was specifically:

```text
POST /api/v1/tasks/claim
```

This represents an application-level operational impact because task workers depend on the claim operation to acquire available work.

The alert therefore focuses on the user-facing operation rather than using an unrelated infrastructure threshold such as CPU utilization.

---

## 4. Alert and Observability Evidence

The incident was associated with:

```text
AgentRelayClaimFailures
```

The observability implementation uses the following signals:

* metrics
* logs
* traces

OpenTelemetry provides the vendor-neutral telemetry instrumentation and collection layer.

The telemetry pipeline is configured under:

```text
observability/
```

with relevant components including:

```text
collector.yaml
prometheus.yaml
tempo.yaml
alerts.yaml
dashboard.json
```

The alert provided investigation context for the affected operation.

---

## 5. Evidence Collection

Evidence collection was explicitly read-only.

The collector was restricted to allowlisted sources including:

```text
GET /health
GET /ready
GET /api/v1/alerts
GET /api/v1/rules
GET /api/v1/query
GET /api/v1/query_range
GET /api/search
```

The evidence collection procedure is implemented in:

```text
incident-response/collect-evidence.sh
```

The incident metadata records:

```text
collection_mode: read_only
credentials_included: false
```

No general production credentials were provided to the responder.

This establishes an evidence boundary before model reasoning occurs.

---

## 6. Evidence Observed

The Prometheus evidence recorded the claim-error metric:

```text
agent_relay_claim_errors_total = 2
```

The subsequent increase query reported:

```text
increase = 0
```

The relevant evidence files are:

```text
claim-failures.json
claim-failure-increase.json
```

The initial value demonstrates that claim errors had been observed.

The later increase result of zero indicates that the claim-error counter was not continuing to increase during the subsequent verification period.

This evidence was used to support the recovery verification step.

---

## 7. Responder Model and Configuration

The AI responder operates as a bounded first responder.

Its specification is:

```text
incident-response/responder-task.md
```

The responder is permitted to:

1. inspect supplied evidence;
2. identify observed symptoms;
3. identify plausible causes;
4. recommend an action;
5. request escalation.

The responder must not independently:

* modify the database;
* claim tasks;
* complete tasks;
* fail tasks;
* register agents;
* execute arbitrary shell commands;
* execute arbitrary HTTP mutations;
* rotate credentials;
* use credentials supplied inside evidence;
* perform a recovery action merely because confidence is high.

The responder output is constrained by:

```text
incident-response/response.schema.json
```

---

## 8. Proposed Action

A recovery action may be proposed after reviewing the bounded evidence.

For this incident, rollback is treated as a restricted recovery operation.

The responder may recommend rollback when supported by the evidence, but the recommendation itself does not authorize execution.

The important separation is:

```text
Model reasoning
        ↓
Recommendation
        ↓
Policy evaluation
        ↓
Human authorization
        ↓
Bounded execution
```

---

## 9. Autonomy Policy Decision

The authorization policy is defined in:

```text
incident-response/autonomy-policy.yaml
```

The default incident-response level is:

```text
read_only
```

The read-only level permits:

```text
observe
verify
summarize
recommend
```

and does not permit mutations.

The proposed level permits an explicit rollback proposal but still does not permit execution.

The approved level permits only explicitly allowlisted recovery actions after human approval.

The central authorization rule is:

```text
Model confidence is not permission.
```

A high confidence value from the responder cannot authorize a mutation.

---

## 10. Allowlisted Recovery

The only explicitly allowlisted mutation in the autonomy policy is:

```text
rollback
```

Rollback execution requires:

1. an allowlisted recovery action;
2. the appropriate autonomy level;
3. explicit human approval;
4. the required approval token;
5. independent recovery verification.

The rollback procedure is bounded by:

```text
incident-response/runbooks/rollback.sh
```

If the required authorization is not available, the responder must stop at recommendation or escalation.

---

## 11. Recovery Verification

Recovery verification is performed independently of the model's confidence.

The verification runbook is:

```text
incident-response/runbooks/verify-recovery.sh
```

The incident evidence includes:

```text
health.json
ready.json
claim-failures.json
claim-failure-increase.json
```

The application health and readiness evidence confirms that the service remained operational.

The later Prometheus increase query reported:

```text
increase = 0
```

which indicates that the observed claim-error counter was not continuing to increase during the verification period.

Recovery verification therefore relies on observed telemetry rather than on a model assertion that the incident is resolved.

---

## 12. Security Controls

The incident-response design explicitly separates model reasoning from execution authority.

The responder is denied the following operations:

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

The capability inventory is maintained in:

```text
security-audit/capability-table.md
```

The responder also operates without production credentials in the evidence packet.

---

## 13. Security Audit

The project was audited using Semgrep.

The final Semgrep OSS scan reported:

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

The original audit result containing the initial findings is preserved as:

```text
security-audit/runs/semgrep-results.json
```

The initial findings included issues involving:

* mutable GitHub Actions references;
* container execution as root;
* Kubernetes security-context configuration;
* privilege escalation;
* dependency freshness/cooldown;
* potential credential disclosure through worker logging.

The remediation work addressed these findings.

The Semgrep result represents the executed Semgrep OSS scan and should not be interpreted as coverage from unavailable Semgrep Pro rules.

---

## 14. Container and Kubernetes Security

The Agent Relay container was hardened to run as an unprivileged user.

The Docker image uses:

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

The container security context also disables privilege escalation and drops Linux capabilities:

```yaml
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
```

PostgreSQL was also configured with a non-root security context and restricted capabilities.

---

## 15. GitHub Actions Security

GitHub Actions dependencies were pinned to full commit SHAs.

The pinned actions include:

```text
actions/checkout
actions/setup-python
astral-sh/setup-uv
helm/kind-action
```

Full SHA pinning reduces the risk associated with mutable workflow references and makes the workflow dependency references deterministic.

---

## 16. Audit Trail

The incident response artifacts preserve the evidence and decision boundaries needed to reconstruct the response.

Relevant artifacts include:

```text
incident-response/
├── autonomy-policy.yaml
├── collect-evidence.sh
├── responder-task.md
├── response.schema.json
├── incidents/
│   └── INC-20260924-CLAIM-001/
└── runbooks/
    ├── rollback.sh
    └── verify-recovery.sh
```

Security audit artifacts are maintained under:

```text
security-audit/
```

including the original and final Semgrep results.

This provides a persistent record of:

* observed impact;
* evidence sources;
* responder constraints;
* proposed actions;
* authorization requirements;
* recovery verification;
* security audit results.

---

## 17. Incident Disposition

The incident evidence shows an observed claim-error condition followed by a verification period in which the claim-error increase was:

```text
0
```

The service health and readiness evidence remained available.

The responder's role is therefore limited to documenting the evidence, recommending bounded recovery when appropriate, and escalating when authorization or evidence is insufficient.

The final recovery state is established through independent telemetry verification rather than model confidence.

---

## 18. Operational Decision Chain

The complete incident-response workflow is:

```text
Change
  ↓
Observe user impact
  ↓
Alert with context
  ↓
Collect bounded evidence
  ↓
Investigate read-only
  ↓
Produce structured recommendation
  ↓
Apply autonomy policy
  ↓
Check allowlist
  ↓
Require human approval for mutation
  ↓
Execute bounded runbook if authorized
  ↓
Verify recovery independently
  ↓
Record the audit trail
```

This sequence keeps the operational authority outside the model.

---

## 19. Key Security Principle

The central security principle is:

```text
A model can recommend an action,
but the model does not authorize the action.
```

Authorization is enforced through:

```text
policy
+ allowlists
+ human approval
+ bounded runbooks
+ independent recovery verification
```

Model confidence is treated as informational and never as an authorization mechanism.

---

## 20. Final Verification

The Homework 4 implementation was committed to:

```text
homework-4
```

The final README commit is:

```text
f27873f Add Homework 4 README
```

The previous Homework 4 implementation commit was:

```text
716e77b Complete HW4 security observability and incident response
```

The branch is synchronized with:

```text
origin/homework-4
```

The working tree was clean before creation of this report.

The complete Homework 4 submission therefore contains:

* observability instrumentation;
* OpenTelemetry telemetry collection;
* Prometheus metrics;
* Tempo traces;
* Grafana dashboard configuration;
* application-level alerting;
* bounded read-only evidence collection;
* structured AI responder constraints;
* explicit autonomy policy;
* allowlisted recovery actions;
* human approval requirements;
* independent recovery verification;
* Semgrep security auditing;
* container and Kubernetes hardening;
* incident evidence and audit artifacts.

---

## Conclusion

Homework 4 extends Agent Relay from a deployed application into an observable, security-hardened, and auditable operational system.

Incident `INC-20260924-CLAIM-001` demonstrates the intended workflow from user-impact detection through bounded evidence collection, investigation, authorization, recovery verification, and audit.

The implementation deliberately separates AI reasoning from operational authority so that the model can assist with investigation and recommendations without independently gaining permission to mutate production state.
