# Verification Examples And Red Flags

Consult this file only when classification is ambiguous, when teaching the
workflow, or when evaluating the skill.

## Status Examples

### Unsupported

```text
Claim: All tests pass.
Evidence: Lint output only.
Status: unsupported.
Action: run or request the expected test evidence.
```

### Cannot Verify

```text
Claim: The production webhook updates entitlements correctly.
Evidence: Source diff only; no provider or production access.
Status: cannot verify.
Action: name the missing environment/access and decide whether it blocks the
next gate.
```

### Unbound Evidence

```text
Claim: Tests pass for candidate commit B.
Evidence: Test output from commit A.
Status: unsupported for commit B; reject the output as stale.
Action: rerun against B or provide an inspectable artifact tied to B.
```

### Agent-Derived Contract

```text
Available task source: final answer and commit message only.
Contract authority: agent-derived assumption.
Maximum verdict: PARTIALLY_VERIFIED.
```

## Red Flags

Treat these as serious until resolved:

- `fixed` or `verified` without relevant proof;
- test output not tied to the candidate snapshot;
- no baseline separating pre-existing and agent changes;
- `all tests pass` supported only by an agent summary;
- changed files omitted from the final answer;
- nearby problem solved instead of the accepted task;
- unrelated refactor, dependency, schema, config, auth, payment, or data change;
- weakened or deleted tests;
- changed project truth without updating its owner;
- runtime behavior inferred only from a diff;
- `VERIFIED` treated as code-review approval or merge authority.

## Common Rationalizations

- `Tests pass, so it is done.` Tests prove only their cases and snapshot.
- `The agent said it verified.` The statement is a claim.
- `The diff looks reasonable.` It can still solve the wrong task.
- `It was only a small refactor.` Unrelated changes hide regression risk.
- `The redirect worked.` It does not establish authoritative payment state.
- `The UI hides the button.` UI hiding is not authorization.
- `The old CI run is probably equivalent.` Evidence must match the candidate.
- `Merge now, fix later.` Verification does not grant merge authority.

## Next-Instruction Patterns

Verification-only:

```text
Do not edit implementation code. Run [exact check] against [candidate snapshot]
in [environment], capture the raw result and exit code, and stop if it fails.
```

Misalignment:

```text
Re-read [authoritative task source]. The current change solves [nearby problem],
but the required behavior is [requirement]. Propose the smallest aligned change
before editing.
```

Scope drift:

```text
Separate or revert [unrelated files]. Preserve pre-existing work. Keep only the
changes attributable to [task] and do not modify high-risk areas without a new
authorized task.
```
