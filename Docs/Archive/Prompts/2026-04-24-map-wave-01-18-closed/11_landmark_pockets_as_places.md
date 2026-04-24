# Prompt 11 - Landmark Pockets As Places

Use this prompt after Prompt 10 closes walker traversal.
This pack makes nodes read as small places and pockets, not icon discs.

Checked-in filename note:
- this pack lives at `Docs/Promts/11_landmark_pockets_as_places.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md` (reference-only, especially Fixed-Board Visual System Rules 1-7)
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- Prompt 10 output
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_board_style.gd`
- `Game/UI/ui_asset_paths.gd`
- related map tests

Preflight:
- touched owner layer: `Game/UI derived landmark/pocket presentation + related Tests`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + targeted map tests + scene isolation + portrait capture + git diff --check`

## Goal

Make destinations read as places:
- center-local opening pocket and outward destination pockets read as parts of one small world
- combat, reward, rest, merchant, blacksmith, key, and boss each get distinct pocket/arrival grammar
- icons and plates become confirmation, not primary identity
- roads enter through pocket throats and do not cut through interaction clearings
- high-value nodes have stronger silhouettes before icon read

## Required Outcomes

- landmark pocket data is derived presentation data
- every discovered non-start destination owns one local pocket/clearing surface
- key and boss do not share the same immediate arrival read
- support-family pockets read differently from combat/reward pockets
- pocket silhouettes support north/south/east/west route identity instead of a generic icon grid
- icon-off mental review is included in the report
- pocket/place evidence is reported against Fixed-Board Visual System Rules 1-7 as a reference lens, not as authority
- no candidate assets are added

## Hard Guardrails

- no gameplay truth in UI
- no stable ID rename
- no save/flow/source-of-truth change
- no candidate art
- no hiding weak pockets behind larger icons

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map composer/canvas tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `git diff --check`

## Done Criteria

- node identities read as pockets/places before icons where practical
- remaining icon dependence is explicit
- asset sockets are not yet opened as proof

## Copy/Paste Parts

### Part A - Landmark Pocket Audit

Apply only Prompt 11 Part A.

Scope:
- audit landmark/pocket read, icon dependence, and arrival grammar

Do not:
- patch code in Part A

Validation:
- architecture guard
- targeted map tests
- capture review

Report:
- findings first
- exact families that still read as icons
- exact pocket/arrival grammar failures
- Fixed-Board Visual System Rules 1-7 pocket/place gaps
- exact files to change in Part B

### Part B - Landmark Pocket Patch

Apply only Prompt 11 Part B.

Scope:
- land only owner-preserving derived pocket/landmark presentation fixes

Do not:
- add assets or move gameplay truth into UI

Validation:
- full Prompt 11 validation stack

Report:
- files changed
- exact pocket grammar changed
- icon-off read evidence
- Fixed-Board Visual System Rules 1-7 gaps changed or still open
- remaining landmark blockers

### Part C - Landmark Recheck

Apply only Prompt 11 Part C.

Scope:
- recheck live and seeded landmark/pocket read across seeds `11`, `29`, `41`, plus at least two additional random seeds unless explicitly deferred with reason

Do not:
- call candidate art open

Validation:
- full Prompt 11 validation stack

Report:
- findings first
- whether Prompt 12 can start
- remaining place-read blockers
- remaining Fixed-Board Visual System Rules 1-7 pocket/place gaps
