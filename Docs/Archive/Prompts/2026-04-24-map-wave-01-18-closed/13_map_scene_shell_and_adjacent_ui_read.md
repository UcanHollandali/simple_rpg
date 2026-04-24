# Prompt 13 - Map Scene Shell And Adjacent UI Read

Use this prompt after Prompt 12 closes terrain and negative-space truth.
This pack checks whether the map scene shell, lower-board UI, and adjacent panels preserve the fixed-board small-world read.

Checked-in filename note:
- this pack lives at `Docs/Promts/13_map_scene_shell_and_adjacent_ui_read.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 12 output
- `scenes/map_explore.gd`
- `scenes/map_explore.tscn`
- `Game/UI/map_explore_scene_ui.gd`
- `Game/UI/map_explore_presenter.gd`
- `Game/UI/map_route_binding.gd`
- `Game/UI/run_status_strip.gd`
- `Game/UI/map_quest_log_panel.gd`
- related map scene/presenter tests

Preflight:
- touched owner layer: `Game/UI map scene shell + scenes/map_explore composition + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map scene/presenter tests + scene isolation + portrait capture + git diff --check`

## Goal

Make the surrounding interface support the map instead of fighting it:
- portrait board remains the first read
- center-local opening and north/south/east/west route directions remain readable inside the board
- lower third/lower board and side-board spaces are meaningful and not dead padding
- action controls, status strips, route copy, and quest/support panels do not occlude roads or pockets
- fixed board remains fixed; no camera/scrolling-board regression
- fallback/wrapper surfaces do not look like a second default lane

This prompt is presentation-only. It does not move route, discovery, current-node, hunger, pending-node, save, or flow truth into UI.

## Required Outcomes

- fresh start frame is reviewed specifically for center-local opening read, cardinal route pressure, lower-board, and adjacent-UI pressure
- map-adjacent UI is audited for overlap, crowding, and board-read damage
- route/action affordances remain usable without becoming the visual owner of route truth
- scene shell changes, if any, are narrow composition/presenter changes
- wrapper/fallback map surfaces visible in the scene are labeled for Prompt 15 or Prompt 17
- no candidate art is used as proof

## Hard Guardrails

- no gameplay truth in UI
- no save/flow/source-of-truth change
- no candidate art
- no broad app UI redesign
- no hiding structural map failures by covering them with panels
- no new default lane without screenshot/readback evidence

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map scene/presenter tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- map scene shell no longer contradicts the fixed-board read, or exact blockers are explicit
- lower-board/lower-third and side-board usage is honestly assessed
- adjacent UI surfaces are not mistaken for route/topology owners
- remaining wrapper/fallback scene surfaces are named before cleanup

## Copy/Paste Parts

### Part A - Scene Shell Audit

Apply only Prompt 13 Part A.

Scope:
- audit map scene shell, center-local/cardinal route read, lower-board/side-board usage, adjacent UI, overlays, and wrapper/fallback surfaces

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map scene/presenter tests
- capture review

Report:
- findings first
- exact UI surfaces that damage board read
- exact overlap/lower-board/side-board failures
- exact wrapper/fallback surfaces visible in the scene
- exact files to change in Part B

### Part B - Adjacent UI Patch

Apply only Prompt 13 Part B.

Scope:
- land only narrow presentation/composition fixes that preserve board read and control usability

Do not:
- change gameplay ownership, save shape, flow state, or route truth
- add candidate art
- mask map structure failures with UI chrome

Validation:
- full Prompt 13 validation stack

Report:
- files changed
- exact UI shell behavior changed
- before/after screenshot paths
- remaining adjacent-UI blockers
- fallback/wrapper surfaces left for cleanup

### Part C - Scene Shell Recheck

Apply only Prompt 13 Part C.

Scope:
- recheck live and seeded captures for board read under the scene shell

Do not:
- overclaim asset readiness; Prompt 14 owns sockets

Validation:
- full Prompt 13 validation stack

Report:
- findings first
- whether Prompt 14 can start
- remaining UI shell blockers
