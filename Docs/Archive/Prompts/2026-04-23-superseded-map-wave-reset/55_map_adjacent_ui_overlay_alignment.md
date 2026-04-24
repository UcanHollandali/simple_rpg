# Prompt 55 - Map-Adjacent UI And Overlay Alignment

Use this prompt only after Prompt 54 is closed green.
This pack keeps map-adjacent UI and overlay surfaces from breaking the small-world map illusion.

Checked-in filename note:
- this pack lives at `Docs/Promts/55_map_adjacent_ui_overlay_alignment.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- Prompt `43-54` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs
- `scenes/map_explore.gd`
- `Game/UI/map_quest_log_panel.gd`
- `Game/UI/safe_menu_overlay.gd`
- `Game/UI/map_route_binding.gd`
- related map/UI tests

Preflight:
- touched owner layer: `Game/UI + scenes`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged by default`
- minimum validation set: `validate_architecture_guards + targeted map/UI tests + scene isolation + portrait capture + full suite checkpoint`

## Goal

Align map-adjacent UI and overlay surfaces so they support the new landmark-road board instead of reading like unrelated HUD clutter.

## Required Outcomes

- quest log and settings surfaces stay truthful and mutually coherent
- route markers, key markers, and current-node focus surfaces do not overpower routes or landmarks
- overlay visibility, focus, and interaction rules do not break the small-world read
- map UI composition remains secondary to route/landmark hierarchy

## Hard Guardrails

- No gameplay-truth move into UI.
- No save-shape change.
- No overlay-system redesign beyond the narrow alignment needed for the map target.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_quest_log_ui.gd,test_save_ui.gd,test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- map-adjacent UI no longer hijacks the board read
- route and landmark hierarchy stays primary
- overlay interaction truth stays coherent during map use

## Copy/Paste Parts

### Part A - UI/Overlay Audit

```text
Apply only Prompt 55 Part A.

Scope:
- Audit map-adjacent UI and overlay surfaces against the new board target.

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- readback only

Report:
- exact UI/overlay illusion breaks
- exact files/functions involved
- explicit separation between facts and assumptions
```

### Part B - Narrow Alignment Patch

```text
Apply only Prompt 55 Part B.

Scope:
- Land the narrowest UI/overlay alignment patch needed so map-adjacent surfaces stop fighting the new board read.

Do not:
- redesign the overlay stack
- move gameplay truth into presentation

Validation:
- validate_architecture_guards
- targeted map/UI tests
- scene isolation
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact UI/overlay rule landed
- exact interaction truth preserved
```

### Part C - Focused Review

```text
Apply only Prompt 55 Part C.

Scope:
- Re-audit the checked-in map-adjacent UI after the Part B patch.

Do not:
- widen scope

Validation:
- validate_architecture_guards
- targeted tests
- portrait capture

Report:
- findings first
- whether the illusion break is closed
- any remaining narrow blocker
```
