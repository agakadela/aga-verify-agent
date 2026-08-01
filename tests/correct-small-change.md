# Behavioral Case: Correct Small Change

## Input

Use Light Mode. In repository `example/docs` on branch `fix/setup-link`, candidate
commit `ccccccc` changes one README link from `./guides/setup.md` to the existing
`./docs/setup.md`. The checkout is clean and no other files differ from base
commit `bbbbbbb`.

## Authoritative Task

The user asked before implementation: "Fix the broken README setup link without
changing any setup instructions." Acceptance requires a valid target and no
other content change.

## Agent Claims

- Fixed the setup link.
- Confirmed the target exists.
- The change is complete and ready to merge.

## Evidence Identity

- Repository / branch: `example/docs` / `fix/setup-link`
- Base / candidate: `bbbbbbb` / `ccccccc`
- Worktree: clean
- Evidence source: verifier-run readback and path check
- Command: `test -f docs/setup.md` (exit `0`)
- Executed against: clean candidate `ccccccc`

## Expected Verdict

`VERIFIED`

The requested change and material claims are supported for the identified
snapshot. The agent's merge-readiness claim does not itself authorize merge.

## Expected Workflow Action

`PROCEED TO CODE REVIEW`

## Last Actual Result

- Date: 2026-08-01
- Runner: Codex CLI 0.144.1
- Model: GPT-5 family (exact session model identifier not exposed)
- Method: Fresh Codex context; expected-result sections withheld
- Result: PASS
- Observed verdict: `VERIFIED`
- Observed workflow action: `PROCEED TO CODE REVIEW`
