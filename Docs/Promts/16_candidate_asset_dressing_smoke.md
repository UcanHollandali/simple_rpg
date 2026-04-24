# Prompt 16 - Candidate Asset Dressing Smoke

Use this prompt only after Prompt 15 explicitly says the structural map slice and asset sockets are ready for a provisional asset-carry smoke.
This pack adds or wires the smallest possible candidate/placeholder dressing needed to prove sockets can carry assets.
It does not produce final art.

Checked-in filename note:
- this pack lives at `Docs/Promts/16_candidate_asset_dressing_smoke.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 14 output
- Prompt 15 output
- `AssetManifest/asset_manifest.csv`
- `SourceArt/`
- `Assets/`
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/ui_asset_paths.gd`
- related map/asset tests

Preflight:
- touched owner layer: `SourceArt/ + Assets/ + AssetManifest + Game/UI asset socket consumption + related Tests`
- authority doc: `Docs/ASSET_PIPELINE.md` plus `Docs/ASSET_LICENSE_POLICY.md`, `Docs/MAP_CONTRACT.md`, and `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance changes allowed only through truthful manifest rows`
- minimum validation set: `validate_assets + validate_architecture_guards + targeted map tests + scene isolation + portrait capture + full suite + git diff --check`

## Goal

Prove the map can carry art through the new socket system without using art as structural proof:
- one tiny path-surface dressing family, if needed
- one tiny landmark/pocket dressing family, if needed
- one tiny decor/filler dressing family, if needed
- dressing smoke must preserve the center-local opening and north/south/east/west route read
- deterministic socket placement across seeds
- no road, clearing, or pocket occlusion regression

The correct result is not "the map looks final."
The correct result is "the map structure still reads without assets, and the asset sockets can dress it without breaking it."

## Required Outcomes

- candidate/placeholder assets are minimal and visibly provisional
- every runtime asset has a truthful manifest row in the same patch
- source/master paths are known and reviewable
- `replace_before_release=yes` is used for placeholder/candidate assets
- asset placement is derived from sockets, not from gameplay truth or ad hoc node-family logic in the canvas
- screenshots compare asset-off or structural read against asset-on smoke where practical
- candidate assets are explicitly not used to claim road hierarchy, pockets, center-outward/cardinal structure, full-board structure, or terrain success

## Hard Guardrails

- no production art claim
- no unclear-license or unclear-provenance source
- no raw AI output promoted directly to runtime
- no asset from the user-provided direction image
- no candidate art as structural proof
- no save/flow/source-of-truth change
- no broad asset pack import
- no hiding weak roads or pockets with larger/darker art
- no cleanup/deletion work; Prompt 17 owns cleanup

## Allowed Asset Sources

Prefer:
- repo-authored placeholder source under `SourceArt/Edited/` or another active source lane
- simple runtime SVG/PNG exports under `Assets/` with matching manifest rows

Allowed only if provenance is fully truthful:
- AI-assisted placeholder source under `SourceArt/Generated/`, cleaned/promoted through the active source lane before runtime export
- safe-first free source pool from `Docs/ASSET_PIPELINE.md`

Blocked:
- unclear external packs
- `SourceArt/Archive/` as a default active source lane
- unmanifested runtime assets

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- targeted map/asset tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- asset smoke proves sockets can carry provisional dressing or exact blocker is explicit
- asset provenance is truthful and validator-clean
- structure remains honestly assessed without asset proof
- Prompt 17 cleanup can start without treating smoke assets as final

## Copy/Paste Parts

### Part A - Asset Smoke Audit

Apply only Prompt 16 Part A.

Scope:
- audit Prompt 14 sockets and Prompt 15 structural gate for the smallest safe asset-smoke target

Do not:
- add or edit assets in Part A

Validation:
- `py -3 Tools/validate_assets.py`
- architecture guard
- targeted map tests

Report:
- findings first
- exact socket classes ready for smoke
- exact socket classes blocked
- exact minimal asset families proposed
- exact provenance plan
- exact files to change in Part B

### Part B - Minimal Candidate Dressing Patch

Apply only Prompt 16 Part B.

Scope:
- add or wire only the smallest candidate/placeholder dressing needed to test ready sockets

Do not:
- add production art
- use candidate art to mask structure
- change gameplay truth, save shape, flow state, or source-of-truth ownership
- import a broad asset pack

Validation:
- full Prompt 16 validation stack

Report:
- files changed
- manifest rows added or changed
- exact sockets exercised
- before/after screenshot paths
- exact structural claims still not proven by assets

### Part C - Asset Smoke Recheck

Apply only Prompt 16 Part C.

Scope:
- recheck asset-on smoke against asset provenance, sockets, and structural honesty

Do not:
- call assets final or release-safe

Validation:
- full Prompt 16 validation stack

Report:
- findings first
- whether Prompt 17 cleanup can start
- exact smoke assets that must remain placeholder/candidate
- exact asset or socket blockers left
