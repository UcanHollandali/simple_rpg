# SIMPLE RPG - Handoff

Last updated: 2026-04-25 (hunger/exploration UX pilot landed; next lane is live-socket production asset brief)

This file is a current-state snapshot only.
It is not a rule contract. If it conflicts with an authority doc, the authority doc wins.
Use `Docs/ROADMAP.md` for next-lane planning and `Docs/DOC_PRECEDENCE.md` for authority routing.

## Current State

- The repo is prototype-playable across `MapExplore`, `Combat`, and the non-combat overlay family.
- The fixed-board replacement lane remains the working map reference in code, but it is prototype structural/presentation evidence, not final art or production-readiness proof.
- The closed map prompt wave `Prompt 01-18` is archived under `Docs/Archive/Prompts/2026-04-24-map-wave-01-18-closed/`.
  - It is historical execution evidence only.
  - It is not the active queue and must not be used as a fallback authority.
  - Its future-lane stub is archived with the rest of the pack.
- Closed reference audits/checklists that were no longer useful as active root docs are archived under `Docs/Archive/Audits/2026-04-24-closed-reference-audits/`.
  - They are historical snapshots only.
  - Active authority routing now stays in `Docs/DOC_PRECEDENCE.md`.
- The stale map-runtime extraction planning snapshot is archived under `Docs/Archive/Plans/2026-04-24-stale-reference-plans/`.
  - Future extraction work should remeasure current code instead of using that snapshot as an active plan.
- Retired map art scope/requirements/brief/audit references are archived under `Docs/Archive/Plans/2026-04-24-retired-map-art-reference/`.
  - They are historical reference only.
  - Future asset work should start from current authority docs, manifest state, and live socket metadata instead of those closed drafts.
- The earlier superseded map wave `43-62` remains archived under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/` as historical evidence only.
- The current map presentation truth after the closed wave:
  - exactly one default lane remains: `render_model.path_surfaces` + `render_model.junctions` + `render_model.clearing_surfaces`
  - `visible_edges` and `layout_edges` remain fallback data
  - `ground_shapes`, `filler_shapes`, and `forest_shapes` remain wrapper metadata for masks/socket derivation only
  - the old trail/decal/node-plate asset lane is retired
  - the old canopy/filler/ground wrapper asset hook is retired
  - socket-smoke placeholder assets remain provisional and must not be treated as final art
- The visual wrapper blob/stamp lane is retired from the default board read:
  - `MapBoardCanvas` no longer draws atmosphere circles/arcs or `ground_shapes`, `filler_shapes`, and `forest_shapes` as default visible layers
  - `ui_map_board_backdrop.svg` no longer carries non-routing oval/blob atmosphere marks in front of the board field
  - landmark pocket underlays and procedural landmark identity silhouettes are hidden from normal/default board render and are available only through explicit prototype/debug canvas flags
- The first production-art pilot is socket-driven and provisional:
  - runtime candidate assets live under `Assets/UI/Map/ArtPilot/`
  - source masters live under `SourceArt/Edited/Map/ArtPilot/`
  - manifest rows are `candidate` with `replace_before_release=yes`
  - `MapBoardCanvas` can consume the pilot path brush, boss landmark, key landmark, rest landmark, merchant landmark, and decor stamp from `render_model` socket metadata only when explicit prototype socket dressing is enabled
  - path brush and decor stamp are v2 selected candidates under the same runtime asset ids
  - source-only production-art candidates and superseded v1 path/decor masters were removed after selected candidates were promoted into manifest-backed source masters and runtime exports
  - candidate art and unsupported-family socket-smoke placeholder art do not draw during normal/default board render
  - socket-smoke placeholder drawing is available only through an explicit debug/prototype canvas flag
  - these assets prove socket carry only; they do not prove final art, route truth, pocket quality, terrain quality, or hunger pressure
- The latest visual cleanup pass added a render-model-derived road/pocket throat blend layer:
  - it is UI presentation only
  - it uses connected path/clearing surface metadata
  - it does not change route, discovery, movement, hunger, save, or flow truth
- The hunger/exploration UX pilot is now applied as a UI-only readability pass:
  - the visible map HUD foregrounds next-move hunger cost, route count, prep/support detour state, and key/boss commitment
  - all reads are derived from `RunState`, `MapRuntimeState`, and the existing `RunSessionCoordinator.MAP_MOVE_HUNGER_COST`
  - route, discovery, hunger, current-node, pending-node, key, and boss truth remain in their existing owners
  - no save shape, flow state, source-of-truth ownership, asset provenance, or default asset lane changed
- Current map-direction truth remains ahead of the old scatter lane:
  - runtime topology backbone exists
  - slot/anchor placement exists
  - corridor/road hierarchy exists
  - terrain/filler masking exists as metadata
  - map-adjacent UI alignment exists
  - route-shape hunger pressure has positive test coverage for `shortest_vs_alternative_route_delta >= 2` on representative staged seeds
- Runtime ownership remains stable:
  - `MapRuntimeState` remains graph, current-node, discovery, adjacency, key/boss, and pending-node owner
  - `RunSessionCoordinator` remains movement and pending-screen orchestration owner
  - `Game/UI` may own derived presentation only
  - `AppBootstrap` remains a facade over flow/run/save coordination
- GitHub Actions `Validate` is active on `main`; check the latest Actions run before claiming remote cleanliness for a new commit.
- The previous post-wave `Validate` failure was limited to stale seeded map portrait baselines after the wrapper/blob visual lane was retired.
  - The seeded map baselines under `Tests/VisualBaselines/portrait_review/` were refreshed to the closed `render_model` surface lane.
  - The refreshed checkpoint passed GitHub Actions `Validate` on `main`.
- Optional GDQuest `gdscript-formatter` `0.19.0` is installed outside the repo at `C:\Tools\gdscript-formatter\gdscript-formatter.exe`.
  - repo helper: `Tools/run_gdscript_static_check.ps1`
  - use it as an opt-in changed-file linter/format-check helper; broad formatting remains a separate explicit cleanup pass
- Portrait image-diff regression harness is available through `Tools/run_portrait_image_diff.ps1`.
  - checked-in baselines live under `Tests/VisualBaselines/portrait_review/`
  - current captures and diff artifacts stay under ignored `export/`
  - use `-CleanOldArtifacts` or `Tools/clean_portrait_artifacts.ps1` to prune stale portrait captures/diffs; `export/windows_playtest` is only removed with explicit `-IncludeWindowsPlaytest`
- `Tools/run_portrait_review_capture.ps1` captures the standard map seed set `11`, `29`, `41` plus `73` and `97` at mid/late advance depths for review evidence.
- The combat/content waves remain historically closed green:
  - archived old prompt packs stay under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`
  - no new combat/content prompt wave is open on this snapshot

## Last Verified Validation Checkpoint

- Latest confirmed GitHub Actions `Validate` on `main`: green after the seeded map portrait baseline refresh for the closed `render_model` surface lane.
  - Check the current run again for any newer commit under review.
- Final local closeout for the map wave passed:
  - `py -3 Tools/validate_assets.py`
  - `py -3 Tools/validate_architecture_guards.py` with existing hotspot warnings only
  - targeted map tests through `Tools/run_godot_tests.ps1`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - stale prompt/doc/reference scan for retired map lanes
  - `git diff --check`
- Docs archival cleanup passed:
  - `py -3 Tools/validate_assets.py`
  - `py -3 Tools/validate_architecture_guards.py` with existing hotspot warnings only
  - active prompt-execution stale scan outside `Docs/Archive/`
  - active archived-audit/plan filename reference scan outside `Docs/Archive/`
  - `git diff --check`
- Production art pilot local checks passed:
  - `py -3 Tools/validate_assets.py`
  - `py -3 Tools/validate_architecture_guards.py` with existing hotspot warnings only
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_canvas.gd`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_image_diff.ps1 -Capture -CleanOldArtifacts -TimeoutSeconds 180`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - `git diff --check`
- Visual cleanup / art-candidate extension local checks passed:
  - `py -3 Tools/validate_assets.py`
  - `py -3 Tools/validate_architecture_guards.py` with existing hotspot warnings only
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_canvas.gd`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_image_diff.ps1 -Capture -CleanOldArtifacts -TimeoutSeconds 180`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - `git diff --check`
- Hunger/exploration UX pilot local checks passed:
  - `py -3 Tools/validate_assets.py`
  - `py -3 Tools/validate_architecture_guards.py` with existing hotspot warnings only
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_explore_presenter.gd,test_map_board_canvas.gd`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120 -CleanOldArtifacts`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_image_diff.ps1 -Capture -CleanOldArtifacts -TimeoutSeconds 180`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - `git diff --check`
- Portrait image diff passed after refreshing the seeded map baselines for the closed `render_model` surface lane.
- `Tools/run_ai_check.ps1` was not rerun during final closeout; do not cite it as current evidence without rerunning.

## Open Risks

- Test green and full-suite green do not substitute for visual honesty on the map lane.
- Candidate/prototype art remains non-proof, including the current art-pilot map assets.
- Socket-smoke placeholders remain provisional and must not be treated as final art.
- Socket-smoke placeholders remain manifest-tracked but hidden from normal/default board render.
- Art-pilot assets remain provisional, hidden from normal/default board render, and must not be treated as final art or release-safe art.
- Wrapper/orchestrator/fallback map data surfaces still exist and must not silently become gameplay owners.
- Manual portrait playtest and screenshot review are required for map readability, overlay feel, and landmark/route read.
- `NodeResolve` remains live legacy flow code; do not behavior-change or remove it without a dedicated flow audit.
- Pending-node continuity still crosses save orchestration in `RunSessionCoordinator` and runtime ownership in `MapRuntimeState`; do not move that boundary without explicit save audit.
- The closed map wave and seeded baseline refresh are committed and pushed; still inspect `git status --short` before starting new edits and do not revert unrelated changes.

## Next Step

1. Build a new production asset brief from current live socket metadata.
2. Include path brush, boss/key/rest/merchant landmarks, combat/event/reward/blacksmith/hamlet gaps, and canopy/filler/decor family sizing.
3. Keep candidate art hidden from normal/default board render until a separate manifest/provenance, screenshot-review, and pixel-diff promotion decision.
4. Do not use archived map art briefs or old audits as active authority for new production art.

## Locked Decisions

- Canonical pending-node owner: `MapRuntimeState`.
- `app_state.pending_node_id` / `app_state.pending_node_type` remain compatibility mirrors for save/restore orchestration; they are not a second owner.
- The current fixed-board replacement lane remains the working map reference in code; archived prompt packs do not revert implementation.
- No save-shape, flow-state, or source-of-truth ownership change is implied by the prompt-wave archive.
- Candidate art remains provisional and non-proof unless a later production-art lane explicitly replaces it with release-safe assets.
- Archived prompt packs, archived audits, and archived stale plans do not become a second authority surface.
