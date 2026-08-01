# Verification Output Templates

Use only the template for the selected mode. Omit empty optional detail, but do
not omit Evidence Identity, Contract Authority, Cannot Verify, the verdict, or
the separate workflow action and code-review status.

## Contents

- Light Mode
- Standard Mode
- High-Risk Mode

## Light Mode

```text
Agent Work Verification - Light

Verification Verdict:
[VERIFIED / PARTIALLY_VERIFIED / NOT_VERIFIED / MISALIGNED / UNSAFE_TO_MERGE]

Task Contract And Authority:
- Required:
- Authority:

Evidence Identity:
- Reviewed change/snapshot:
- Worktree state and dirty snapshot identity:
- Evidence executed against:
- Evidence source:

Task Vs Work:
- Agent did:
- Snapshot-bound evidence:
- Unsupported or rejected evidence:

Cannot Verify:
- ...

Next Action:
- Verification verdict:
- Workflow action:
- Code review status: not ready - verification blocker / required / complete for candidate
- Human next action:
- Agent next instruction:
- Human inspection first:
- Verification needed before merge:
- Do not:
```

## Standard Mode

```text
Agent Work Verification

Verification Verdict:
[VERIFIED / PARTIALLY_VERIFIED / NOT_VERIFIED / MISALIGNED / UNSAFE_TO_MERGE]

Why:
[Task alignment, evidence identity, strongest support, and main gap or risk.]

Task Contract:
- Required:
- Out of scope:
- Verification expected:
- High-risk areas:

Contract Authority:
- Level:
- Source:
- Conflicts or assumptions:

Evidence Identity:
- Repository / branch:
- Base:
- Candidate snapshot:
- Worktree state and dirty snapshot identity:
- Pre-existing changes:
- Evidence source and environment:
- Commands / exit codes / executed against:

Agent Claims:
- ...

Evidence Inventory:
- Bound evidence:
- Rejected as stale or unbound:
- Missing:

Claim Vs Evidence:
| Claim | Snapshot-bound evidence | Status | Notes |
|---|---|---|---|
| ... | ... | ... | ... |

Task Alignment:
- ...

Scope Drift And Attribution:
- ...

Verification Fit:
- Appropriate / incomplete / mismatched
- Exact proof needed next:

Docs Truth Check:
- Required:
- Status:

Cannot Verify:
- Item:
  Missing access/environment/authority:
  What would prove it:
  Blocking the next gate:

Human Inspection First:
1. ...
2. ...

Next Action:
- Verification verdict:
- Workflow action:
- Code review status: not ready - verification blocker / required / complete for candidate
- Human next action:
- Agent next instruction:
- Human inspection first: [first file/area or "See Human Inspection First above"]
- Verification needed before merge:
- Do not:
```

## High-Risk Mode

```text
Agent Work Verification - High Risk

Verification Verdict:
[VERIFIED / PARTIALLY_VERIFIED / NOT_VERIFIED / MISALIGNED / UNSAFE_TO_MERGE]

High-Risk Area And Contract Authority:
- Area:
- Contract source and authority:

Evidence Identity:
- Repository / branch / base:
- Candidate snapshot:
- Worktree state and dirty snapshot identity:
- Pre-existing changes:
- Evidence source and environment:
- Commands / exit codes / executed against:

Blocking Gate:
- Required proof:
- Snapshot-bound evidence found:
- Rejected or missing evidence:

Claim Vs Evidence:
| Claim | Snapshot-bound evidence | Status | Notes |
|---|---|---|---|
| ... | ... | ... | ... |

Scope Drift And Attribution:
- ...

Cannot Verify:
- ...

Human Inspection First:
1. ...
2. ...

Next Action:
- Verification verdict:
- Workflow action:
- Code review status: not ready - verification blocker / required / complete for candidate
- Human next action:
- Agent next instruction:
- Human inspection first: [first file/area or "See Human Inspection First above"]
- Verification needed before merge:
- Do not:
```
