# Prompt 03 - Extraction and Next Wave

Use this prompt pack only after `02_guarded_cleanup.md` is green.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`

## Goal

Execute the extraction wave in a controlled order, then carry the remaining map-specific next steps without widening scope.

## Current Baseline

- `Game/RuntimeState/map_runtime_state.gd`: `2395` lines
- `Game/UI/map_board_composer_v2.gd`: `1247` lines
- `Game/UI/map_route_binding.gd`: `1079` lines
- `Game/Application/run_session_coordinator.gd`: `1016` lines
- typed-reflection cleanup is already landed on the map/support/router/core low-risk slices; extraction must not reintroduce string-based owner calls that are already guard-locked.
- frozen full-layout filtering is already live on the current map board slice:
  - graph-stable `world_positions`, `layout_edges`, and `forest_shapes` now stay cached together
  - `visible_nodes` / `visible_edges` filter from the frozen layout instead of regenerating edge geometry from the visible subset
  - initial footprint widening is already landed; follow-up work must tune it, not undo it

## Order

### 0. Measurement And Doc Sync Preflight

- Re-measure the touched hotspot files before claiming a new extraction baseline.
- Keep `Docs/HANDOFF.md`, `Docs/ROADMAP.md`, and `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` aligned to the real post-patch numbers.
- Do not update validator caps until the new baseline is real and documented.

### 1. `MapRuntimeState` Extraction

- Keep extraction owner-preserving.
- `MapRuntimeState` remains the single caller-facing owner.
- No save payload change.
- Save roundtrip must stay field-for-field identical.
- Pending-node, key/boss-gate, reset lifecycle, and save-codec logic are not first-pass extraction targets.

### 2. Big-File Extraction Chain

Run these in order, one family at a time:

1. `Game/UI/map_board_composer_v2.gd`
2. `Game/Application/inventory_actions.gd`
3. `Game/Application/run_session_coordinator.gd`
4. `Game/UI/map_route_binding.gd`

Rules:
- start each family with a preflight/report section inside the same pass
- keep helper ownership narrow and local
- do not run multiple hotspot extractions in the same patch
- update validator caps only after the new baseline is real
- delete dead helper residue when extraction makes it provably unused
- keep live compat or restore-sensitive paths unless the patch explicitly audits and validates their removal

### 3. Map Next Wave

After the extraction chain is stable:

1. re-check reconnect tuning against the frozen-layout baseline
2. re-check placement / footprint widening
3. audit visibility-driven recomposition regressions
4. extend frozen full-layout filtering only if the audit proves a remaining gap
5. wire approved map assets into runtime hooks
6. run variation and residue cleanup

Rules:
- do not generate new path geometry from the currently visible subset
- keep full-layout stability when the graph signature is unchanged
- treat `SourceArt/Generated/new` as a candidate/reference pack, not as an authority doc set

## Asset Blocker Rule

The asset-hook step is blocked until approved runtime filenames and truthful manifest rows exist.
If approved filenames are missing, stop at that step and report the exact filenames/families still needed.
Do not generate assets in this prompt pack.
Approved prototype candidates may come from `SourceArt/Generated/new`, but those files stay reference-only until runtime filenames and manifest rows are explicit.

## Guardrails

- No save-schema shape change without an explicit escalate-first stop.
- No owner move to a new autoload.
- No new command family or event family.
- No redesign hidden inside extraction.
- No asset-generation work inside this prompt pack.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted map/runtime/save tests for each extraction slice
- save roundtrip tests whenever persisted owner code is touched
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `py -3 Tools/validate_assets.py` when the asset-hook step runs

## Done Criteria

- Hotspot owners drop below their current caps with visible headroom.
- Validator caps and active measurement docs are updated to the new baselines.
- Save roundtrip remains stable where required.
- Map next-wave items are either completed or explicitly blocked on approved asset filenames, with no regression back to visibility-driven path regeneration.
- The repo is ready to move into playtest/telemetry, then balance, then the asset wave.
