# Prompt 46 - Map Authority Ownership And Risk Sync

Use this prompt only after Prompt 45 is closed green.
This is the last authority/risk docs gate before the baseline harness lands and runtime/system replacement work starts.

Checked-in filename note:
- this pack lives at `Docs/Promts/46_map_authority_ownership_risk_sync.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/ARCHITECTURE.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- Prompt `43-45` outputs

Preflight:
- touched owner layer: `active docs only`
- authority doc: `Docs/MAP_CONTRACT.md`, `Docs/SOURCE_OF_TRUTH.md`, and `Docs/ARCHITECTURE.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `markdown/internal link sanity + validate_architecture_guards`

## Goal

Synchronize ownership, risk, baseline validation, side-by-side replacement, and candidate-asset policy before runtime implementation prompts begin.

## Direction Statement

- no silent owner drift
- no save/flow drift hidden inside visual work
- if later prompts need a boundary move, they must say `escalate first`
- candidate asset policy must stay truthful
- asset art sequence must stay structure-first:
  topology/placement -> corridors/pocket masks -> landmark sockets/anchors -> candidate art spike
- replacement must stay side-by-side until the green switch gate is explicitly satisfied

## Hard Guardrails

- No runtime patch in Prompt `46`.
- No new authority surface unless unavoidable.
- Do not move map truth into UI or scenes in docs wording.

## Validation

- markdown/internal link sanity
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- active docs route the upcoming wave clearly
- risk lines are explicit
- side-by-side replacement mode is explicit
- later implementation prompts can cite stable authority wording

## Copy/Paste Parts

### Part A - Drift Audit

```text
Apply only Prompt 46 Part A.

Scope:
- Audit the active docs that will govern Prompt 57, Prompt 47, Prompt 47.5, Prompt 48-56, and Prompt 58-62.

At minimum review:
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/ARCHITECTURE.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`

Do not:
- patch runtime

Validation:
- validate_architecture_guards

Report:
- authority drifts
- ownership wording that must be tightened
- side-by-side replacement wording that must be tightened
- candidate-asset policy wording that must stay explicit
- later prompt areas that may need `escalate first`
```

### Part B - Docs Sync

```text
Apply only Prompt 46 Part B.

Scope:
- Land only the active-doc wording sync required by Part A.

Do not:
- create new gameplay authority outside the existing docs unless truly unavoidable
- patch runtime code

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact authority wording updated
- explicit confirmation that runtime truth, save shape, and flow state stayed unchanged
```
