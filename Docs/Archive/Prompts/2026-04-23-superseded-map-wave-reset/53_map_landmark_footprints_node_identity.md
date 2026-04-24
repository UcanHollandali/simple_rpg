# Prompt 53 - Map Landmark Footprints And Node Identity

Use this prompt only after Prompt 52 is closed green.
This pack moves node presentation away from icon circles and toward local landmark pockets.

Checked-in filename note:
- this pack lives at `Docs/Promts/53_map_landmark_footprints_node_identity.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-52` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/ui_asset_paths.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged by default`
- minimum validation set: `validate_architecture_guards + targeted map tests + portrait capture + full suite checkpoint`

## Goal

Make nodes read as small places on the board instead of abstract circles floating over roads.

## Required Outcomes

Each current family should gain a local landmark-footprint grammar:
- `combat`
- `reward`
- `event`
- `hamlet`
- `rest`
- `merchant`
- `key`
- `boss`

Meaning:
- logic stays runtime-owned
- presentation becomes:
  - landmark anchor
  - pocket mask
  - local clearing
  - local signage / identity
  - route relationship

## Hard Guardrails

- No gameplay truth move into presentation.
- No final asset claim in this prompt.
- Do not widen into the broader candidate-asset spike unless strictly necessary.
- Landmark/icon fallback must stay secondary; if the icon disappears, the node should still mostly read from its pocket and clearing.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- portrait capture
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- nodes read as places, not just icons
- route pockets and local identity are materially stronger
- landmark pockets own a readable local clearing
- current family meaning remains truthful

## Copy/Paste Parts

### Part A - Landmark Identity Audit

```text
Apply only Prompt 53 Part A.

Scope:
- Audit current node identity and local pocket read against the landmark-footprint target.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted map tests
- portrait capture

Report:
- exact families still reading like abstract icons
- exact surfaces that should own local landmark identity
```

### Part B - Landmark Footprint Implementation

```text
Apply only Prompt 53 Part B.

Scope:
- Implement landmark-footprint presentation for the current runtime-backed node families.

Do not:
- move family truth into UI
- claim final asset quality

Validation:
- validate_architecture_guards
- targeted map tests
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact family footprint behavior landed
- before/after screenshot paths
```
