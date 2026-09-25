# Agent Relay Responder Capability Table

| Capability | Default | Read-only | Proposed | Approved | Human approval |
|---|---|---:|---:|---:|---:|
| Read health | Allowed | Yes | Yes | Yes | No |
| Read readiness | Allowed | Yes | Yes | Yes | No |
| Read Prometheus alerts | Allowed | Yes | Yes | Yes | No |
| Read Prometheus rules | Allowed | Yes | Yes | Yes | No |
| Read Prometheus metrics | Allowed | Yes | Yes | Yes | No |
| Read Tempo evidence | Allowed | Yes | Yes | Yes | No |
| Summarize incident | Allowed | Yes | Yes | Yes | No |
| Recommend recovery | Allowed | Yes | Yes | Yes | No |
| Propose rollback | Restricted | No | Yes | Yes | No |
| Execute rollback | Restricted | No | No | Yes | Yes |
| Create task | Denied | No | No | No | N/A |
| Claim task | Denied | No | No | No | N/A |
| Complete task | Denied | No | No | No | N/A |
| Fail task | Denied | No | No | No | N/A |
| Register agent | Denied | No | No | No | N/A |
| Modify database | Denied | No | No | No | N/A |
| Delete database data | Denied | No | No | No | N/A |
| Arbitrary shell execution | Denied | No | No | No | N/A |
| Arbitrary HTTP mutation | Denied | No | No | No | N/A |
| Credential rotation | Denied | No | No | No | N/A |

## Authorization principle

Model confidence is never treated as authorization.

A model can recommend an action with high confidence while the policy still
blocks that action.

Mutating actions require:

1. an explicitly allowlisted operation;
2. an approved autonomy level;
3. explicit human approval;
4. the required approval token;
5. independent recovery verification.
