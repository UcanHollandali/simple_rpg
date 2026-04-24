# Prompt 02 - Baseline Reproduction And Failure Naming

Use this prompt only after Prompt 01 closes its docs/process target lock.
This pack reproduces current visual/playtest truth and names failures before any new architecture work starts.

Checked-in filename note:
- this pack lives at `Docs/Promts/02_baseline_reproduction_and_failure_naming.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/TEST_STRATEGY.md`
- current `export/portrait_review/` outputs if present
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_board_style.gd`
- `Game/UI/map_route_binding.gd`
- `Tools/run_portrait_review_capture.ps1`
- `Tools/map_review_capture_helper.gd`

Preflight:
- touched owner layer: `review/capture only; no default code write`
- authority doc: `Docs/TEST_STRATEGY.md` plus `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Make the baseline impossible to overclaim.
The report must say whether the current board still reads as:
- dark blobs / abstract filler
- stroke or decal roads instead of walkable terrain
- icon/plate nodes instead of places
- weak center-outward route variation and directional exploration feel
- weak hunger route-pressure feel
- UI/dashboard frame rather than small-world board

## Required Outcomes

- fresh start-frame capture is reviewed
- seeded mid/late captures for seeds `11`, `29`, and `41` are reviewed
- at least two additional random seed sweeps are attempted or explicitly deferred with reason, so the reviewed set can meet the `5`-seed floor in `MAP_CONTRACT.md`
- readback metrics are separated from screenshot truth
- the report names gaps against `MAP_COMPOSER_V2_DESIGN.md` Fixed-Board Visual System Rules 1-7 without treating that reference doc as a rule source
- tests passing is explicitly not enough for structural green
- candidate art remains closed
- exact owner files for each visible failure are named

## Hard Guardrails

- no code patch in Part A
- no styling patch that hides failure
- no asset work
- no gameplay truth in UI
- no save/flow/source-of-truth change

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd,test_map_review_capture_helper.gd,test_map_quest_log_ui.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- baseline failures are named plainly
- screenshot paths reviewed are listed
- next implementation target is explicit
- candidate art remains closed

## Copy/Paste Parts

### Part A - Baseline Capture And Readback

Apply only Prompt 02 Part A.

Scope:
- run/read the minimum capture and test evidence needed to reproduce current map truth

Do not:
- patch code

Validation:
- Prompt 02 validation stack, excluding full suite unless already required by a code change

Report:
- screenshot paths reviewed
- readback metrics
- confirmed visual failures
- Fixed-Board Visual System Rules 1-7 gaps, separated from authority claims
- unknowns that need later prompts

### Part B - Failure Naming Sync

Apply only Prompt 02 Part B.

Scope:
- update only active docs/prompt notes if the baseline contradicts them

Do not:
- change runtime/UI behavior

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- docs/path truth check
- `git diff --check`

Report:
- files changed, if any
- exact stale wording fixed
- exact failures carried into Prompt 03+

### Part C - Recheck

Apply only Prompt 02 Part C.

Scope:
- recheck that the baseline report cannot be mistaken for green

Do not:
- relabel partial improvement as success

Validation:
- Prompt 02 validation stack

Report:
- findings first
- whether Prompt 03 can start
- exact blockers it must preserve
- remaining Fixed-Board Visual System Rules 1-7 gaps
