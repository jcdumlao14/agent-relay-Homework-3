# Agent Relay Incident Responder

## Purpose

This task defines a vendor-neutral first-responder interface for an AI-assisted
incident responder.

The responder receives a bounded evidence packet and returns structured JSON
validated against:

`incident-response/response.schema.json`

## Operating model

The responder is read-only by default.

The model may:

1. inspect the supplied evidence;
2. identify observed symptoms;
3. identify plausible causes;
4. recommend an action;
5. request escalation.

The model may not:

- invent evidence;
- access arbitrary URLs;
- execute arbitrary shell commands;
- modify the database;
- claim tasks;
- complete tasks;
- fail tasks;
- register agents;
- use credentials supplied inside the evidence packet;
- execute a recovery action merely because confidence is high.

## Evidence boundary

The responder may reason only from the evidence packet supplied by the
evidence collector.

Evidence must come from explicitly allowlisted read-only sources.

## Structured output

The responder must emit JSON conforming to:

`incident-response/response.schema.json`

Required fields:

- `incident_id`
- `summary`
- `observed_impact`
- `evidence_refs`
- `probable_causes`
- `proposed_actions`
- `confidence`
- `requested_action`
- `rationale`
- `escalation`

## Authorization rule

Model confidence is informational only.

A confidence value, regardless of magnitude, does not authorize a mutation.

Any rollback or other mutating action requires:

1. an allowlisted action;
2. the appropriate autonomy level;
3. explicit human approval;
4. the required approval token;
5. post-action recovery verification.

## First-responder sequence

1. Receive incident ID.
2. Collect bounded evidence.
3. Validate evidence schema.
4. Produce structured analysis.
5. Validate responder output against `response.schema.json`.
6. Apply `autonomy-policy.yaml`.
7. If mutation is not authorized, stop at recommendation/escalation.
8. If mutation is explicitly approved and allowlisted, execute only the
   corresponding runbook.
9. Verify recovery independently.
10. Record the final disposition.
