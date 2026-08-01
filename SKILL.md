---
name: aga-verify-agent
description: Verify completed AI coding-agent work against the authoritative task and exact repository snapshot. Use after an agent reports a task, fix, feature, commit, or PR complete to check claims, evidence provenance, scope drift, and the next workflow action. Not code review, runtime testing, or merge approval. Invoke explicitly with $aga-verify-agent.
---

# Aga Verify Agent

## Purpose

Verify completed work from an AI coding agent before the user trusts it,
continues from it, or sends it to the next workflow gate.

Ask what the agent was authorized to do, which snapshot is under review, what
it claimed, which evidence is bound to that snapshot, what remains unverified,
and what the user should do next. Do not substitute the broader question `Is
the code good?`; that belongs to code review.
This is an evidence gate, not code review, runtime testing, or merge approval.

The output must always end with **Next Action**.

## Non-Negotiable Principles

- The agent final answer is a source of claims, not evidence or task authority.
- Evidence supports a claim only when its provenance and snapshot match the
  reviewed change.
- Agent-reported command results remain claims until independently rerun or
  supported by an inspectable raw artifact tied to the reviewed snapshot.
- A passing command proves only what that command covers.
- A reasonable diff can still solve the wrong task.
- `VERIFIED` describes task fulfillment for one identified snapshot. Downstream
  review, merge, deploy, or release claims stay separate in the claim matrix and workflow action.
- Missing access is not certainty. Name it under `Cannot Verify` and decide
  whether it blocks the next gate.

## Verification Is Not Code Review

Keep these checks separate. Verification asks whether the agent fulfilled the
accepted task and whether its claims have snapshot-bound evidence. Code review
asks whether the implementation is correct, safe, clear, maintainable, and a
good architectural fit. Either can pass while the other fails. Passing this
skill never waives code review, and review must inspect the same candidate or
be repeated after it changes.

Default a `VERIFIED` result to `PROCEED TO CODE REVIEW` unless a separate code
review is already complete and bound to the same snapshot.

## Use And Mode Selection

Use this skill after an AI coding agent completes a task, bug fix, feature
slice, commit, PR, code-generation session, rescue change, or final answer that
says `fixed`, `done`, `implemented`, `verified`, or `tests pass`.

Choose the mode from the behavior and risk changed, not merely words appearing
in a file:

- **Light Mode:** copy or documentation-only edits that do not change executable
  behavior or operational safeguards, trivial styling, one isolated UI state,
  or another small low-risk change. Usually 15-30 lines.
- **Standard Mode:** normal bug fix, feature slice, commit, or PR.
- **High-Risk Mode:** behavior, schema, configuration, or operational
  instructions that materially affect auth, authorization, tenant data,
  payments, migrations, secrets, production config, AI costs/actions, tool
  actions, external callbacks, or another trust boundary.

A documentation edit that only mentions a high-risk domain remains Light Mode.
Use High-Risk Mode when the documentation itself changes an operational
safeguard, execution instruction, production decision, or source of truth.

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
- update a project verification record or workflow status unless the project
  workflow explicitly grants this verifier that narrow write authority;
- merge, deploy, publish, or perform another external mutation.

If verification finds a problem, stop and report it. Do not silently fix it.

## Required Context

Inspect only the smallest sufficient context: the task and human corrections;
agent-authored claims; repository, base, candidate, worktree, and attributable
diff; relevant raw evidence; applicable architecture or current primary
sources; and known access or environment limits.

Do not load the whole repository or all project history merely because it is
available. Follow the repository's own instructions and source-of-truth map.

## Core Verification Sequence

### 1. Establish Task Contract And Authority

Identify what the agent was actually supposed to do and classify the source.

Authority hierarchy, strongest first:

**Authoritative**

- original user instruction;
- acceptance criteria accepted before or during implementation;
- task, issue, specification, or project plan approved before or during
  implementation;
- user corrections issued during the work.

**Human-accepted reconstruction**

- PR description accepted before implementation;
- implementation plan explicitly accepted by the user;
- another reconstruction explicitly confirmed before implementation.

**Agent-derived assumption**

- commit message;
- agent final answer;
- PR description written only after implementation and not human-accepted;
- changed-file summary or inferred nearby goal.

Agent-derived material may explain what the agent believes it did. It cannot by
itself define what the agent was required to do.

Record when the contract was accepted. A source created or materially rewritten
after implementation cannot prove the agent's original authorization. Post-hoc
human acceptance may approve the delivered outcome, but it does not rewrite the
original task or raise original task fulfillment above `PARTIALLY_VERIFIED`
without independent contemporaneous task evidence. If the user adopts the
outcome as a new task, report original alignment separately.

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
task text only when the correction was issued during the work. Do not let an
agent-authored or post-hoc summary rewrite the original authorization.

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

If no agent-authored report exists, state `No agent-authored claims provided`.
Do not infer claims from the diff. Continue by comparing the task with the work
and evidence; omit empty claim rows and limit the verdict to task fulfillment.

### 3. Establish Evidence Identity

Identify the exact change under review before treating any artifact as evidence.

Output:

```text
Evidence Identity:
- Repository:
- Branch:
- Base commit:
- Candidate commit:
- Worktree state: clean / dirty
- Dirty snapshot identity, when applicable:
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

- Treat evidence as belonging to a commit only when it ran from a clean checkout
  of that commit.
- Before a verifier-run command, capture worktree status. If it is dirty, bind
  the evidence to the base SHA plus staged, unstaged, and relevant untracked
  files using a diff, content snapshot, or stable fingerprint. Label the result
  as dirty-snapshot evidence, never commit-only evidence.
- Capture worktree status again after commands that may change tracked or
  relevant untracked files. If the state changed, identify the post-command
  snapshot or reject the result as insufficiently bound.
- Separate pre-existing human or unrelated changes from agent-attributable
  work. If no baseline exists, state that attribution cannot be confirmed.
- Reject stale, cross-branch, cross-repository, cross-environment, or otherwise
  unbound evidence for the affected claim.
- If the reviewed change itself cannot be identified, use `NOT_VERIFIED`.
- If the change is identified but some proof is unbound, reject that proof and
  lower the affected claim and verdict accordingly.

### 4. Inventory Evidence

Before interpreting evidence, inventory the relevant diff, checks, runtime or
provider observations, raw artifacts, current primary sources, documentation,
rejected stale/unbound artifacts, and missing proof.

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

- **Low:** documentation, formatting, tiny cleanup, or narrowly additive tests
  that do not weaken coverage or alter production behavior. Mention it.
- **Medium:** shared logic, component structure, output format, CLI flags, API
  shape, non-trivial UI structure, or material test rewrites. Hold until
  inspected; split if unrelated.
- **High:** auth, payments, data access, migrations, secrets, production config,
  AI actions, tool permissions, destructive operations, or deleted/weakened
  safeguards and regression tests. Stop and do not merge.

### 8. Judge Verification Fit

Ask whether the right proof was used, not merely whether tests ran. Read
`references/evidence-fit.md` and apply only the rows triggered by the task.

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

Tell the human owner where to look first. Prioritize the core task behavior,
high-risk areas, scope drift, shared helpers, generated tests, unverified
runtime behavior, and docs that should have changed.

Keep this list short enough to reduce review burden.

In Standard and High-Risk outputs, keep details in the main `Human Inspection First` section.
In `Next Action`, name only the first file/area or refer above; Light Mode may keep it there.

### 12. Issue A Verification Verdict

Choose one:

- **VERIFIED:** the accepted task is fulfilled for the identified snapshot. The
  contract is authoritative or human-accepted, material task evidence is bound,
  and remaining cannot-verify items do not block verification. Downstream review,
  merge, deploy, or release claims stay separate in the claim matrix and workflow
  action; unsupported downstream claims do not change the task-fulfillment verdict.
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

The verdict answers only whether the accepted task is verified for this snapshot.
It does not collapse testing, code review, release approval, or merge authority
into the same result.

### 13. Route The Workflow Action

Choose the next action independently from the verification verdict:

```text
PROCEED TO CODE REVIEW
PROCEED TO TEST
HOLD
SPLIT / ISOLATE
DO NOT MERGE
REVERT CANDIDATE
MERGE CANDIDATE
```

Default routing:

- `VERIFIED` → `PROCEED TO CODE REVIEW` unless a separate review is already
  complete for the same snapshot; then proceed to the next incomplete gate.
- `PARTIALLY_VERIFIED` → `HOLD`; run or obtain the exact missing proof. When the
  only limitation is explicitly accepted post-hoc scope and original alignment
  remains recorded, `PROCEED TO CODE REVIEW` is allowed; post-hoc acceptance
  never substitutes for missing evidence.
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
- the human owner understands the changed behavior and retains the merge
  decision.

Even then, this skill recommends a candidate state. It never performs the
merge or grants authority that the user or project workflow did not grant.

End with:

```text
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

## Binding High-Risk Rules

High-risk behavioral or operational changes override normal confidence. A
source diff alone is never enough; documentation-only mentions do not trigger
these gates.

- **Auth/data isolation:** require positive and negative access proof at the
  architecture-declared enforcement boundary.
- **Payments/product access:** require the authoritative payment result and its
  resulting product state, including replay/idempotency where applicable.
- **Migrations:** require the artifact, data-risk treatment, and relevant
  rollback/backfill; require backup/PITR proof before production execution.
- **AI/tool actions:** require permissions, limits, validation, observable
  failures, and approval/auditability where risk requires them.
- **Secrets/config:** require environment evidence when live state matters.

Read `references/high-risk-gates.md` for the full gate selected by the change.

## References

- Read `references/output-templates.md` before producing the chosen mode's
  final output.
- Read `references/evidence-fit.md` when judging whether proof matches the task.
- Read `references/high-risk-gates.md` whenever High-Risk Mode applies.
- Read `references/examples-and-red-flags.md` only when classification is
  ambiguous, the result needs calibration, or the skill is being taught or
  evaluated.

## Done Means

The skill is complete only when it gives the user an authoritative or limited
task contract, exact snapshot and provenance, factual verdict, supporting and
rejected evidence, cannot-verify items, first manual inspection point, and a
separate exact workflow action.

If the result does not change what the user should do next, it is not done.
