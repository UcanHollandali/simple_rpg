# Prompt 52 - Map Walker Traversal And Route Read

Use this prompt only after Prompt 51 is closed green.
This pack makes the chosen route and the walker read as one clear traversal lane.

Checked-in filename note:
- this pack lives at `Docs/Promts/52_map_walker_traversal_route_read.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-51` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `Game/UI/map_route_binding.gd`
- `Game/UI/map_route_motion_helper.gd`
- `scenes/map_explore.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI + scenes`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map/UI tests + map scene isolation + portrait captures + full suite checkpoint`

## Goal

Keep the board fixed while making the walker, selected route, and active route read like one coherent traversal lane.

## Required Outcomes

- fixed board and fixed camera remain true
- walker follows corridor lane
- selected route and active lane visually reinforce each other
- hover/preview does not fight the final traversal lane
- neighboring curves do not steal attention from the chosen lane
- walker and route preview do not read like they are cutting through landmark clearings

## Hard Guardrails

- No moving-board follow.
- No flow-state change.
- No traversal truth ownership move.
- Do not let walker motion or preview lines imply off-corridor movement that the runtime cannot actually perform.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map/UI tests
- map scene isolation
- portrait capture
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- walker feels lane-bound, not world-drifting
- selected route and traveled route read as one path
- route ownership ambiguity is materially reduced
- walker motion respects landmark pockets instead of visually trampling them

## Copy/Paste Parts

### Part A - Walker / Route Audit

```text
Apply only Prompt 52 Part A.

Scope:
- Audit the current walker, hover, selection, and active route read.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- targeted map/UI tests
- map scene isolation

Report:
- exact files/functions carrying route-read ambiguity
- whether the fixed-board model still holds cleanly
```

### Part B - Walker Lane Implementation

```text
Apply only Prompt 52 Part B.

Scope:
- Tighten walker traversal and selected-route read so they reinforce the same corridor lane.

Do not:
- reintroduce board/camera follow
- change movement truth ownership

Validation:
- validate_architecture_guards
- targeted map/UI tests
- map scene isolation
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact route-read behavior improved
- remaining traversal feel risks, if any
```
