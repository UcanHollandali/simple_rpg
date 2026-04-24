# Prompt 62 - Map Post-Cleanup Final Hygiene And Closeout

Use this prompt only after Prompt 61 is closed green.
This pack is the final hygiene and closeout gate after the full map rebuild and cleanup wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/62_map_post_cleanup_final_hygiene_closeout.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- Prompt `43-61` outputs

Preflight:
- touched owner layer: `full wave final hygiene review`
- authority doc: `Docs/MAP_CONTRACT.md` plus the closest touched authority docs
- impact: `review first / runtime truth-save shape-asset provenance only if a last tiny corrective cleanup is clearly justified`
- minimum validation set: `validate_architecture_guards + touched tests + portrait verification + full suite checkpoint + git diff --check`

## Goal

Confirm that the rebuilt map system and its cleanup pass leave the repo in a truthful, low-drift, continuation-safe state.

## Required Review Order

- shipped map contract
- runtime topology and local adjacency truth
- placement and corridors
- walker and landmark pockets
- terrain/filler and candidate assets
- map-adjacent UI
- cleanup/decommission result
- docs truth
- remaining deferred debt

## Hard Guardrails

- No fake "clean" judgment if stale or conflicting map surfaces remain.
- No hidden late behavior changes inside hygiene work.
- Any remaining risky cleanup must stay explicitly deferred.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- touched validators and targeted tests
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- the final repo truth is clear
- the map wave is closed or explicitly left open for a named reason
- stale passive map code is either removed or honestly deferred
- future continuations do not inherit silent drift

## Copy/Paste Parts

### Part A - Final Hygiene Review

```text
Apply only Prompt 62 Part A.

Scope:
- Audit the full Prompt 43-61 chain after cleanup and judge whether the wave is truly continuation-safe.

Do not:
- patch code in Part A
- rename residual blockers as success

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
4. whether the wave is truly closeable
```

### Part B - Last Tiny Corrective Cleanup

```text
Apply only Prompt 62 Part B.

Scope:
- Land only the last tiny corrective cleanup justified by Part A.

Do not:
- open another broad refactor
- move authority boundaries silently

Validation:
- validate_architecture_guards
- touched tests
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact last blocker corrected
- exact blocker intentionally left open if still unresolved
```

### Part C - Final Handoff/Closeout Sync

```text
Apply only Prompt 62 Part C.

Scope:
- Sync final wave state after the Part A or Part B outcome.

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
