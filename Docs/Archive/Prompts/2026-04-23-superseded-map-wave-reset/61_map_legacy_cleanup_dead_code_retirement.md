# Prompt 61 - Map Legacy Cleanup And Dead-Code Retirement

Use this prompt only after Prompt 60 is closed green.
This pack removes stale, passive, superseded, and engine-unused map surfaces left behind by the rebuild wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/61_map_legacy_cleanup_dead_code_retirement.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- Prompt `43-60` replacement-slice outputs
- touched map runtime/UI/scenes/tests/tools/docs surfaces from the wave

Preflight:
- touched owner layer: `full map slice cleanup across runtime/UI/scenes/tests/tools/docs as justified by the shipped replacement`
- authority doc: `Docs/MAP_CONTRACT.md` plus the closest touched authority docs
- impact: `runtime truth preserved / save shape preserved / asset-provenance may shrink only truthfully if stale candidate surfaces are removed`
- minimum validation set: `validate_architecture_guards + touched tests + scene isolation + portrait capture + full suite checkpoint + git diff --check`

## Goal

Retire stale legacy paths, dead helper surfaces, obsolete fallback logic, and passive unused code that no longer belongs after the new map system is live.

## Required Outcomes

- remove proven dead or superseded map code
- remove stale fallback lanes that only existed for the replaced system
- remove passive unused asset hooks or docs pointers that no longer resolve to the live map truth
- keep uncertain or not-provably-dead surfaces out of the patch and call them out instead

## Hard Guardrails

- Do not remove uncertain surfaces without evidence.
- Do not silently change owner meaning while "cleaning up".
- Do not treat hotspot size alone as proof that code is dead.
- Any compatibility or save-sensitive removal that crosses owner meaning must still be called out as `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- touched validators and targeted tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- stale, replaced, or dead map-system surfaces are retired
- no live behavior regresses
- remaining uncertain cleanup is explicitly deferred rather than guessed

## Copy/Paste Parts

### Part A - Legacy/Dead-Code Audit

```text
Apply only Prompt 61 Part A.

Scope:
- Audit the shipped Prompt 43-60 replacement slice for stale, passive, superseded, or engine-unused surfaces.

Do not:
- patch code in Part A
- guess that a surface is dead without evidence

Validation:
- validate_architecture_guards
- readback only

Report:
- findings first
- exact files/functions/assets/docs that look stale
- exact evidence for "dead", "superseded", or "still uncertain"
- explicit separation between safe cleanup and escalate-first removal
```

### Part B - Narrow Cleanup Patch

```text
Apply only Prompt 61 Part B.

Scope:
- Remove only the stale, passive, superseded, or engine-unused surfaces that the Part A audit proved safe to retire.

Do not:
- widen into fresh feature work
- remove uncertain compatibility surfaces
- hide behavior changes inside cleanup

Validation:
- validate_architecture_guards
- touched validators and tests
- scene isolation
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact dead/stale surfaces removed
- exact uncertain cleanup intentionally left alone
```

### Part C - Cleanup Re-Audit

```text
Apply only Prompt 61 Part C.

Scope:
- Re-audit the checked-in map slice after the cleanup patch.

Do not:
- widen into another refactor

Validation:
- validate_architecture_guards
- touched tests
- portrait capture

Report:
- findings first
- whether stale passive map surfaces still remain
- exact cleanup debt deferred to future escalation if any
```
