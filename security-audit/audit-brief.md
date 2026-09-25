# Agent Relay Security Audit Brief

## Scope

This audit covers the AI-assisted Agent Relay application and its HW4
incident-response and observability components.

The audit focuses on:

- responder attack surface;
- credential handling;
- authorization boundaries;
- evidence collection;
- model autonomy;
- deployment configuration;
- logging;
- deterministic security scanning;
- model-assisted review;
- human validation;
- provenance and scanner execution records.

## Security principle

The system follows:

> The model may reason; the system must observe, authorize, verify, remember.

Model reasoning is therefore separated from execution authority.

## Audit layers

### 1. Deterministic checks

Deterministic checks are executed independently of model reasoning.

Examples include:

- repository security scanning;
- secret-pattern checks;
- JSON/schema validation;
- Git whitespace validation;
- configuration validation;
- read-only evidence collector inspection.

### 2. Model review

The AI reviewer may analyze deterministic findings and identify additional
risk areas.

The model does not have authority to modify findings or authorize mutations.

### 3. Human validation

A human reviews the deterministic results and model observations before a
security disposition is finalized.

## Credential boundary

Incident evidence must not contain:

- bearer tokens;
- passwords;
- database credentials;
- API keys;
- authorization headers;
- private credentials.

The incident packet for `INC-20260924-CLAIM-001` was checked for common
credential markers and no matches were found.

## Responder boundary

The default responder autonomy level is `read_only`.

Read-only evidence sources are explicitly allowlisted.

Mutating operations are not available to the default responder.

## Mutation gate

Rollback is separated behind:

- approved autonomy level;
- explicit approval;
- approval token;
- allowlisted image target;
- independent recovery verification.

## Provenance

Every audit run records:

- timestamp;
- repository revision;
- scanner/tool;
- command;
- result;
- human disposition.

## Snyk Agent Scan

Snyk Agent Scan is treated as an additional responder attack-surface and
credential/provenance check.

The audit records the availability check and whether an actual scan was
executed. If the scanner is unavailable, that fact is recorded rather than
fabricating a successful result.

## Non-goals

This audit does not claim coverage for:

- penetration testing;
- SBOM generation;
- signed build provenance;
- chaos testing;
- canary deployment;
- progressive delivery;
- SLO/error-budget analysis;
- synthetic monitoring;
- profiling;
- long-term retention/cost optimization.
