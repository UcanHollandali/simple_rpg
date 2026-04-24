# Prompt 18 - Map Final Hygiene Closeout

Use this prompt after Prompt 17 cleanup, directly after Prompt 16 if cleanup is explicitly skipped, or directly after Prompt 15 if asset smoke and cleanup are both explicitly skipped.
This pack is the final hygiene closeout for the active map-system wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/18_map_final_hygiene_closeout.md`

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
- Prompt 17 output if Prompt 17 ran
- latest portrait captures and test logs

Preflight:
- touched owner layer: `final docs/handoff hygiene + narrow cleanup fix only if directly justified`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`; asset closeout decisions also defer to `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- impact: `review first / runtime truth-save shape-asset provenance unchanged unless a narrow docs correction is explicitly justified`
- minimum validation set: `validate_assets + validate_architecture_guards + targeted map tests + scene isolation + portrait capture + full suite + stale prompt/doc scan + git diff --check`

## Goal

Close the wave with repo truth that a new continuation can trust:
- one default map presentation lane
- non-default lanes labeled `wrapper`, `fallback`, or `retired`
- final center-local start and north/south/east/west route-read truth stated honestly
- no stale prompt numbering or old wave authority drift
- screenshot/readback truth separated from test green
- next lane chosen honestly

## Required Outcomes

- final prompt order and queue state are checked
- `HANDOFF` and `ROADMAP` are updated if next-state truth changed
- stale references to superseded prompt names, old default lanes, or closed cleanup targets are scanned
- final captures and validation are summarized separately
- final closeout explicitly says whether the map achieved center-outward small-world identity or still needs structural continuation
- next lane is exactly one of: `structural continuation`, `asset candidate`, `production art`, or `broader cleanup`

## Hard Guardrails

- no broad implementation under final hygiene
- no partial improvement labeled as green
- no candidate art as structural proof
- no save/flow/source-of-truth ownership drift
- no ambiguous co-live default lanes
- no hidden cleanup outside the map wave

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- stale prompt/doc/reference scan
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- final closeout is findings-first and screenshot-grounded
- exactly one default lane is named
- every non-default lane has status
- docs do not point future agents at superseded prompt truth
- next lane is explicit

## Copy/Paste Parts

### Part A - Final Hygiene Audit

Apply only Prompt 18 Part A.

Scope:
- audit final docs, prompt order, lane status, captures, tests, and stale references

Do not:
- patch code in Part A

Validation:
- full Prompt 18 validation stack

Report:
- findings first
- confirmed / inferred / unknown
- screenshot paths reviewed
- validation results separated from visual truth
- stale refs or lane ambiguity found

### Part B - Final Hygiene Patch

Apply only Prompt 18 Part B.

Scope:
- land only narrow doc/test/cleanup fixes directly justified by Part A

Do not:
- widen into a new implementation wave

Validation:
- full Prompt 18 validation stack

Report:
- files changed
- exact stale truth corrected
- exact remaining failure not corrected
- exact default lane status

### Part C - Final Closeout

Apply only Prompt 18 Part C.

Scope:
- recheck and close the active wave honestly

Do not:
- overstate unresolved work

Validation:
- full Prompt 18 validation stack

Report:
- findings first
- whether the wave is honestly closed
- exactly one default lane
- every non-default lane status
- exact next lane
