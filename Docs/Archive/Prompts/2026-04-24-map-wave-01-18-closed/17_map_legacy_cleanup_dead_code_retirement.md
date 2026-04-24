# Prompt 17 - Map Legacy Cleanup Dead Code Retirement

Use this prompt after Prompt 16 asset smoke, or directly after Prompt 15 if Prompt 15 explicitly skips asset smoke and says cleanup is safe.
This pack retires proven non-default map lanes, dead code, stale tests, and stale docs left by the replacement wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/17_map_legacy_cleanup_dead_code_retirement.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 15 output
- Prompt 16 output if Prompt 16 ran
- current `git status --short`
- relevant map UI/runtime/tests/tools files named by Prompt 15

Preflight:
- touched owner layer: `retired map presentation lanes + tests/docs/tools directly tied to cleanup`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`; asset cleanup/provenance decisions also defer to `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance may change only for evidence-backed cleanup with truthful manifest updates`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + full suite + stale symbol scan + git diff --check`

## Goal

Make the repo easier to continue by removing or clearly retiring map code that Prompt 15 proved is no longer a default lane:
- old stroke/decal road paths
- obsolete wrapper/fallback surfaces
- dead helper methods and duplicate constants
- stale tests that assert retired behavior
- stale doc wording that implies co-live defaults

Cleanup is not allowed to remove evidence or fallback paths that are still needed to debug a structurally short board.

## Required Outcomes

- every deletion or retirement cites Prompt 15 evidence
- scene/resource references are scanned before removing Godot files
- tests move toward the single default lane instead of preserving retired behavior
- non-default lanes left in place are labeled `wrapper`, `fallback`, or `retired`
- cleanup does not change gameplay rules, graph truth, save shape, flow state, or asset provenance

## Hard Guardrails

- do not delete code only because it looks old
- do not remove a fallback that Prompt 15 still needed for honest comparison
- do not change save schema/version or flow states
- do not move runtime truth into UI
- do not add candidate art
- do not broad-refactor unrelated UI, combat, support, inventory, or tools surfaces

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests for touched files
- stale symbol/reference scan for removed names
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- cleanup is evidence-backed and narrow
- no ambiguous co-live default lane remains because of stale code/docs/tests
- removed names have no live references
- Prompt 18 can perform final hygiene without rediscovering stale lane ambiguity

## Copy/Paste Parts

### Part A - Cleanup Audit

Apply only Prompt 17 Part A.

Scope:
- audit Prompt 15 retired/fallback/wrapper list and Prompt 16 smoke assets against code, scenes, tests, tools, docs, and manifest

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map tests
- stale symbol/reference scan

Report:
- findings first
- exact cleanup candidates with evidence
- exact candidates that must stay
- exact files to change in Part B

### Part B - Dead Code Retirement Patch

Apply only Prompt 17 Part B.

Scope:
- remove or label only cleanup targets proven safe by Part A

Do not:
- widen into feature work or visual redesign
- delete unproven fallback/debug evidence
- alter runtime/save/flow/source-of-truth ownership
- remove or promote smoke assets without explicit Prompt 16 evidence and manifest updates

Validation:
- full Prompt 17 validation stack

Report:
- files changed
- exact code/tests/docs retired
- exact names scanned as stale
- exact fallback/wrapper surfaces intentionally left

### Part C - Cleanup Recheck

Apply only Prompt 17 Part C.

Scope:
- recheck that cleanup left one default lane and no stale refs

Do not:
- claim final wave completion; Prompt 18 owns that

Validation:
- full Prompt 17 validation stack

Report:
- findings first
- whether Prompt 18 can start
- remaining cleanup risks
