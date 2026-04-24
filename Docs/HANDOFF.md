# SIMPLE RPG - Handoff

Last updated: 2026-04-24 (Prompt 02 baseline complete as failure evidence; `Prompt 03` is next; GitHub `Validate` workflow is active; portrait export cleanup is wired into image-diff)

This file is a current-state snapshot only.
It is not a rule contract. If it conflicts with an authority doc, the authority doc wins.
Use `Docs/ROADMAP.md` for canonical queue/open-state and `Docs/DOC_PRECEDENCE.md` for authority routing.

## Current State

- The repo is prototype-playable across `MapExplore`, `Combat`, and the non-combat overlay family.
- The current fixed-board replacement lane remains the working map reference in code, but it is not final art/read truth.
- The old live prompt wave `43-62` is no longer the active continuation surface.
  - it is archived under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`
  - it remains useful as historical execution evidence only
  - its queue semantics and success claims are superseded
- The active map continuation wave is now `Docs/Promts/01-18`.
- `Prompt 01` has completed the current-truth reset and target lock at docs/process level only.
- `Prompt 02` has completed as a baseline failure-naming pass; it does not claim the current map visuals are structurally green.
- The earlier reset drafts were too compressed around render-model/canvas switching, adjacent UI read, asset smoke, and cleanup closeout; they have been replaced by the `01-18` wave.
- Candidate art is closed through this wave.
  - existing candidate assets from the previous lane may still be live, but they are not structural proof
  - `Prompt 14` checks socket readiness only
  - `Prompt 15` gates asset smoke and cleanup/hygiene
  - `Prompt 16` may run only provisional candidate/placeholder smoke if Prompt 15 allows it
  - any actual asset-candidate lane must be chosen later by `Prompt 18`
- Current map-direction truth remains ahead of the old scatter lane but still needs honest rework:
  - runtime topology backbone exists
  - slot/anchor placement attempts exist
  - corridor/road hierarchy attempts exist
  - terrain/filler masking exists
  - map-adjacent UI alignment exists
- GitHub Actions `Validate` is active on `main`; check the latest Actions run before claiming remote cleanliness for a new commit.
  - earlier tooling commit `79bb501` failed because `test_phase2_loop.gd` exposed missing map presentation helpers such as `build_forest_shapes`
  - the failure was addressed by `7e47fd7`, which keeps terrain/filler/forest masks derived from render-model path and clearing surfaces
  - later CI commits split validation steps and made environment diagnostics non-blocking so validator/Godot failures are easier to locate
- Optional GDQuest `gdscript-formatter` `0.19.0` is installed outside the repo at `../Tools/gdscript-formatter/gdscript-formatter.exe`.
  - repo helper: `Tools/run_gdscript_static_check.ps1`
  - use it as an opt-in changed-file linter/format-check helper; broad formatting remains a separate explicit cleanup pass
- Portrait image-diff regression harness is now available through `Tools/run_portrait_image_diff.ps1`.
  - checked-in baselines live under `Tests/VisualBaselines/portrait_review/`
  - current captures and diff artifacts stay under ignored `export/`
  - use `-CleanOldArtifacts` or `Tools/clean_portrait_artifacts.ps1` to prune stale portrait captures/diffs; `export/windows_playtest` is only removed with explicit `-IncludeWindowsPlaytest`
  - unseeded map captures are still for human review; seeded map captures are pixel-gated
- Current honesty watchpoints remain open until the new wave rechecks them:
  - baseline screenshot truth vs optimistic closeout wording
  - center-local start identity with varied north/south/east/west outward exploration feel
  - seed-to-seed route identity
  - hunger pressure through route shape
  - road surfaces vs stroke/decal roads
  - landmark pockets/places vs icon/plate nodes
  - dark blob/filler rescue
  - asset socket readiness without asset proof
- Runtime ownership remains stable:
  - `MapRuntimeState` remains graph, current-node, discovery, adjacency, key/boss, and pending-node owner
  - `RunSessionCoordinator` remains movement and pending-screen orchestration owner
  - `Game/UI` may own derived presentation only
  - `AppBootstrap` remains a facade over flow/run/save coordination
- The combat/content waves remain historically closed green:
  - archived old Prompt `06-36` packs stay archived under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`
  - no new combat/content prompt wave is open on this snapshot

## Last Verified Validation Checkpoint

- Latest GitHub Actions `Validate` on `main`: check the current run for the commit under review.
- Passed latest local portrait image diff: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_image_diff.ps1 -Capture -CleanOldArtifacts -TimeoutSeconds 180`.
- Passed latest local AI check: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_ai_check.ps1 -TimeoutSeconds 240`.
- Passed latest local map review check: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_ai_check.ps1 -MapReview -TimeoutSeconds 240`.
- Passed latest explicit full suite: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- Passed latest validators: `py -3 Tools/validate_content.py`, `py -3 Tools/validate_assets.py`, `py -3 Tools/validate_architecture_guards.py`
- Passed latest diff hygiene check: `git diff --check`

## Open Risks

- Test green and full-suite green do not substitute for structural honesty on the map lane.
- Archived `43-62` contains useful implementation history, but some closeout language was too optimistic.
- Candidate art must not reopen by inertia from archived `56` or currently visible candidate files.
- The current visual gap is system-first: sector grammar, anchors, corridors, path surfaces, walker feel, pockets, terrain masks, and sockets must be checked before art.
- Narrow wrapper/orchestrator/fallback map surfaces still exist and must not silently become gameplay owners.
- Manual portrait playtest and screenshot review are required for map readability, overlay feel, and landmark/route read.
- `NodeResolve` remains live legacy flow code; do not behavior-change or remove it without a dedicated flow audit.
- Pending-node continuity still crosses save orchestration in `RunSessionCoordinator` and runtime ownership in `MapRuntimeState`; do not move that boundary without explicit save audit.

## Next Step

1. Use `Docs/Promts/03_hidden_sector_grammar_contract_recheck.md` next.
2. Apply Prompt 03's Prompt 02 Correction Gate before Part A if the Prompt 02 report still says `lower-entry` or `upward exploration pressure`.
3. Run `Prompt 03-14` in order; do not skip straight to assets.
4. Use `Prompt 15` for the first honest integrated structural closeout and asset-smoke/cleanup gate.
5. Run `Prompt 16` only if Prompt 15 says provisional asset smoke is safe and useful.
6. Run `Prompt 17` only if Prompt 15 or Prompt 16 says cleanup is safe or required.
7. Use `Prompt 18` for final hygiene closeout and next-lane decision.
8. Treat archived `43-62` prompts as historical evidence only, not as the live queue.

## Locked Decisions

- Canonical pending-node owner: `MapRuntimeState`.
- `app_state.pending_node_id` / `app_state.pending_node_type` remain compatibility mirrors for save/restore orchestration; they are not a second owner.
- The current fixed-board replacement lane remains the working map reference in code; resetting prompt packs does not revert implementation.
- No save-shape, flow-state, or source-of-truth ownership change is implied by the prompt-wave reset.
- Candidate art remains provisional and non-proof even if a later prompt opens an asset lane.
- Archived prompt packs do not become a second authority surface.
