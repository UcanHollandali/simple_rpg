# Prompt 05 - Map Layout Regression Fix

Use this prompt pack only after Prompt 04 Part A is green.
Prompt 04 Part B-C landing first is preferred.
Do not run Prompt 05 in parallel with Prompt 04 inside the same chat or patch stream.
This pack addresses a separate concern from Prompt 04:
- Prompt 04 is presentation polish inside `map_board_canvas.gd` and `map_board_style.gd`.
- Prompt 05 is layout/placement behavior inside the composer/route lane.

Do not merge these two packs into one pass. Their scope boundaries are different and their risk lanes are different.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`

## Observed Live Regressions

Portrait playtest screenshots confirm that the regressions named in Prompt 03 Part F are still live:

1. Lower-board underuse. The node cluster concentrates in the upper two-thirds of the board frame. The lower third stays mostly empty across multiple progression states.
2. Over-lateral clustering. Nodes push to the right and left edges of the frame more than they occupy the vertical center. Late-route nodes sit near the right frame edge instead of spreading downward.
3. Disappearing / clipped route segments. Some nodes visibly sit at or past the padded frame boundary, with their edges partially cut off. Connecting polylines visually drop out near the frame edge rather than clamping into the visible content bounds.
4. Fragmenting readability. Visible route fragments can appear detached from the main current-route cluster, producing a board that reads as two disconnected islands in the lateral axis.

These are active regressions per the archived `Docs/Archive/Prompts/2026-04-21-phase-a-closed/03_extraction_and_next_wave.md` Part F guidance (historical reference only, do not edit) and per `Docs/HANDOFF.md` open-risk notes. They must be fixed or explicitly disproven on portrait screenshots, not accepted as acceptable layout variance.

## Why This Is A Separate Pack From Prompt 04

- Prompt 04 Part B only tunes `map_board_canvas.gd` and `map_board_style.gd`.
- The regressions above come from scatter placement, frozen full-layout geometry, footprint widening, and visible-cluster board follow behavior.
- Their owners are:
  - `Game/UI/map_board_composer_v2.gd` (derived-layout owner)
  - `Game/UI/map_board_layout_solver.gd` (layout placement / collision / crossing helper)
  - `Game/UI/map_route_binding.gd` (board/route binding owner)
  - `Game/UI/map_route_layout_helper.gd` (emergency-layout math)
  - `Game/UI/map_route_motion_helper.gd` (route-motion math)
- Some of these sit in medium-risk territory. Extraction and save/runtime ownership stay untouched; only derived-layout behavior changes.

## Direction Statement

- Keep graph truth, save schema, flow, owner meaning, and visibility-filtering semantics unchanged.
- Keep the frozen full-layout baseline (stage-start caches `world_positions`, `layout_edges`, `forest_shapes`; discovery only changes the visible subset).
- Within the frozen-layout model, expand the effective vertical footprint use and reduce lateral over-clustering, so the realized `14`-node graph fills the portrait route frame with less upper/lateral bias and less lower-board emptiness.
- Ensure that no visible node is placed outside the padded board bounds and no connecting polyline visibly drops out near the frame edge.

## Part Execution Rule

- Run one part at a time.
- Do not advance to the next part until the current part is green with validation, or explicitly blocked with `escalate first`.
- Do not combine layout/placement and binding/clamp changes into one patch.

## Asset Blocker Rule

- No generated asset is approved, moved, renamed, converted, imported, or hooked in this pack.
- No `UiAssetPaths` constant is added or repointed.
- This pack does not unblock Prompt 03 Part G. The asset-hook step stays deferred per Prompt 04.

## Guardrails

- No save-schema shape change.
- No save payload contract change for `MapRuntimeState` or the realized graph codec.
- No owner move.
- No flow state change.
- No new command family or event family.
- No scene/core boundary change.
- No graph-truth change. The stage guarantee floor, node family set, adjacency rules, controlled-scatter role placement, and key/boss viability from `Docs/MAP_CONTRACT.md` remain intact.
- No visibility-filtering semantic change. `visible_nodes` and `visible_edges` must continue to filter from the frozen full layout, not regenerate from the visible subset.
- No interaction / movement semantic change.
- No edit to `Game/RuntimeState/map_runtime_state.gd`, `Game/RuntimeState/map_runtime_graph_codec.gd`, `Game/RuntimeState/map_scatter_graph_tools.gd`, `Game/Application/run_session_coordinator.gd`, or any `scenes/*.gd` file for gameplay/runtime ownership reasons. Presentation reads of runtime snapshots remain allowed.
- No string-based owner call reintroduction on typed-reflection-locked files.
- No `AppBootstrap` public-surface widening.
- No widening of `/root/AppBootstrap` lookup spread.

## Order

### 0. Preflight + Measurement

- Confirm Prompt 04 state:
  - Part A green is required
  - Part B-C already landed is preferred but not required
- Re-measure the hotspot files that Prompt 05 may touch:
  - `Game/UI/map_board_composer_v2.gd`
  - `Game/UI/map_board_layout_solver.gd`
  - `Game/UI/map_route_binding.gd`
  - `Game/UI/map_route_layout_helper.gd`
  - `Game/UI/map_route_motion_helper.gd`
- Capture baseline portrait screenshots of `scenes/map_explore.tscn` at stage start, mid-progression, and late progression before making any change.
- Catalogue each observed regression instance per screenshot (lower-board underuse, over-lateral clustering, clipped segment, fragmented cluster).

### 1. Scatter / Placement Vertical Spread

- Target: the realized `14`-node graph uses more of the available vertical frame height while keeping the bounded compact portrait envelope.
- Surface: scatter placement inside `map_board_composer_v2.gd` and `map_board_layout_solver.gd`.
- Keep controlled-scatter role placement stable. The event, hamlet, reward, support, key, and boss role slots must continue to resolve per `MAP_CONTRACT.md`.
- Increase downward bias for late-route positions, but not by re-introducing layered horizontal rings or by compressing the opening cluster into a single upper band.
- Do not change the graph signature / adjacency truth. Re-tune spread factors / noise / jitter only within the existing placement model.

### 2. Lateral Clamp And Padded Frame Enforcement

- Target: no visible node is placed at or past the padded board bounds. Connecting polylines do not drop out near the frame edge.
- Surface: `map_route_binding.gd` and `map_route_layout_helper.gd`.
- Keep the visible-cluster focus clamp intact. Tighten it so that emergency-layout math does not push nodes past the padded frame.
- If a node is clipping out, prefer shrinking the effective inner layout bounds instead of cropping the frame.
- Do not rewrite the emergency-layout fallback; only clamp its output into the padded frame.

### 3. Route Continuity Fix

- Target: visible route polylines stay continuous from the current-route cluster to outer reachable nodes. No fragmented islands caused by visibility filtering artifacts.
- Surface: `map_board_composer_v2.gd` and `map_route_binding.gd`.
- Confirm that visible edges are filtered from frozen `layout_edges` and that no visible edge is dropped because one endpoint was pushed out-of-frame by Part 1 or Part 2.
- If visible-edge dropout still occurs, adjust clamp boundaries upstream; do not regenerate geometry from the visible subset.

### 4. Visual Review + Playtest

- Re-capture portrait screenshots at stage start, mid-progression, and late progression.
- Compare against the baseline captures from Part 0.
- Pass/fail per regression:
  1. lower-board use: increased vs baseline
  2. over-lateral clustering: reduced vs baseline
  3. clipped segments: zero visible clipped nodes or edges
  4. fragmented cluster: single visually connected current-route cluster
  5. frozen-layout stability: stage-start layout stays stable while discovery only changes visibility
- If any checkpoint fails, open a narrow follow-up patch inside the same part's file scope. Do not widen into runtime, save, or flow.

### 5. Closeout

- Update `Docs/HANDOFF.md` and `Docs/ROADMAP.md` to reflect that the three open layout regressions named under Prompt 03 Part F open-risks are either fixed (with portrait screenshots cited in the handoff) or explicitly disproven.
- Do not edit the archived `Docs/Archive/Prompts/2026-04-21-phase-a-closed/03_extraction_and_next_wave.md`; it is historical reference only. If its Part F wording would overclaim relative to the new state, capture the corrected wording inside `Docs/HANDOFF.md` open risks instead. Do not reopen Part G from this pack.
- If any regression remains, record it as the new explicit open risk in `Docs/HANDOFF.md` with screenshots and the remaining follow-up scope.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted: `Tests/test_map_board_composer_v2.gd`, `Tests/test_map_explore_presenter.gd`, `Tests/test_map_board_canvas.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- portrait capture via `Tools/scene_portrait_capture.gd` before/after each applied part.

## Done Criteria

- Portrait screenshots demonstrate that lower-board underuse, over-lateral clustering, and clipped/disappearing route segments are visibly reduced or eliminated on `14`-node stage graphs.
- Frozen-layout baseline is unchanged: stage-start full layout stays stable, discovery only widens the visible subset, and visibility changes do not regenerate path geometry.
- Save roundtrip stays field-for-field identical.
- The full suite and targeted map tests remain green.
- `Docs/HANDOFF.md` reflects the real post-patch state, including any regressions that remain as open risks.

## Copy/Paste Parts

### Part A - Measurement And Baseline Capture

```text
Apply only Prompt 05 Part A.

Scope:
- Measure the Prompt 05 hotspot files:
  - Game/UI/map_board_composer_v2.gd
  - Game/UI/map_board_layout_solver.gd
  - Game/UI/map_route_binding.gd
  - Game/UI/map_route_layout_helper.gd
  - Game/UI/map_route_motion_helper.gd
- Capture baseline portrait screenshots via Tools/scene_portrait_capture.gd (or the repo's standard capture lane) for scenes/map_explore.tscn at:
  - stage start
  - mid-progression (several resolved nodes)
  - late progression (key and boss visible)
- Catalogue each observed regression per screenshot:
  - lower-board underuse
  - over-lateral clustering
  - clipped / out-of-frame nodes
  - visibly dropped edges
  - fragmented / disconnected visible cluster

Do not:
- change any code in this part
- approve, move, rename, convert, import, or hook any asset
- reopen Prompt 03 Part G
- edit authority docs

Validation:
- validate_architecture_guards (sanity baseline)
- full suite (sanity baseline)

Report:
- current line counts per hotspot file
- screenshot file paths
- a short regression catalogue per screenshot with which of the four regression types are visible and where
```

### Part B - Scatter / Placement Vertical Spread

```text
Apply only Prompt 05 Part B.

Scope:
- File scope limited to Game/UI/map_board_composer_v2.gd and Game/UI/map_board_layout_solver.gd.
- Goal: the realized 14-node graph uses more of the available vertical frame height while keeping the bounded compact portrait envelope intact.
- Tune scatter spread / noise / jitter / downward bias so:
  - the opening cluster does not compress into a narrow upper band
  - late-route positions bias downward instead of pushing further right/left
  - lateral extremes no longer dominate the frame
- Preserve the controlled-scatter role placement from MAP_CONTRACT.md: start reveals an early combat, early reward, and early support route; one dedicated event role; one dedicated hamlet role; key/boss on the same late route line or flank; no immediate adjacent boss click after key.
- Preserve the frozen full-layout baseline: stage-start caches world_positions, layout_edges, forest_shapes; discovery only changes the visible subset.

Do not:
- regenerate path geometry from the visible subset
- change the graph signature, adjacency truth, node family set, or stage guarantee floor
- touch MapRuntimeState, map_runtime_graph_codec.gd, map_scatter_graph_tools.gd, or any runtime/save/flow owner
- edit UiAssetPaths, MapBoardCanvas, MapBoardStyle, MapRouteBinding, or any scenes/*.gd file
- approve, move, rename, convert, import, or hook any asset
- widen AppBootstrap public surface or /root/AppBootstrap lookup spread
- reintroduce string-based owner calls on typed-reflection-locked files
- change save payload shape

Validation:
- validate_architecture_guards
- targeted: test_map_board_composer_v2.gd, test_map_explore_presenter.gd, test_map_board_canvas.gd stay green
- map scene isolation on scenes/map_explore.tscn
- full suite before closing the part
- portrait screenshot capture after the patch, compared against Part A baseline

Report:
- files changed with line counts before/after
- every named constant or tuning value adjusted, with before/after
- a short description of the scatter-model change and why it preserves the controlled-scatter role contract
- portrait screenshots at the three progression states
- pass/fail per regression category (lower-board underuse, over-lateral clustering, clipped segments, fragmented cluster) with 1-2 line reasoning each
- explicit confirmation that no runtime, save, flow, or asset hook was touched
```

### Part C - Lateral Clamp And Padded Frame Enforcement

```text
Apply only Prompt 05 Part C.

Scope:
- File scope limited to Game/UI/map_route_binding.gd and Game/UI/map_route_layout_helper.gd.
- Goal: no visible node sits at or past the padded board bounds; no connecting polyline visibly drops out near the frame edge.
- Tighten the visible-cluster focus clamp so emergency-layout math does not push nodes past the padded frame.
- If a node is clipping out, prefer shrinking effective inner layout bounds instead of cropping the visible frame.
- Preserve the widened-footprint and frozen-layout behavior.

Do not:
- rewrite the emergency-layout fallback semantics
- regenerate path geometry from the visible subset
- touch MapBoardComposerV2, map_board_layout_solver.gd, MapBoardCanvas, MapBoardStyle, MapRuntimeState, or any runtime/save/flow owner
- edit UiAssetPaths or any scenes/*.gd file
- approve, move, rename, convert, import, or hook any asset

Validation:
- validate_architecture_guards
- targeted: test_map_board_composer_v2.gd, test_map_explore_presenter.gd, test_map_board_canvas.gd stay green
- map scene isolation on scenes/map_explore.tscn
- full suite before closing the part
- portrait screenshot capture after the patch

Report:
- files changed with line counts before/after
- every clamp constant / tuning value adjusted, with before/after
- portrait screenshots comparing Part B output against Part C output
- explicit confirmation that clipped/out-of-frame nodes and dropped-edge fragments are resolved, or an explicit list of which remain
```

### Part D - Route Continuity Fix

```text
Apply only Prompt 05 Part D.

Scope:
- File scope limited to Game/UI/map_board_composer_v2.gd and Game/UI/map_route_binding.gd.
- Goal: visible route polylines stay continuous from the current-route cluster to outer reachable nodes; no fragmented visible islands caused by visibility filtering or clamp interactions.
- Confirm that visible edges are filtered from frozen layout_edges and that no visible edge is dropped because one endpoint was pushed out-of-frame by Part B or Part C.
- If visible-edge dropout still occurs, adjust clamp boundaries upstream in the same part. Do not regenerate geometry from the visible subset.

Do not:
- regenerate path geometry from the visible subset
- change the graph signature, adjacency truth, node family set, stage guarantee floor, or save payload shape
- touch MapRuntimeState, map_runtime_graph_codec.gd, map_scatter_graph_tools.gd, or any runtime/save/flow owner
- edit UiAssetPaths, MapBoardCanvas, MapBoardStyle, or any scenes/*.gd file
- approve, move, rename, convert, import, or hook any asset

Validation:
- validate_architecture_guards
- targeted: test_map_board_composer_v2.gd, test_map_explore_presenter.gd, test_map_board_canvas.gd stay green
- map scene isolation on scenes/map_explore.tscn
- full suite before closing the part
- portrait screenshot capture after the patch

Report:
- files changed with line counts before/after
- any tuning values adjusted, with before/after
- portrait screenshots showing current-route continuity
- explicit confirmation that visible fragments are resolved, or an explicit list of which remain
```

### Part E - Visual Review And Playtest Signoff

```text
Apply only Prompt 05 Part E.

Scope:
- Re-capture portrait screenshots via Tools/scene_portrait_capture.gd (or the repo's standard capture lane) for scenes/map_explore.tscn at stage start, mid-progression, and late progression.
- Compare against the Part A baseline captures.
- Score pass/fail per checkpoint:
  1. lower-board use increased vs baseline
  2. over-lateral clustering reduced vs baseline
  3. zero clipped nodes or edges
  4. single visually connected current-route cluster (no lateral islands)
  5. stage-start layout stays stable while discovery only changes visibility
- If any checkpoint fails, open a narrow follow-up patch strictly inside the same file scope as the relevant earlier part. Do not widen into runtime, save, flow, or asset work.

Do not:
- modify test baseline expectations to mask regressions
- approve, move, rename, convert, import, or hook any asset
- edit any file outside the Prompt 05 file scope

Validation:
- validate_architecture_guards if any code was touched
- targeted map tests if any code was touched
- map scene isolation
- full suite before closing the part

Report:
- list of captured files
- pass/fail per checkpoint with 1-2 line reasoning
- list of any follow-up tuning applied and before/after constants
- explicit confirmation that the frozen-layout baseline is unchanged
- explicit confirmation that scope did not leave the Prompt 05 file scope
```

### Part F - Closeout And Handoff Refresh

```text
Apply only Prompt 05 Part F.

Scope:
- Update Docs/HANDOFF.md to reflect:
  - which of the three open layout regressions (lower-board underuse, over-lateral clustering, disappearing/clipped segments) are now fixed
  - screenshot references for the fixes
  - any regression that remains as an explicit open risk, with scope for the next pass
- Update Docs/ROADMAP.md measured-state section to note that Prompt 05 landed (or the exact open part) and that the remaining map-wave items stay per Prompt 04 direction.
- Do not edit Docs/Archive/Prompts/2026-04-21-phase-a-closed/03_extraction_and_next_wave.md; it is historical reference only. If its Part F wording would overclaim relative to the new state, capture the corrected wording inside Docs/HANDOFF.md open risks instead. Do not reopen Prompt 03 Part G from this pack.
- Leave Docs/MAP_CONTRACT.md, Docs/ASSET_PIPELINE.md, Docs/ASSET_LICENSE_POLICY.md, and Docs/VISUAL_AUDIO_STYLE_GUIDE.md unchanged.

Do not:
- declare asset wave unblocked
- reopen Prompt 03 Part G
- edit authority docs listed above

Validation:
- verify all internal doc links resolve
- validate_architecture_guards
- full suite once to confirm no repo drift during doc updates

Report:
- files changed
- handoff state before/after for the relevant open-risk entries
- any follow-up work explicitly deferred to later phases
```

## Success Condition

- Portrait screenshots show the random `14`-node graph filling the portrait route frame without lower-board emptiness or lateral over-clustering.
- No visible node or connecting polyline drops out at the padded frame edge.
- The frozen full-layout baseline is preserved.
- Save shape, flow, owner meaning, graph truth, and visibility-filtering semantics are unchanged.
- Handoff and roadmap reflect the real post-patch state of the three named regressions.
