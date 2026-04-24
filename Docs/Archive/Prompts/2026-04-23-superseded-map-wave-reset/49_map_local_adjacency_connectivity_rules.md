# Prompt 49 - Map Local Adjacency And Connectivity Rules

Use this prompt only after Prompt 48 is closed green.
This pack narrows the connectivity grammar so the map stops feeling globally over-connected.

Checked-in filename note:
- this pack lives at `Docs/Promts/49_map_local_adjacency_connectivity_rules.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- Prompt `43-48` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/RuntimeState/map_runtime_state.gd`
- relevant map tests

Preflight:
- touched owner layer: `Game/RuntimeState`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth may change / save shape unchanged by default / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted runtime map tests + full suite checkpoint`

## Goal

Reject global nearest-neighbor style connectivity and replace it with constrained local adjacency rules.

## Required Connectivity Rules

- local candidate set only
- forward-progress bias
- max branch degree budget
- reconnect budget
- cross-map diagonal rejection
- edge-crossing rejection
- clear rules for:
  - which nodes should typically have `1` edge out
  - which can get `2`
  - which may rarely get `3`

## Hard Guardrails

- No save-shape change unless the prompt stops with `escalate first`.
- No owner move.
- No UI-owned connectivity logic.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted runtime map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- adjacency no longer behaves like broad global freedom
- route choices become more local and directional
- later road routing prompts can assume the graph is no longer fighting them

## Copy/Paste Parts

### Part A - Connectivity Audit

```text
Apply only Prompt 49 Part A.

Scope:
- Audit current adjacency and reconnect logic against the new local-connectivity rules.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted runtime map tests

Report:
- exact current connectivity rules
- exact drift from the new local-connectivity target
- whether any later correction would require `escalate first`
```

### Part B - Connectivity Implementation

```text
Apply only Prompt 49 Part B.

Scope:
- Implement the new local adjacency and connectivity rules in the runtime owner.

Required outcomes:
- local candidate sets
- forward-progress bias
- edge budget control
- reconnect budget
- diagonal/cross-map rejection

Do not:
- change save shape by default
- move routing truth into UI

Validation:
- validate_architecture_guards
- targeted runtime map tests
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact connectivity rules now enforced
- remaining risks for Prompt 50-51
```
