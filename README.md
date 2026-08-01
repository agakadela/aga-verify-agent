# Aga Verify Agent

`aga-verify-agent` checks whether a coding agent actually completed the task it
was given.

It does not trust `fixed`, `tests pass`, or `ready to merge` on their own. It
compares the original task, the agent's claims, the code that changed, and the
proof available for that exact version of the code.

```text
task → agent claims → changed code → proof → next action
```

## What does it check?

- Did the agent solve the requested problem?
- What exactly does the agent claim it changed and tested?
- Do the tests and other results belong to the commit being reviewed?
- Did the agent change anything outside the task?
- What still needs to happen before the work can continue or merge?

For example, if the agent changed commit `B` but shows a passing test from
commit `A`, the skill rejects that test as stale evidence and asks for a new run
against commit `B`.

## This is not code review

The two checks answer different questions:

- **Aga Verify Agent:** Did the agent complete the accepted task, and are its
  claims supported by evidence from the exact code version being reviewed?
- **Code review:** Is the implementation correct, safe, maintainable, and a good
  fit for the system's design and architecture?

You still need code review as a separate step. A change can pass verification
and fail code review. It can also be well written but fail verification because
it solves the wrong task.

## Installation

Install it for your Codex user:

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/agakadela/aga-verify-agent.git \
  ~/.agents/skills/aga-verify-agent
```

Or install it only in one project:

```bash
mkdir -p .agents/skills
git clone https://github.com/agakadela/aga-verify-agent.git \
  .agents/skills/aga-verify-agent
```

Restart Codex after installation.

## How to use it

Run it after a coding agent finishes:

```text
$aga-verify-agent
```

### In the same conversation

The verifier can use the original task and the previous agent's final answer
from the conversation:

```text
$aga-verify-agent

Verify the work reported in the previous agent response against the current
HEAD.
```

The conversation matters, not the terminal window.

### In a new conversation

Paste or link the missing context:

```text
$aga-verify-agent

Task:
Fix the Export button so it downloads the generated CSV. Keep the label
unchanged and add a regression test.

Agent final answer:
Implemented the export fix. Tests pass. Ready to merge.

Reviewed change:
Base commit: 3333333
Candidate commit: 4444444

Evidence:
<CI link, raw test output, runtime result, or other proof>
```

You can point to an issue, PR, commit, CI run, or saved agent report instead of
pasting it.

## Where do the agent's claims come from?

Claims come from material written by the agent:

- its final answer;
- a PR description;
- a commit message;
- another completion report.

The agent's final answer is a source of claims. It is not proof and it does not
define the original task.

If no agent report is available, the skill can still compare the task with the
code and tests. It will state that no agent-authored claims were provided.

## What result do you get?

The skill returns a verification verdict:

- `VERIFIED`
- `PARTIALLY_VERIFIED`
- `NOT_VERIFIED`
- `MISALIGNED`
- `UNSAFE_TO_MERGE`

It also returns a separate next action, such as:

```text
Verification verdict: VERIFIED
Workflow action: PROCEED TO CODE REVIEW
```

`VERIFIED` does not automatically mean `MERGE`. Code review, runtime testing,
or another project gate may still be required.

## High-risk changes

Auth, tenant data, payments, migrations, production configuration, AI actions,
and tool permissions need stronger proof than a source diff or unit tests. If
that proof is unavailable, the skill says exactly what is missing and prevents
the work from being treated as safe to merge.

## Boundaries

The skill does not replace code review or runtime testing. It does not silently
fix the implementation, merge, deploy, or publish anything. If the candidate
changes after verification or review, the relevant checks must run again
against the new candidate.

The complete rules are in [`SKILL.md`](./SKILL.md). Detailed high-risk gates
and output templates are in [`references/`](./references/).

Created by [Aga Kadela](https://github.com/agakadela), Software Engineer.
