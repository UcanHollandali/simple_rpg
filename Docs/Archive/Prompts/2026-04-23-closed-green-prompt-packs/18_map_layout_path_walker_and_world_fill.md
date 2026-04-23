# Prompt 18 - Map Layout Path Walker And World Fill

Use this prompt pack only after Prompt 17 is closed green.
This pack converges fixed-board placement, path readability, walker motion, and non-routing world fill.
It is not a topology pack and it is not the asset-hook pack.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/18_map_layout_path_walker_and_world_fill.md`
- checked-in filename and logical queue position now match Prompt `18`

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
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_layout_solver.gd`
- `Game/UI/map_route_binding.gd`
- `Game/UI/map_route_layout_helper.gd`
- `Game/UI/map_route_motion_helper.gd`
- `Game/UI/map_board_ground_builder.gd`
- `Game/UI/map_board_filler_builder.gd`
- directly related map tests

## Goal

Make the corrected graph read as a fixed, discoverable board world:

- node placement stays inside the safe playable rect
- paths are readable and stable
- walker movement is physical on the board
- world fill comes after structure
- filler remains non-routing

## Direction Statement

- layout follows topology and family placement
- path generation follows stable graph/layout truth
- walker moves on the board, not through board translation
- ground/ruin/forest/canopy fill comes after node/path structure
- portrait capture and seed sweep are required before signoff

## World-Fill Requirements

- filler anchors/masks are derived after node and path placement
- filler is visual-world only
- filler must not become traversal truth
- remaining negative space may be filled by:
  - ground
  - ruin
  - forest
  - canopy
  - clutter

## Hard Guardrails

- No graph-truth change in this pack.
- No save shape change.
- No flow-state change.
- No owner move.
- No asset approval/hookup beyond existing procedural/runtime-owned surfaces.
- No weakening of the fixed-board baseline.

## Validation

- layout/path continuity
- walker motion verification
- portrait captures
- portrait seed sweep
- explicit full-suite checkpoint

## Done Criteria

- the graph reads as a stable board world on portrait captures
- crossings/spaghetti stay controlled
- walker motion feels board-local
- filler stays non-routing and additive

## Copy/Paste Parts

### Part A - Baseline Capture

```text
Apply only Prompt 18 Part A.

Scope:
- Capture baseline portrait screenshots after Prompt 17:
  - stage start
  - mid progression
  - late progression
- Catalogue visible problems:
  - bad spread
  - path confusion
  - walker mismatch
  - filler fighting routes

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards

Report:
- screenshot paths
- concise regression catalogue
```

### Part B - Layout And Path Convergence

```text
Apply only Prompt 18 Part B.

Scope:
- Tune composer/layout spread, safe-rect fitting, jitter, branch spacing, and path generation so the fixed-board graph reads clearly on portrait targets.
- Preserve frozen-layout semantics and landed topology truth.

Do not:
- change MapRuntimeState graph truth
- widen into asset work

Validation:
- targeted layout/composer tests
- map scene isolation
- portrait captures
- full-suite checkpoint

Report:
- files changed
- layout/path rules adjusted
- before/after portrait comparison
```

### Part C - Walker And World Fill

```text
Apply only Prompt 18 Part C.

Scope:
- Tighten walker motion on the fixed board.
- Converge ground/filler/forest/canopy masks after node/path structure.
- Keep all filler non-routing.

Do not:
- move world fill into gameplay truth
- change save/flow/owner boundaries

Validation:
- route continuity checks
- walker motion verification
- portrait seed sweep
- targeted tests
- full-suite checkpoint

Report:
- files changed
- walker/world-fill problems fixed
- remaining visual risks, if any
```

### Part D - Signoff And Closeout

```text
Apply only Prompt 18 Part D.

Scope:
- Re-capture portrait screenshots and compare against Part A baseline.
- Update Docs/HANDOFF.md and Docs/ROADMAP.md only if Parts A-C are green.
- Record whether the map is asset-ready for Prompt 19 and audit-ready for Prompt 20.

Do not:
- claim asset polish is already landed
- overstate layout signoff if visual regressions remain

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- full-suite checkpoint if code changed in this part

Report:
- final screenshot set
- pass/fail signoff statement
- explicit readiness note for Prompt 19 and Prompt 20
```
