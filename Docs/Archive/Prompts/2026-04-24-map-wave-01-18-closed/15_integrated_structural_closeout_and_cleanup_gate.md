# Prompt 15 - Integrated Structural Closeout And Cleanup Gate

Use this prompt after Prompt 14 closes asset-socket readiness.
This pack owns the integrated structural closeout and decides whether asset smoke and cleanup can run.
It is not the final wave hygiene closeout; Prompt 18 owns that.

Checked-in filename note:
- this pack lives at `Docs/Promts/15_integrated_structural_closeout_and_cleanup_gate.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 01 through Prompt 14 outputs
- current portrait review exports
- `Tools/run_portrait_review_capture.ps1`
- `Tools/map_review_capture_helper.gd`

Preflight:
- touched owner layer: `full map slice review; narrow corrective patch only if directly justified`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`; asset gate decisions also defer to `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- impact: `review first / runtime truth-save shape-asset provenance unchanged unless a narrow corrective patch is explicitly justified`
- minimum validation set: `validate_assets + validate_architecture_guards + targeted map tests + scene isolation + portrait capture + full suite + git diff --check`

## Goal

Close the structural map work only if the board truth is honest.
The closeout must answer:
- does it feel like a fixed small world rather than a moving diagram?
- does each seed feel different while remaining readable?
- does the center-local start open into readable north/south/east/west exploration without collapsing into a fixed upward ladder?
- do roads divide the world?
- do nodes read as places/pockets?
- does walker traversal support exploration and hunger pressure?
- is asset dressing structurally ready without relying on candidate art?
- exactly one default lane, with every other lane labeled `wrapper`, `fallback`, or `retired`

## Required Outcomes

- fresh start-frame and seeded mid/late captures are reviewed
- seeds `11`, `29`, `41`, plus at least two additional random seeds are included or explicitly deferred with reason
- tests and captures are separated in the report
- remaining structural, visual, scene-shell, asset-socket, asset-smoke, or cleanup gaps are explicit
- `HANDOFF` and `ROADMAP` are updated only if the closeout truth changes next-state guidance
- gate decision is exactly one of: `run Prompt 16 asset smoke`, `skip asset smoke and run Prompt 17 cleanup`, `skip asset smoke and cleanup and go to Prompt 18 hygiene`, or `stop for structural continuation`
- closeout explicitly summarizes remaining or resolved Fixed-Board Visual System Rules 1-7 gaps as reference evidence only

## Hard Guardrails

- no broad new implementation wave under closeout
- no partial improvement labeled as green
- no candidate art as structural proof
- no save/flow/source-of-truth ownership drift
- no ambiguous co-live default lanes

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- closeout is findings-first and screenshot-grounded
- exactly one default lane is named
- non-default lanes are wrapper/fallback/retired
- asset-smoke/cleanup gate decision is explicit
- unresolved gaps are not hidden

## Copy/Paste Parts

### Part A - Integrated Review

Apply only Prompt 15 Part A.

Scope:
- audit the full map slice against Prompt 01 target and Prompt 02 baseline failures

Do not:
- patch code in Part A

Validation:
- full Prompt 15 validation stack

Report:
- findings first
- confirmed / inferred / unknown
- screenshot paths reviewed
- exact target gaps still visible
- Fixed-Board Visual System Rules 1-7 integrated gap summary
- default/non-default lane judgment

### Part B - Narrow Closeout Patch

Apply only Prompt 15 Part B.

Scope:
- land only the narrow corrective patch directly justified by Part A

Do not:
- widen into a new implementation wave

Validation:
- full Prompt 15 validation stack

Report:
- files changed
- exact failure corrected
- exact remaining failure not corrected
- exact default lane status
- Fixed-Board Visual System Rules 1-7 closeout wording changed or still open
- exact asset-smoke/cleanup gate candidate

### Part C - Structural Closeout Gate

Apply only Prompt 15 Part C.

Scope:
- recheck and close the structural map slice honestly

Do not:
- overstate unresolved work

Validation:
- full Prompt 15 validation stack

Report:
- findings first
- whether the structural map slice is honestly closed
- exactly one default lane
- every non-default lane status
- exact asset-smoke/cleanup gate decision
- remaining Fixed-Board Visual System Rules 1-7 gaps
