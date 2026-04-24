# Prompt 48 - Map Runtime Topology Backbone

Use this prompt only after Prompt 47 is closed green.
This is the first real runtime implementation pack in the new wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/48_map_runtime_topology_backbone.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- Prompt `43-47` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/RuntimeState/map_runtime_state.gd`
- directly related map runtime tests

Preflight:
- touched owner layer: `Game/RuntimeState`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth may change / save shape must stay unchanged by default / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted runtime map tests + full suite checkpoint`

## Goal

Replace the old scatter-centered runtime topology with a sector-aware backbone that still preserves current owner boundaries and save continuity.

## Direction Statement

- `MapRuntimeState` remains the graph truth owner
- no UI-owned topology
- no save payload widening by default
- start uses a deliberate start-anchor zone; exact geometric center is not required
- preferred default is a center-local lower-center / lower-third opening pocket unless stage shape clearly justifies another anchor
- corner-entry or heavily offset starts should be explicit exceptions, not accidental outcomes
- top-heavy random start placement is failure
- stage graph should read as primary spine + branch pockets + late pressure, not a central cluster

## Required Runtime Outcomes

- deliberate opening pocket with readable first route choices
- primary traversal backbone through sector grammar
- branch pockets attached locally
- reconnects remain local and limited
- key/boss pressure appears late and outward
- support detour remains possible
- hunger tradeoff remains meaningful through route shape

## Hard Guardrails

- No save-shape widening unless the prompt stops with `escalate first`.
- No owner move away from `MapRuntimeState`.
- No flow-state change.
- No map truth leak into UI.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted runtime map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- runtime topology is sector-aware
- current graph truth owner remains `MapRuntimeState`
- save and flow boundaries remain intact
- a later screenshot pass can reasonably expect stronger board structure

## Copy/Paste Parts

### Part A - Runtime Audit

```text
Apply only Prompt 48 Part A.

Scope:
- Audit the current runtime topology generation and map it against the new sector grammar.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted runtime map readbacks/tests

Report:
- exact functions carrying the old scatter-centered topology logic
- exact places where the new sector backbone can land without owner drift
- explicit note whether save-shape or flow-state pressure appears
```

### Part B - Backbone Implementation

```text
Apply only Prompt 48 Part B.

Scope:
- Implement the sector-aware runtime topology backbone in `MapRuntimeState`.

Required outcomes:
- deliberate start anchor, not arbitrary or top-heavy spawn
- readable first `2-4` route choices from that opening anchor
- primary spine
- branch pockets
- local reconnects only
- late-pressure outer pockets

Do not:
- widen save payload shape by default
- move truth into UI
- hide `escalate first` if a boundary move becomes necessary

Validation:
- validate_architecture_guards
- targeted runtime map tests
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact runtime topology behavior replaced
- exact start-anchor behavior landed
- explicit confirmation whether save shape and flow state stayed unchanged
- checkpoint:
  - screenshot/readback artifacts used
  - whether any legacy runtime lane still remains live
  - exact next-prompt risks for Prompt `49-50`
```

### Part C - Runtime Closeout Sync

```text
Apply only Prompt 48 Part C.

Scope:
- Land the narrowest docs/test sync needed after Part B.

Do not:
- widen into placement/render/asset work

Validation:
- validate_architecture_guards
- touched tests

Report:
- files changed
- any remaining runtime topology risks that Prompt 49-50 must pick up
```
