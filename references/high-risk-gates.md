# High-Risk Verification Gates

Read only the sections triggered by the reviewed change. These details extend
the binding summaries in `SKILL.md`; they do not replace them.

## Auth, Authorization, And Tenant Data

Do not use `VERIFIED` without evidence for the architecture-declared
enforcement boundary.

Required where applicable:

- an authorized actor can access the intended resource;
- an unauthorized or second actor cannot access another owner's resource;
- server-side authorization exists;
- database-level isolation exists when required by the accepted architecture;
- negative permission cases cover direct requests, not only hidden UI.

## Payments And Product State

Confirm the authoritative payment result, then the resulting product or access
state at the source of truth declared by the architecture. A redirect or success
screen alone is never sufficient.

For webhook-driven SaaS, verify:

- provider event authenticity;
- successful webhook processing;
- idempotent duplicate/retry behavior;
- local entitlement or product-state transition;
- reconciliation or recovery behavior when processing fails.

For another accepted payment architecture, name its authoritative result,
state owner, transition mechanism, and equivalent replay/recovery proof.

## Migrations And Data Changes

For code-level verification, require:

- migration artifact in the repository;
- data-loss and compatibility risks named;
- rollback or forward-fix strategy;
- backfill plan when relevant.

Before production execution, also require backup/PITR confirmation and the
exact environment and execution authority. Local or preview evidence does not
prove production execution.

## AI Endpoints

Model output alone is not sufficient. Check, where applicable:

- authentication and authorization;
- input, token, file, rate, and cost limits;
- retry and timeout caps;
- output validation;
- logging without sensitive-content leakage;
- observable failure and fallback behavior;
- prompt-injection or hostile-input boundary;
- human review when the output can affect another person or system.

## Tool Actions And Agents

Check:

- read-only versus action permissions;
- allowed target and scope;
- human approval when risk requires it;
- idempotency or rollback;
- audit trail;
- tool-result validation;
- failure, timeout, and retry behavior.

## Secrets, Environment, And Production Config

Check:

- no secret is committed or exposed in output;
- environment examples and required names are current;
- local, preview, and production separation is preserved;
- provider dashboard or secret-manager state is confirmed when required;
- evidence identifies the exact environment.

Source inspection alone cannot verify live environment state.
