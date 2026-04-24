# Prompt 60 - Final Integrated Audit Review Patch And Closeout

Use this prompt only after Prompt 59 is closed green.
This pack is the final integrated closeout gate for the full map-system replacement slice before the dedicated cleanup and hygiene prompts.

Checked-in filename note:
- this pack lives at `Docs/Promts/60_map_final_integrated_audit_review_patch_closeout.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/ASSET_PIPELINE.md`
- Prompt `43-59` outputs

Preflight:
- touched owner layer: `full wave integrated review`
- authority doc: `Docs/MAP_CONTRACT.md` plus the closest touched authority docs
- impact: `review first / narrow corrective patch only if clearly justified / no silent boundary crossing`
- minimum validation set: `validate_architecture_guards + touched tests + portrait verification + full suite checkpoint + git diff --check`

## Goal

Audit the full `43-59` chain honestly, allow only a justified narrow corrective patch, and close out the wave without renaming blockers as success.

## Required Review Order

- contract
- runtime topology
- placement
- corridors
- walker
- landmarks
- terrain and filler
- candidate assets
- map-adjacent UI
- default switch state
- docs
- tests

## Hard Guardrails

- No hidden scope-widening in the final patch.
- No success claim if the small-world target is still structurally unmet.
- Do not close the wave if visible checkerboard/cell-centering, weak pocket-defining roads, landmark-clearing failure, or asset/filler rescue still reproduce.
- Any high-risk boundary crossing must still be called out as `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- touched validators and targeted tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- the final repo truth is stated clearly
- any remaining blocker is explicit
- closeout docs are honest
- future continuations know whether the system slice is ready for Prompt 61 cleanup and Prompt 62 final hygiene closeout
- exactly one lane is default, and any non-default legacy lane is explicitly wrapper/fallback/retired rather than accidentally co-live

## Copy/Paste Parts

### Part A - Final Integrated Review

```text
Apply only Prompt 60 Part A.

Scope:
- Audit the full Prompt 43-59 chain against the final target.

Do not:
- patch code in Part A
- hide residual failures behind local wins

Validation:
- validate_architecture_guards
- touched tests
- scene isolation
- portrait capture
- full suite checkpoint

Report order:
1. findings first
2. confirmed / inferred / unknown
3. exact screenshot paths reviewed
4. exact blockers still open or explicit pass judgment
```

### Part B - Final Narrow Patch

```text
Apply only Prompt 60 Part B.

Scope:
- Land only the final narrow corrective patch justified by Part A.

Do not:
- widen into another subsystem pass
- move authority boundaries silently

Validation:
- validate_architecture_guards
- touched tests
- scene isolation if needed
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact blocker corrected
- exact residual blocker left open if any
```

### Part C - Closeout Sync

```text
Apply only Prompt 60 Part C.

Scope:
- Sync closeout docs and final wave state after the Part A or Part B outcome.

Do not:
- rewrite archive history

Validation:
- validate_architecture_guards
- git diff --check

Report:
- docs changed
- final wave state
- closed vs open vs technically paused truth
```
