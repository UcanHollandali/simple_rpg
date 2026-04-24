# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-24 (prompt wave archived; next lane is broader cleanup)

This is the active short-horizon roadmap for the repo.
It is a planning file, not an authority doc.
Authority still lives where `Docs/DOC_PRECEDENCE.md` says it lives.

## Measured Current State

- The repo is prototype-playable per `Docs/HANDOFF.md`.
- There is no active prompt-wave queue.
- The closed map `Prompt 01-18` wave is archived under `Docs/Archive/Prompts/2026-04-24-map-wave-01-18-closed/`.
  - It is historical execution evidence only.
  - It is not active queue truth.
  - It must not be used as a fallback authority when active docs answer the question.
- Closed map/UI audit and checklist snapshots are archived under `Docs/Archive/Audits/2026-04-24-closed-reference-audits/`.
  - They are not part of the default working set.
  - They do not route future agents by default.
- The stale map-runtime extraction planning snapshot is archived under `Docs/Archive/Plans/2026-04-24-stale-reference-plans/`.
  - Future extraction work should remeasure current code before planning.
- The archived `43-62` wave remains superseded history under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`.
- The current fixed-board map replacement is closed as prototype structural/presentation evidence, not final art or release-ready visual proof.
- Exactly one default map presentation lane remains:
  - `render_model.path_surfaces`
  - `render_model.junctions`
  - `render_model.clearing_surfaces`
- Non-default map lanes are labeled:
  - `visible_edges` and `layout_edges`: fallback data
  - `ground_shapes`, `filler_shapes`, and `forest_shapes`: wrapper metadata for masks/socket derivation only
  - old draw-only trail/decal/node-plate candidate lane: retired
  - old canopy/filler/ground wrapper asset hook: retired
  - socket-smoke placeholder assets: provisional placeholder evidence only
- The visual wrapper blob/stamp lane is retired from the default board read.
  - `MapBoardCanvas` no longer draws atmosphere circles/arcs or wrapper `ground_shapes`, `filler_shapes`, and `forest_shapes` as visible board layers.
  - `ui_map_board_backdrop.svg` no longer carries non-routing oval/blob atmosphere marks in front of the board field.
- Candidate art is not the default next step.
  - Existing socket-smoke placeholder assets are not structural proof.
  - Open production-art or asset-candidate work only after broader cleanup preserves one unambiguous default presentation lane.
- Archived old prompt `14-20` remains historically closed as the older guarded fixed-board map-overhaul wave.
- Archived old prompt `21-36` remains historically closed as the combat/content reset and first executable combat slice.

## Next Lane - Broader Cleanup

Goal:
- prepare the repo for the next implementation lane by removing stale routing, obsolete docs, stale references, and retired map-presentation leftovers that no longer need to stay active
- preserve the single default map presentation lane
- keep archived prompt/audit/stale-plan material out of default agent routing

In scope:
- doc routing cleanup after prompt archival
- stale prompt/doc/reference scans
- dead-code or stale-test cleanup only when evidence-backed and boundary-safe
- stale asset/manifest references only when provenance and live runtime use are clear
- cleanup of obsolete wrapper/fallback labels if code evidence proves they are no longer needed

Out of scope by default:
- save-schema or save-version changes
- flow-state additions
- pending-node ownership moves
- gameplay truth moving into UI
- production art claims
- using candidate art as structural proof
- restoring archived prompt packs as active queue truth

Minimum validation for docs-only cleanup:
- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- stale prompt/doc/reference scan
- `git diff --check`

Add these when map presentation code, scenes, assets, or tests change:
- targeted map tests for the touched slice
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1` before claiming broad cleanliness

## Archived Summary

- `Prompt 01-18`: closed map-system wave archived under `Docs/Archive/Prompts/2026-04-24-map-wave-01-18-closed/`
- closed map/UI audit and checklist snapshots: archived under `Docs/Archive/Audits/2026-04-24-closed-reference-audits/`
- stale map-runtime extraction planning snapshot: archived under `Docs/Archive/Plans/2026-04-24-stale-reference-plans/`
- `Prompt 43-62`: superseded mid-wave history archived under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`
- old `Prompt 14-20`: historical fixed-board map-overhaul wave
- old `Prompt 21-36`: historical combat/content reset wave
- old `Prompt 06-36`: broader closed-green prompt history archived under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`

## After Broader Cleanup

- If cleanup leaves one unambiguous default presentation lane, choose the next lane explicitly from:
  - production art
  - asset candidate
  - additional map structural cleanup
  - broader balance/content work
- Do not open a new prompt queue until `ROADMAP.md` names it directly.
- Do not infer the next lane from archived prompt packs, archived audit snapshots, or archived stale plans.
