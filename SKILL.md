---
name: aga-verify-agent
description: Workflow command. Evidence gate for completed AI coding agent work. Verifies whether the agent fulfilled an authoritative task contract by binding its claims and evidence to the exact reviewed repository snapshot, checking scope drift and docs truth, naming cannot-verify items, and routing Aga to the next workflow action. This is not code review or merge approval. Invoke explicitly with $aga-verify-agent.
---

# Aga Verify Agent

## Purpose

Verify completed work from an AI coding agent before Aga trusts it, continues
from it, or sends it to the next workflow gate.

Do not ask first:

```text
Is the code good?
```

Ask:

```text
What was the agent authorized to do?
Which exact repository snapshot is under review?
What did the agent claim?
Which evidence is bound to that snapshot?
What remains unsupported or cannot be verified?
What should Aga do next?
```

This is an evidence gate, not code review, runtime testing, or merge approval.

```text
$aga-build
→ $aga-verify-agent
→ Aga Action
→ required test / review / targeted fix / split / revert / merge candidate
```

The output must always end with **Aga Action**.

## Non-Negotiable Principles

```text
task authority
→ reviewed snapshot
→ agent claims
→ snapshot-bound evidence
→ gaps and risk
→ verification verdict
→ workflow action
```

- The agent final answer is a source of claims, not evidence or task authority.
- Evidence supports a claim only when its provenance and snapshot match the
  reviewed change.
- Agent-reported command results remain claims until independently rerun or
  supported by an inspectable raw artifact tied to the reviewed snapshot.
- A passing command proves only what that command covers.
- A reasonable diff can still solve the wrong task.
- `VERIFIED` describes task fulfillment and claims for one identified snapshot.
  It does not mean code review passed or merge is allowed.
- Missing access is not certainty. Name it under `Cannot Verify` and decide
  whether it blocks the next gate.

## Use And Mode Selection

Use this skill after an AI coding agent completes a task, bug fix, feature
slice, commit, PR, code-generation session, rescue change, or final answer that
says `fixed`, `done`, `implemented`, `verified`, or `tests pass`.

Choose one mode:

- **Light Mode:** copy, docs, trivial styling, one isolated UI state, or another
  small low-risk change. Usually 10-20 lines.
- **Standard Mode:** normal bug fix, feature slice, commit, or PR.
- **High-Risk Mode:** auth, authorization, tenant data, payments, migrations,
  secrets, production config, AI costs/actions, tool actions, external provider
  callbacks, or another material trust boundary.

Every mode uses a task contract, minimum Evidence Identity, explicit cannot-
verify items, a verification verdict, and a separate workflow action.

Before rendering the result, read the matching template in
`references/output-templates.md`. When High-Risk Mode applies, also read
`references/high-risk-gates.md`.

## Verification Boundary

Default behavior is verification-only and implementation-read-only.

Allowed by default:

- inspect the task, diff, commit, PR, source, docs, and raw evidence;
- identify the repository, branch, base, candidate snapshot, and pre-existing
  changes;
- run safe checks, tests, lint, or build when appropriate;
- report missing evidence and produce the next exact instruction.

Running a check may create normal caches or test artifacts. It does not
authorize implementation edits, dependency installation, provider mutation,
production actions, or cleanup outside the task boundary.

Do not by default:

- change implementation code or tests to improve the verdict;
- refactor or clean up while checking;
- install dependencies without authority;
- alter migrations, auth, payments, env, provider state, or production config;
- update `VERIFY_LOG` or workflow status unless the project workflow explicitly
  grants this verifier that narrow write authority;
- merge, deploy, publish, or perform another external mutation.

If verification finds a problem, stop and report it. Do not silently fix it.

## Required Context

Inspect only the smallest sufficient context:

- authoritative task source and acceptance criteria;
- human corrections issued during the work;
- agent final answer and other agent-authored claims;
- repository identity, branch, base, candidate snapshot, and worktree state;
- diff or changed files attributable to the task;
- relevant tests, runtime observations, logs, screenshots, CI artifacts, and
  database/provider evidence;
- relevant architecture, contracts, risk documents, and version-sensitive
  official sources;
- known access and environment limitations.

Do not load the whole repository or all project history merely because it is
available. Follow the repository's own instructions and source-of-truth map.

## Core Verification Sequence

### 1. Establish Task Contract And Authority

Identify what the agent was actually supposed to do and classify the source.

Authority hierarchy, strongest first:

**Authoritative**

- original user instruction;
- accepted acceptance criteria;
- approved task in `PLAN.md`;
- accepted issue or specification;
- user corrections issued during the work.

**Human-accepted reconstruction**

- PR description accepted before implementation;
- implementation plan explicitly accepted by the user;
- another reconstruction explicitly confirmed by the user.

**Agent-derived assumption**

- commit message;
- agent final answer;
- PR description written only after implementation and not human-accepted;
- changed-file summary or inferred nearby goal.

Agent-derived material may explain what the agent believes it did. It cannot by
itself define what the agent was required to do.

Output:

```text
Task Contract:
- Required:
- Acceptance criteria:
- Out of scope:
- User-visible result expected:
- Verification expected:
- High-risk areas:

Contract Authority:
- Authoritative / Human-accepted reconstruction / Agent-derived assumption
- Source:
- Conflicts or assumptions:
```

If no authoritative or human-accepted contract exists, the maximum verdict is
`PARTIALLY_VERIFIED`. If the requirements cannot be reconstructed well enough
to judge alignment, use `NOT_VERIFIED`.

When sources conflict, the latest explicit user correction overrides earlier
task text. Do not let an agent-authored summary override a human decision.

### 2. Extract Agent Claims

Extract claims from the final answer, PR description, commit message, and other
agent-authored output. Separate:

- what changed;
- what was tested;
- what is assumed;
- what is claimed complete;
- what limitation the agent admitted.

Treat `fixed`, `done`, `implemented`, `verified`, `works`, `all tests pass`, and
`no regressions` as claims requiring their own support.

### 3. Establish Evidence Identity

Identify the exact change under review before treating any artifact as evidence.

Output:

```text
Evidence Identity:
- Repository:
- Branch:
- Base commit:
- Candidate commit or dirty-worktree snapshot:
- Pre-existing changes:
- Evidence source: verifier-run / CI or raw artifact / agent-reported
- Command and exit code:
- Environment:
- Executed against:
```

In Light Mode, the minimum is still:

1. what exact change or snapshot is being reviewed;
2. which snapshot and environment produced the evidence;
3. whether the verifier, CI/raw artifact, or agent supplied the result.

Apply these rules:

- Record a commit SHA when a commit exists.
- For dirty worktrees, identify changed files and the diff or content snapshot
  used for review. Do not imply stronger reproducibility than exists.
- Separate pre-existing human or unrelated changes from agent-attributable
  work. If no baseline exists, state that attribution cannot be confirmed.
- Reject stale, cross-branch, cross-repository, cross-environment, or otherwise
  unbound evidence for the affected claim.
- If the reviewed change itself cannot be identified, use `NOT_VERIFIED`.
- If the change is identified but some proof is unbound, reject that proof and
  lower the affected claim and verdict accordingly.

### 4. Inventory Evidence

List evidence before interpreting it:

```text
Evidence Inventory:
- Diff and changed files:
- Tests/lint/build:
- Runtime/browser:
- Database/provider/dashboard:
- Screenshots/logs/raw outputs:
- Current official-source evidence:
- Docs:
- Rejected as unbound or stale:
- Missing:
```

Rank provenance:

1. verifier-observed result against the identified snapshot;
2. inspectable CI, terminal, provider, browser, or other raw artifact tied to
   that snapshot;
3. agent-reported result, which remains a claim until independently supported.

Evidence only proves what it directly covers. For example:

- lint proves lint passed, not UI behavior or tenant isolation;
- unit tests prove their tested cases, not provider behavior or all regressions;
- a webhook diff proves source changed, not that an event arrived or product
  state changed;
- a screenshot proves one visible state, not authorization enforcement.

### 5. Build The Claim Vs Evidence Matrix

Use:

```text
| Agent claim | Snapshot-bound evidence | Status | Notes |
|---|---|---|---|
| ... | ... | supported / partially supported / unsupported / contradicted / cannot verify | ... |
```

Status definitions:

- **supported:** evidence directly confirms the claim for the reviewed snapshot.
- **partially supported:** evidence confirms part of the claim, but a material
  portion remains unsupported.
- **unsupported:** the agent made a concrete claim, but expected evidence was
  not provided, was not run, or was rejected as stale/unbound. Ask for or run
  evidence that should normally exist.
- **contradicted:** bound evidence suggests the claim is false.
- **cannot verify:** the appropriate evidence requires access, an environment,
  or authority the verifier does not have. Name what is missing and decide
  whether it blocks the next gate.

Do not use `cannot verify` merely to soften an unsupported claim. Do not turn
missing access into `unsupported` when the required proof is genuinely outside
the available environment.

### 6. Check Task Alignment

Decide whether the work matches the contract:

```text
Task Alignment:
- Aligned / partially aligned / misaligned
- What matches:
- What is missing:
- What solves a nearby but different problem:
- User-visible result status:
```

Real work can still be misaligned. Examples include patching without the
requested reproduction, changing types for a runtime behavior task, or solving
a nearby problem inferred from the code instead of the accepted requirement.

### 7. Check Scope Drift And Attribution

Identify work outside the contract without assigning pre-existing changes to
the agent when the baseline does not support that attribution.

```text
Scope Drift:
- None / possible / confirmed / cannot attribute
- Files or behavior outside scope:
- Dependency/config/schema changes:
- Attribution basis:
- Risk: Low / Medium / High
```

- **Low:** docs, tests, formatting, tiny cleanup. Mention it.
- **Medium:** shared logic, component structure, output format, CLI flags, API
  shape, non-trivial UI structure. Hold until inspected; split if unrelated.
- **High:** auth, payments, data access, migrations, secrets, production config,
  AI actions, tool permissions, destructive operations. Stop and do not merge.

### 8. Judge Verification Fit

Ask whether the right proof was used, not merely whether tests ran.

| Task type | Minimum useful proof |
| --- | --- |
| Markdown/docs | readback, format, and relevant link/path check |
| Pure logic | relevant unit tests including material edge cases |
| CLI | command output showing changed behavior |
| API/server action | request/response, validation/error behavior, shared contract alignment |
| UI/frontend state | browser/state check covering material new states |
| RAG/retrieval | sample query, retrieved material, citations, groundedness check |
| Auth/data isolation | authorized case plus two-user or equivalent negative isolation test |
| Payment/product state | authoritative payment result plus resulting state at the architecture-declared source of truth |
| Migration/schema | migration artifact, data-risk note, rollback/backfill where relevant; backup/PITR before production execution |
| AI endpoint | auth, limits/cost, retry, logging, failure path, output validation |
| Tool action | permission, approval where needed, audit trail, result validation, failure/retry behavior |
| Provider/webhook | contract/authenticity, relevant test or replay, idempotency/ordering behavior |
| Version-sensitive behavior | installed version plus current primary source and matching implementation |
| Triggered observability | named operational question plus observable test event/error/request or explicit cannot-verify |

Output:

```text
Verification Fit:
- Appropriate / incomplete / mismatched
- Verified:
- Not verified:
- Mismatch:
- Exact proof needed next:
```

### 9. Check Docs Truth

If the change alters project truth, verify that the project-owned source of
truth is updated in the same change when the repository workflow requires it.
Do not invent a new documentation system merely because another repository
uses one.

Check relevant architecture, API, access, UI, AI, integration, operations,
handoff, and verification records according to the repository's own map.

### 10. Record Cannot Verify

Always include:

```text
Cannot Verify:
- Item:
  Missing access/environment/authority:
  What would prove it:
  Blocking the next gate: yes / no
```

`Cannot Verify` is not automatically a failure. It blocks when the missing
proof is required by the task, risk, or next workflow gate.

### 11. Direct Human Inspection

Tell Aga where to look first. Prioritize the core task behavior, high-risk
areas, scope drift, shared helpers, generated tests, unverified runtime
behavior, and docs that should have changed.

Keep this list short enough to reduce review burden.

### 12. Issue A Verification Verdict

Choose one:

- **VERIFIED:** the agent's task fulfillment and claims are supported for the
  identified repository snapshot. The contract is authoritative or human-
  accepted, material evidence is snapshot-bound, and remaining cannot-verify
  items do not block verification. This does not mean review passed or merge is
  allowed.
- **PARTIALLY_VERIFIED:** the core work appears aligned, but important proof is
  missing, rejected as unbound, or only part of a claim is supported. Also the
  maximum verdict when the best available contract is an agent-derived
  assumption.
- **NOT_VERIFIED:** the evidence does not support completion, the reviewed
  change cannot be identified, or the task contract cannot be reconstructed
  well enough to judge fulfillment.
- **MISALIGNED:** the work is real but does not match the accepted contract or
  solves a nearby problem.
- **UNSAFE_TO_MERGE:** a high-risk change lacks a required hard-gate proof, or
  there is serious scope drift, contradiction, broken behavior, weakened tests,
  unsafe migration/config, or another merge blocker.

The verdict answers only whether this agent work is verified. It does not
collapse testing, code review, release approval, or merge authority into the
same result.

### 13. Route The Workflow Action

Choose the next action independently from the verification verdict:

```text
PROCEED TO REVIEW
PROCEED TO TEST
HOLD
SPLIT / ISOLATE
DO NOT MERGE
REVERT CANDIDATE
MERGE CANDIDATE
```

Default routing:

- `VERIFIED` → proceed to any required review or test gate that has not yet
  completed for the same snapshot.
- `PARTIALLY_VERIFIED` → `HOLD`; run or obtain the exact missing proof.
- `NOT_VERIFIED` → `HOLD` or `DO NOT MERGE`; obtain evidence or reconstruct the
  contract before continuing.
- `MISALIGNED` → `DO NOT MERGE` or `SPLIT / ISOLATE`.
- `UNSAFE_TO_MERGE` → `DO NOT MERGE` or `REVERT CANDIDATE`.

Use `MERGE CANDIDATE` only when all are true:

- the task contract is authoritative or human-accepted;
- the candidate snapshot and attribution are identified;
- the verification verdict is `VERIFIED`;
- every required review completed for that same snapshot;
- every required automated and runtime test completed for that same snapshot;
- required docs and high-risk gates are satisfied;
- no merge-blocking `Cannot Verify` item remains;
- Aga understands the changed behavior and retains the merge decision.

Even then, this skill recommends a candidate state. It never performs the
merge or grants authority that the user or project workflow did not grant.

End with:

```text
Aga Action:
- Verification verdict:
- Workflow action:
- Your next action:
- Agent next instruction:
- Human inspection first:
- Verification needed before merge:
- VERIFY_LOG action:
- Do not:
```

## Binding High-Risk Rules

High-risk areas override normal confidence. A source diff alone is never enough.

- **Auth/data isolation:** require an authorized case and a two-user or
  equivalent negative isolation test; confirm enforcement at the architecture-
  declared boundary.
- **Payments/product access:** confirm the authoritative payment result, then
  confirm resulting product or access state at the source of truth declared by
  the architecture. For webhook-driven SaaS, verify event authenticity,
  processing, idempotent transition, and local entitlement/product state.
- **Migrations:** require the migration artifact and data-risk treatment;
  require rollback/backfill when relevant and backup/PITR confirmation before
  production execution.
- **AI endpoints and tool actions:** require permissions, input/output limits,
  cost/retry boundaries, validation, observable failure behavior, and human
  approval/audit trail where the action risk requires them.
- **Secrets/env/production config:** source inspection cannot confirm provider
  or secret-manager state; require environment evidence when it matters.

Read `references/high-risk-gates.md` for the full gate selected by the change.

## References

- Read `references/output-templates.md` before producing the chosen mode's
  final output.
- Read `references/high-risk-gates.md` whenever High-Risk Mode applies.
- Read `references/examples-and-red-flags.md` only when classification is
  ambiguous, the result needs calibration, or the skill is being taught or
  evaluated.

## Done Means

The skill is complete only when it gives Aga:

1. an authoritative or explicitly limited task contract;
2. the exact reviewed snapshot and evidence provenance;
3. a factual verification verdict;
4. the evidence, rejected evidence, and cannot-verify items behind it;
5. the first place to inspect manually;
6. a separate, exact next workflow action.

If the result does not change what Aga should do next, it is not done.
