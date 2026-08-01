# Aga Verify Agent

An evidence gate for completed AI coding-agent work.

`aga-verify-agent` checks whether an agent fulfilled the task it was actually
given, whether its completion claims are supported, and whether the supporting
evidence belongs to the exact repository snapshot under review.

It deliberately separates three decisions that are easy to collapse:

```text
Did the agent fulfill the task?
What should happen next?
Is the change ready to merge?
```

Those are not the same question. `VERIFIED` does not automatically mean
`MERGE CANDIDATE`.

## Why this skill exists

Coding agents can produce convincing summaries while accidentally mixing:

- the requested task with a nearby problem they chose to solve;
- a current diff with tests from an earlier commit;
- their own completion report with the task contract;
- passing lint or unit tests with proof of runtime behavior;
- verification of task fulfillment with code-review or merge approval.

This skill makes those boundaries explicit:

```text
task authority
→ reviewed snapshot
→ agent claims
→ snapshot-bound evidence
→ gaps and risk
→ verification verdict
→ workflow action
```

## What it verifies

The skill checks:

- the authority and content of the task contract;
- the exact repository, branch, base, and candidate snapshot;
- which changes are attributable to the agent;
- claims made in the agent's final answer, PR description, or commit message;
- whether each claim has evidence tied to the reviewed snapshot;
- task alignment, scope drift, and documentation truth;
- whether the verification method fits the type and risk of the change;
- what is unsupported and what cannot currently be verified;
- the next workflow action for the human owner.

It supports Light, Standard, and High-Risk modes. High-risk gates cover auth,
tenant isolation, payments, migrations, AI endpoints, tool actions, secrets,
production configuration, and provider callbacks.

## What it does not do

This is not:

- a general code-quality review;
- a replacement for runtime or browser testing;
- an automatic implementation fixer;
- permission to merge, deploy, or publish;
- proof that every possible regression was excluded.

The verifier may inspect code and run safe checks. It should not silently edit
the implementation to improve its own verdict.

## Installation

Agent Skills are portable folders built around a `SKILL.md` file and optional
resources. See OpenAI's [Using skills](https://openai.com/academy/skills/) and
[Agent Skills catalog](https://github.com/openai/skills) for background.

### User-level installation for Codex

Clone the repository into the user skills directory:

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/agakadela/aga-verify-agent.git \
  ~/.agents/skills/aga-verify-agent
```

Restart Codex so it discovers the new skill.

### Project-level installation

To make the skill available only inside one repository:

```bash
mkdir -p .agents/skills
git clone https://github.com/agakadela/aga-verify-agent.git \
  .agents/skills/aga-verify-agent
```

Restart the agent session after installation. Keep the whole directory
together: `SKILL.md` routes to files under `references/`.

## Invocation

The skill is intentionally configured for explicit invocation:

```text
$aga-verify-agent
```

The important boundary is the conversation context, not whether you use the
same terminal window.

### Same conversation or thread

If the implementation agent's final answer is still in the conversation, the
verifier can extract claims from it:

```text
$aga-verify-agent

Verify the work reported in the previous agent response against the current
HEAD. The original task and corrections are in this thread.
```

### New conversation or different agent

A new conversation should not be expected to know a previous agent's final
answer. Provide it directly or point the verifier to a durable artifact:

```text
$aga-verify-agent

Task contract:
- Original issue: #42
- Accepted acceptance criteria: <paste or link>
- Later human corrections: <paste or link>

Agent claims source:
- Final answer: <paste it>
- PR description: #77

Reviewed change:
- Repository: acme/product
- Branch: agent/fix-export
- Base commit: 3333333
- Candidate commit: 4444444

Evidence:
- CI run: <link or raw artifact>
- Runtime check: <command and output>
```

If no agent-authored completion report exists, say so. The skill can still
compare the task contract with the diff and evidence, but it cannot audit claims
that were never supplied.

## Inputs

Provide or make inspectable as much of the following as exists:

| Input | Preferred source | Why it matters |
| --- | --- | --- |
| Task contract | Original prompt, accepted issue/spec, accepted plan, human corrections | Defines what the agent was authorized and required to do |
| Agent claims | Final answer, PR description, commit message, agent report | Defines what the agent says it changed, tested, and completed |
| Reviewed snapshot | Repository, branch, base SHA, candidate SHA or dirty-worktree snapshot | Defines the exact change being judged |
| Pre-existing changes | Baseline diff or recorded worktree state | Prevents human or unrelated work from being attributed to the agent |
| Evidence | Verifier-run result or inspectable raw CI, terminal, browser, provider, or database artifact | Supports or rejects individual claims |
| Environment | Local, CI, preview, production, provider sandbox, relevant versions | Establishes where the result was observed |
| Access limits | Missing credentials, provider access, environment, or authority | Distinguishes missing proof from proof that cannot currently be obtained |

Do not treat the agent's final answer as the task contract. It is a source of
claims. Do not treat `tests pass` as evidence until the result is independently
rerun or backed by an inspectable raw artifact tied to the candidate snapshot.

## Where agent claims come from

The verifier extracts claims from agent-authored material:

1. the final answer or completion report;
2. the PR description;
3. the commit message;
4. other explicit agent-authored summaries.

Typical claims include:

- `The bug is fixed.`
- `Both states are covered.`
- `All tests pass.`
- `There are no regressions.`
- `The change is ready to merge.`

The diff is not an agent claim. It is evidence of what changed. Test output is
evidence only when its provenance identifies the reviewed repository snapshot.

If no claims source is available, the output should state:

```text
Agent Claims:
- No agent-authored completion report was provided.
```

That absence does not automatically prevent task verification when an
authoritative contract and sufficient snapshot-bound evidence exist. It does
prevent the verifier from checking the truthfulness of an unavailable report.

## Contract authority

The skill distinguishes three levels:

### Authoritative

- original user instruction;
- accepted acceptance criteria;
- approved task in `PLAN.md`;
- accepted issue or specification;
- human corrections issued during the work.

### Human-accepted reconstruction

- a PR description accepted before implementation;
- an implementation plan explicitly accepted by the user;
- another reconstruction explicitly confirmed by a human.

### Agent-derived assumption

- commit message;
- agent final answer;
- post-implementation PR description that was not human-accepted;
- inferred goal based only on the changed files.

Agent-derived material cannot independently define what the agent was required
to do. Without an authoritative or human-accepted contract, the maximum verdict
is `PARTIALLY_VERIFIED`. If the task cannot be reconstructed well enough to
judge alignment, the correct verdict is `NOT_VERIFIED`.

## Evidence identity

Evidence supports a claim only when its provenance and snapshot match the
reviewed change.

For each material artifact, identify:

```text
Repository
Branch
Base commit
Candidate commit or dirty-worktree snapshot
Pre-existing changes
Evidence source
Command and exit code
Environment
Executed against
```

Examples of evidence that must be rejected for the affected claim:

- tests from an earlier commit;
- CI output from another branch;
- a screenshot whose build cannot be identified;
- provider or database state from an unrelated environment;
- a command result reported only in the agent's prose;
- a green worktree that also contains unrecorded human changes.

## Unsupported vs. cannot verify

These statuses describe different situations.

### Unsupported

The agent made a concrete claim, but the expected evidence was not supplied,
was not run, or was rejected as stale or unbound.

```text
Claim: All tests pass.
Evidence: Lint output only.
Status: Unsupported.
```

Next step: ask for or run the evidence that should normally exist.

### Cannot verify

The appropriate evidence requires access, an environment, or authority that
the verifier does not have.

```text
Claim: The production webhook updates access correctly.
Evidence: Source diff only; no provider or production access.
Status: Cannot verify.
```

Next step: name the missing access or environment and decide whether it blocks
the next workflow gate.

## Verification verdicts

The skill returns one verification verdict:

| Verdict | Meaning |
| --- | --- |
| `VERIFIED` | Task fulfillment and material claims are supported for the identified snapshot |
| `PARTIALLY_VERIFIED` | The work appears aligned, but important proof is missing, rejected, or incomplete |
| `NOT_VERIFIED` | Completion is unsupported, the snapshot is unidentified, or the contract cannot be reconstructed |
| `MISALIGNED` | The work is real but solves the wrong or a nearby problem |
| `UNSAFE_TO_MERGE` | A high-risk hard gate or another material merge blocker is unresolved |

`VERIFIED` is not a code-review verdict and is not merge permission.

## Workflow actions

The next action is a separate axis:

- `PROCEED TO REVIEW`
- `PROCEED TO TEST`
- `HOLD`
- `SPLIT / ISOLATE`
- `DO NOT MERGE`
- `REVERT CANDIDATE`
- `MERGE CANDIDATE`

A common successful result is:

```text
Verification verdict: VERIFIED
Workflow action: PROCEED TO REVIEW
```

`MERGE CANDIDATE` is available only after all required review, automated test,
runtime, documentation, and high-risk gates have completed against the same
candidate snapshot, with no merge-blocking `Cannot Verify` item left.

## Modes

### Light Mode

For copy, documentation, trivial styling, or one small low-risk state. It still
requires a task contract, minimum evidence identity, cannot-verify section,
verdict, and workflow action.

### Standard Mode

For normal bug fixes, feature slices, commits, and pull requests. It produces a
claim-versus-evidence matrix and checks alignment, scope drift, verification
fit, documentation truth, and human inspection priorities.

### High-Risk Mode

For auth, tenant boundaries, payments, migrations, AI costs or actions, tool
permissions, secrets, production configuration, and external providers. Source
diffs alone cannot satisfy high-risk hard gates.

Examples:

- tenant isolation needs an authorized case and a two-user or equivalent
  negative isolation test;
- payment verification needs the authoritative payment result and the resulting
  product or access state at the architecture-declared source of truth;
- migrations need data-risk treatment and rollback/backfill where relevant;
- tool actions need permission, approval, audit, and failure-path evidence
  proportionate to their risk.

## Example outcomes

| Scenario | Expected result |
| --- | --- |
| Small correct change with candidate-bound proof, review still pending | `VERIFIED` → `PROCEED TO REVIEW` |
| Sensible change that solves a neighboring problem | `MISALIGNED` → `DO NOT MERGE` |
| Tests belong to an earlier commit | Reject stale evidence → `PARTIALLY_VERIFIED` or `NOT_VERIFIED` |
| Tenant isolation is supported only by source and mocked unit tests | `UNSAFE_TO_MERGE` → `DO NOT MERGE` |
| Only the agent's own description defines the task | At most `PARTIALLY_VERIFIED`; `NOT_VERIFIED` if alignment cannot be judged |

## Repository structure

```text
aga-verify-agent/
├── SKILL.md
├── agents/
│   └── openai.yaml
└── references/
    ├── examples-and-red-flags.md
    ├── high-risk-gates.md
    └── output-templates.md
```

The main `SKILL.md` contains the binding semantics. References hold detailed
gates, templates, and calibration material without hiding the core rules in a
file the agent may never read.

## Design principle

A claim is not supported merely because the evidence is the right kind. The
evidence must also come from the right version of the system.

Created by [Aga Kadela](https://github.com/agakadela), a software engineer
focused on system behavior, architecture boundaries, and verification of
agent-assisted work.
