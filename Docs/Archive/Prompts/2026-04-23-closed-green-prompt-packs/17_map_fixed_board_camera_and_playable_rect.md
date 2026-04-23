# Prompt 17 - Map Fixed Board Camera And Playable Rect

Use this prompt pack only after Prompt 16 is closed green.
This pack resets the board/camera model before deeper layout/world-fill work.
It is not a topology pack and it is not an asset pack.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/17_map_fixed_board_camera_and_playable_rect.md`
- checked-in filename and logical queue position now match Prompt `17`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`

Primary write surface:
- `scenes/map_explore.gd`
- `Game/UI/map_route_binding.gd`
- `Game/UI/map_route_layout_helper.gd`
- `Game/UI/map_focus_helper.gd`
- `Game/UI/map_route_motion_helper.gd`
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_layout_solver.gd`
- directly related map tests

## Goal

Retire the moving-board camera/focus chain from the desired model so the map becomes a fixed board diorama:

- board fixed
- camera fixed
- character/walker moves on the board
- graph/layout stay inside a playable rect with safe margins

## Direction Statement

- no camera follow as the desired end state
- no route-follow recenter as the desired end state
- moving the character must not move the world under them
- emergency fallback may remain only as a narrow exceptional lane
- graph truth remains runtime-owned in `MapRuntimeState`

## Playable Rect Requirements

- define a visible playable map rect inside the portrait board
- keep node centers inside the safe envelope
- include margin for:
  - node radius
  - path stroke width
  - walker sprite footprint
  - overlay clearance
- prefer generation/placement envelopes over late clamp-only rescue

## Hard Guardrails

- No graph-truth change in this pack.
- No save shape change.
- No flow-state change.
- No owner move.
- No asset hookup.
- No widening of routing truth into UI.

## Validation

- current focus-chain audit
- map scene isolation
- no-follow verification
- portrait captures
- explicit full-suite checkpoint

## Done Criteria

- the desired model is fixed board + fixed camera
- board drift/follow is no longer treated as the target behavior
- node/path/walker safe bounds are explicit
- current moving-camera logic is either retired or clearly isolated as non-default fallback

## Copy/Paste Parts

### Part A - Focus Chain Audit

```text
Apply only Prompt 17 Part A.

Scope:
- Audit the live board/camera/focus chain before patching.
- Record the current roles of:
  - `_route_layout_offset`
  - `MapFocusHelper`
  - route camera follow progress
  - any recenter / clamp / emergency fallback logic

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards

Report:
- exact files/functions carrying follow/recenter behavior
- explicit note whether the desired fixed-board model can land without `escalate first`
```

### Part B - Fixed Board Reset

```text
Apply only Prompt 17 Part B.

Scope:
- Reset the desired board/camera model to fixed board + fixed camera.
- Remove or retire route-follow/recenter behavior as the default traversal presentation.
- Keep the walker moving on the board instead of moving the board under the walker.

Do not:
- change MapRuntimeState graph truth
- widen into asset work
- move traversal truth into UI

Validation:
- map scene isolation
- no-follow verification
- portrait captures
- full suite checkpoint

Report:
- files changed
- follow/recenter behavior retired or isolated
- remaining exceptional/fallback behavior, if any
```

### Part C - Playable Rect And Safe Bounds

```text
Apply only Prompt 17 Part C.

Scope:
- Introduce or tighten the playable-rect / safe-bounds contract for the fixed board.
- Cover:
  - node safe margins
  - path bounds
  - walker footprint
  - overlay clearance
- Prefer generation/placement-envelope fixes over late clamp-only rescue.

Do not:
- widen into topology or family-placement changes
- change save/flow/owner boundaries

Validation:
- map scene isolation
- portrait captures
- targeted tests
- full suite checkpoint

Report:
- files changed
- safe-bounds rules introduced or tightened
- remaining visual risks, if any
```

### Part D - Closeout Sync

```text
Apply only Prompt 17 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md only if Parts A-C are green.
- Record that the desired model is now fixed board / fixed camera / walker on board.
- Keep Prompt 18-20 clearly open.

Do not:
- claim layout/world-fill or asset polish is already landed

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- readiness note for Prompt 18
```
