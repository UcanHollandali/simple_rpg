# Prompt 58 - First Integrated Structural Playtest And Screenshot Review

Use this prompt only after Prompt 55 is closed green.
This pack is the first integrated review checkpoint for the full map-system replacement wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/58_map_first_integrated_playtest_screenshot_review.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-55` outputs
- Prompt `47.5` structural metrics outputs
- Prompt `57` baseline harness outputs

Preflight:
- touched owner layer: `full map slice review, with narrow corrective patch only if findings justify it`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `review first / runtime truth-save shape-asset provenance only if a narrow corrective patch is clearly justified`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait seed sweep + full suite checkpoint`

## Goal

Run the first integrated structural review of the new map-system wave against the intended small-world target and refuse to hide remaining failures behind local wins.
This prompt owns the green-switch decision for the side-by-side replacement lane.

## Required Checks

- scene isolation for `scenes/map_explore.tscn`
- portrait capture at `1080x1920`
- progressed and late seeded screenshot sweep
- targeted map tests
- full suite checkpoint

## Explicit Failure Conditions

- central cluster read
- top-heavy cluster read
- unreadable first-route choice read from the start anchor
- weak directionality
- roads not reading first
- roads failing to define pockets
- roads cutting through landmark space
- landmarks still feeling like icons
- landmark pockets lacking a readable local clearing
- lower half still underused
- visible checkerboard / visible cell-centering / obvious symmetry read
- asset/filler rescuing weak structure instead of reinforcing good structure
- UI illusion break

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- the integrated board truth is stated honestly
- any corrective patch stays narrow and justified
- the next continuation pass knows whether the structure is green enough to justify Prompt 56 candidate art
- if roads, landmarks, and terrain masks are not already assets-free green, Prompt `56` stays closed and that stop is stated explicitly
- the default-switch decision is explicit:
  - either the new lane becomes default here
  - or the old lane explicitly stays default pending later work

## Copy/Paste Parts

### Part A - Findings-First Review

```text
Apply only Prompt 58 Part A.

Scope:
- Audit the current checked-in integrated map against the full wave target.

Do not:
- patch code in Part A
- relabel visual failure as success

Validation:
- validate_architecture_guards
- targeted map tests
- scene isolation
- portrait seed sweep
- full suite checkpoint

Report order:
1. findings first
2. confirmed / inferred / unknown
3. exact screenshot paths reviewed
4. whether the current board is converging or still structurally off target
```

### Part B - Narrow Corrective Patch

```text
Apply only Prompt 58 Part B.

Scope:
- Land only the narrow corrective patch directly justified by the Part A findings.

Do not:
- widen into new feature work
- hide broad failure behind a cosmetic patch

Required outcome:
- if the green-switch gate is satisfied, own the default-switch patch here
- otherwise state explicitly that the legacy lane remains default and why

Validation:
- validate_architecture_guards
- targeted tests
- scene isolation
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact failure corrected
- exact default-switch decision taken
- exact remaining failure not addressed by this patch
- checkpoint:
  - whether Prompt `56` is still blocked by assets-free structural failure
  - whether any legacy lane still remains live
  - exact next-prompt risks for Prompt `56` or Prompt `59`
```

### Part C - Review Recheck

```text
Apply only Prompt 58 Part C.

Scope:
- Re-audit the corrected board after Part B.

Do not:
- widen into another patch

Validation:
- validate_architecture_guards
- targeted tests
- portrait capture

Report:
- findings first
- whether the explicit fail conditions still reproduce
- whether the wave is ready for Prompt `56`
- whether the board is assets-free green or must stop before candidate art
```
