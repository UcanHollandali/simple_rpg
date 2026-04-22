# Prompt 03 - Extraction and Next Wave

Use this prompt pack only after the archived foundation and guarded closeout packs are green on the current workspace.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`

## Goal

Execute the extraction wave in a controlled order, then carry the remaining map-specific next steps without widening scope.

## Part Execution Rule

- When driving this prompt manually in chat, run it one part at a time.
- Do not advance to the next part until the current part is either:
  - green with validation, or
  - explicitly blocked with `escalate first`
- Do not combine multiple hotspot extraction families into one large patch.

## Current Baseline

- `Game/RuntimeState/map_runtime_state.gd`: `2279` lines
- `Game/UI/map_board_composer_v2.gd`: `954` lines
- `Game/UI/map_route_binding.gd`: `931` lines
- `Game/Application/inventory_actions.gd`: `230` lines
- `Game/Application/run_session_coordinator.gd`: `751` lines
- typed-reflection cleanup is already landed on the map/support/router/core low-risk slices; extraction must not reintroduce string-based owner calls that are already guard-locked.
- frozen full-layout filtering is already live on the current map board slice:
  - graph-stable `world_positions`, `layout_edges`, and `forest_shapes` now stay cached together
  - `visible_nodes` / `visible_edges` filter from the frozen layout instead of regenerating edge geometry from the visible subset
  - initial footprint widening is already landed; follow-up work must tune it, not undo it
- current Part F follow-up is already landed on top of that baseline:
  - late-route scatter now biases lower-board usage more than the earlier upper / lateral clustering pass
  - visible-cluster focus now clamps to padded board bounds so visible roads and clearings do not clip out during progression-only drift
- final visual signoff is still manual before the asset-hook step:
  - reconnect feel and widened-footprint comfort still need portrait playtest confirmation

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
- treat lower-board underuse, over-lateral node clustering, and disappearing route segments as active regressions until they are explicitly disproven by playtest and tests
- treat `SourceArt/Generated/new` as a candidate/reference pack, not as an authority doc set

## Asset Blocker Rule

The asset-hook step is blocked until approved runtime filenames and truthful manifest rows exist.
The asset-hook step is also blocked until the frozen-layout baseline is visually stable in live progression:
- stage-start full layout must stay stable while discovery only changes visibility
- lower-board underuse / over-lateral clustering must be reduced to an acceptable level
- disappearing or clipped route segments must be fixed or explicitly disproven
If approved filenames are missing, stop at that step and report the exact filenames/families still needed.
If layout stability is still failing, stop at that step and report the remaining map-behavior regressions before any asset adoption work.
Do not generate assets in this prompt pack.
Approved prototype candidates may come from `SourceArt/Generated/new`, but those files stay reference-only until runtime filenames and manifest rows are explicit.
Even after Part F is green, manual portrait playtest remains the final visual signoff lane before runtime asset hookup.

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

## Copy/Paste Parts

### Part A - Measurement + `MapRuntimeState` Extraction

```text
Apply only Prompt 03 Part A.

Scope:
- Re-measure the touched hotspot files.
- Sync HANDOFF / ROADMAP / MAP_RUNTIME_STATE_EXTRACTION_PLAN if numbers drift.
- Run only the first owner-preserving extraction pass for `MapRuntimeState`.
- Keep the current live map-behavior regressions explicit during preflight:
  - lower-board underuse / over-lateral clustering
  - disappearing or clipped route segments
- Do not start asset-hook work in this part.

Do not:
- change save payload shape
- change owner meaning
- touch pending-node, key/boss-gate, reset lifecycle, or save-codec logic as first-pass extraction targets

Validation:
- validate_architecture_guards
- targeted map/save/runtime tests
- save roundtrip tests
- full suite before closing the part
```

### Part B - `map_board_composer_v2.gd` Extraction

```text
Apply only Prompt 03 Part B.

Scope:
- Run only the `Game/UI/map_board_composer_v2.gd` extraction family.
- Keep helper ownership narrow and local.
- Preserve the frozen-layout baseline.

Do not:
- regenerate visible-path geometry from the visible subset
- move ownership out of the current UI/composer layer
- update validator caps until the new baseline is real

Validation:
- validate_architecture_guards
- targeted map composer / map canvas tests
- map scene isolation
- full suite before closing the part
```

### Part C - `inventory_actions.gd` Extraction

```text
Apply only Prompt 03 Part C.

Scope:
- Run only the `Game/Application/inventory_actions.gd` extraction family.
- Keep ownership unchanged.
- Delete only provably dead helper residue created by the extraction.

Do not:
- widen save/runtime ownership
- hide redesign inside extraction

Validation:
- validate_architecture_guards
- targeted inventory tests
- full suite before closing the part
```

### Part D - `run_session_coordinator.gd` Extraction

```text
Apply only Prompt 03 Part D.

Scope:
- Run only the `Game/Application/run_session_coordinator.gd` extraction family.
- Keep owner behavior intact.

Do not:
- touch pending-node owner meaning
- alter save/restore assumptions
- change key/boss-gate orchestration semantics unless explicitly escalated

Validation:
- validate_architecture_guards
- targeted flow/save/runtime tests
- save roundtrip tests
- full suite before closing the part
```

### Part E - `map_route_binding.gd` Extraction

```text
Apply only Prompt 03 Part E.

Scope:
- Run only the `Game/UI/map_route_binding.gd` extraction family.
- Keep the frozen-layout and widened-footprint behavior intact.

Do not:
- reintroduce string-based owner calls
- widen AppBootstrap lookup spread
- regress route stability across progression

Validation:
- validate_architecture_guards
- targeted map presenter / route binding / map canvas tests
- map scene isolation
- full suite before closing the part
```

### Part F - Map Next Wave Behavior Follow-Up

```text
Apply only Prompt 03 Part F.

Scope:
- Re-check reconnect tuning against the frozen-layout baseline.
- Re-check placement / footprint widening.
- Audit visibility-driven recomposition regressions.
- Extend frozen full-layout filtering only if the audit proves a remaining gap.
- Push node scatter to use more of the available board height instead of compressing the live layout into mostly upper / lateral lanes.
- Treat disappearing or clipped route segments in live progression states as regressions to fix, not as acceptable layout variance.

Do not:
- generate new path geometry from the currently visible subset
- change save shape or owner meaning

Validation:
- validate_architecture_guards
- targeted map composer / route / presenter tests
- map scene isolation
- full suite before closing the part
```

### Part G - Asset Hook Wiring + Variation Cleanup

```text
Apply only Prompt 03 Part G.

Scope:
- Wire approved map assets into runtime hooks.
- Run variation and residue cleanup.
- Treat `SourceArt/Generated/new` as a candidate/reference pack only.
- Treat all currently generated map assets as unapproved unless explicit runtime approval is already documented.

Blocker rule:
- If approved runtime filenames or truthful manifest rows are missing, stop and report the exact missing families/files.
- If the full-layout / discovery baseline is still unstable in playtest or tests, stop and report the remaining layout regressions first.
- Do not auto-approve any `SourceArt/Generated/new` file as a live runtime asset.
- At the blocker, report the exact runtime-facing asset families and filenames still needed for Map Composer V2, grouped as:
  1. already wired in `UiAssetPaths` / current runtime hooks
  2. required by active docs but not wired yet
  3. optional later polish
  4. unsafe or not currently usable without renderer/code changes
- For each expected asset path, report whether the current live/runtime expectation is `.svg` or `.png`.

Do not:
- wire any existing generated asset into runtime during this pass unless it is already explicitly approved
- move any generated asset from `SourceArt/` into `Assets/`
- create, edit, rename, convert, approve, or import art assets in this pass
- infer approval from file presence
- add manifest rows for experimental generated assets
- update `UiAssetPaths` to point at unapproved generated files
- generate assets in this part
- treat SourceArt docs as authority
- rename `.png` source files to `.svg`

If any generated map assets are already present under runtime-facing folders such as `Assets/UI/Map/`, report them as suspicious/unapproved before using them.

The correct outcome for this part is allowed to be:
"Asset hook blocked until approved runtime filenames and truthful manifest rows are provided."

Validation:
- validate_architecture_guards
- validate_assets
- targeted map tests
- map scene isolation
- full suite before closing the part
```
