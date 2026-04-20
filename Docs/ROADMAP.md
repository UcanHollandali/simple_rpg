# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-20.

This is the single active roadmap and queue index for the repo.
It is a planning file, not an authority doc.
Gameplay and technical rules still live where `Docs/DOC_PRECEDENCE.md` says they live.

## Measured Current State

- Current stage: `Phase A - Stabilization / Cleanup Closeout`.
- Prompt readiness:
  - ready now: `Docs/Promts/01_foundation_fastlane.md` as a short closeout-only sanity pass
  - blocked on Prompt 01 exit: `Docs/Promts/02_guarded_cleanup.md`
  - blocked on Prompt 02 exit: `Docs/Promts/03_extraction_and_next_wave.md`
- Locked continuation decisions:
  - canonical pending-node owner: `MapRuntimeState`
  - live `NodeResolve` generic fallback stays until an explicit flow audit approves removal
  - existing `/root/AppBootstrap` usage may shrink only when owner meaning and live flow behavior stay unchanged
- Repo state: prototype-playable per `Docs/HANDOFF.md`.
- Measured open facts on the current workspace:
  - `Docs/COMMAND_EVENT_CATALOG.md` now registers `turn_phase_resolved` and `BossPhaseChanged`; that catalog drift is closed.
  - active markdown internal links resolve, and the live entry docs no longer describe the whole `Docs/` tree as one flat authority surface.
  - `scenes/` contains `0` direct `AppBootstrap.` member callsites, but several scenes still resolve `/root/AppBootstrap`; public-surface growth and new lookup spread are validator-locked, but narrowing the existing dependency surface still belongs to guarded cleanup.
  - retired stage-1 boss ballast is closed on the live repo surface; only the roadmap, the foundation prompt, and archive/history docs should still mention `gate_warden`.
  - typed-owner reflection regressions are now validator-locked for `map_explore_presenter.gd`, `map_route_binding.gd`, `support_interaction_presenter.gd`, `support_interaction.gd`, `scene_router.gd`, and `combat_resolver.gd`.
  - `NodeResolve` still has live generic-fallback and legacy-compatible pending-node restore routes; behavior-changing removal is not fast-lane work.
  - pending-node continuity still spans `RunSessionCoordinator` save orchestration and `MapRuntimeState` owner-side load/consume behavior; any owner move there is escalate-first.
- Hotspot measurements:
  - `Game/RuntimeState/map_runtime_state.gd`: `2395` lines
  - `Game/UI/map_board_composer_v2.gd`: `1257` lines
  - `scenes/combat.gd`: `1184` lines
  - `scenes/map_explore.gd`: `1000` lines
  - `Game/Application/inventory_actions.gd`: `1087` lines
  - `Game/UI/map_route_binding.gd`: `1093` lines
  - `Game/RuntimeState/inventory_state.gd`: `1060` lines
  - `Game/Application/run_session_coordinator.gd`: `1016` lines
  - `Game/RuntimeState/support_interaction_state.gd`: `976` lines
  - `Game/Application/combat_flow.gd`: `764` lines
- Measured map-pass status:
  - already landed: display-name helper, presenter wiring, topology refactor, composer path-family differentiation
  - still open: reconnect tuning follow-up, placement tuning follow-up, asset hook wiring, variation cleanup

## Already Applied

- The repo already has a live `MapDisplayNameHelper` and the map-facing presenter family is using it.
- The topology refactor already landed through `map_runtime_graph_codec.gd`.
- `map_board_composer_v2.gd` already exposes path-family differentiation.
- `SceneRouter` already has overlay-open / overlay-close dictionaries; the remaining work is contract hardening, not greenfield implementation.
- The prompt-local duplicate of `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` has already been removed from the active working set.
- A dedicated scene-side `AppBootstrap.` member-call grep cleanup pass is no longer needed unless new direct member callsites appear later.
- `COMMAND_EVENT_CATALOG.md` now includes the live `turn_phase_resolved` signal and `BossPhaseChanged` event.
- The stale `GameFlowManager.transition_to` and `SaveService.is_supported_save_state_now` wrappers are already removed.
- The shared inventory display-name helper and shared texture-loader cleanup already landed in the active UI presenters/canvas helpers.
- `gate_warden` is retired from the live repo surface; the stage-1 boss art identity is now carried directly by `tollhouse_captain`.
- `AppBootstrap` public-surface growth and new `/root/AppBootstrap` lookup spread are now validator-locked.
- The retired stage-1 boss surface is now validator-locked outside the roadmap, the foundation prompt, and `Docs/Archive/`.
- Active markdown link resolution and mixed-authority wording are now cleaned up in the live entry docs.
- Typed-owner reflection cleanup already landed on the low-risk map/support/router/core slices; the remaining work is broader guarded cleanup, not more opportunistic reflection pruning.

## Retired

- The 2026-04-18 audit set is no longer part of the active working set; it is historical material and belongs under `Docs/Archive/`.
- Separate queue mirrors and prompt indexes are retired in favor of the three active prompt packs under `Docs/Promts/`.
- Separate long-horizon and legacy roadmap files are retired in favor of this file.
- Historical audit-artifact recovery is no longer an active task; the live roadmap is self-contained and does not depend on archived review material.
- A standalone "`AppBootstrap.` member-call grep cleanup" prompt is retired from the active queue because the repo measures clean on that narrower grep; broader bootstrap-surface hardening still belongs to guarded cleanup if it is taken on later.

## Active Queue

1. [01_foundation_fastlane.md](Promts/01_foundation_fastlane.md)
   - Goal: run a short doc/guard sanity pass, then move immediately to Prompt 02 if no real fast-lane drift remains.
   - Exit: the active docs agree on current measurements and escalation items, or Prompt 01 explicitly reports that the workspace is already green and advances.
2. [02_guarded_cleanup.md](Promts/02_guarded_cleanup.md)
   - Goal: clear the remaining flow/application/scene drift without changing save shape, pending-node ownership, or gameplay authority boundaries.
   - Exit: guarded cleanup is green with targeted tests, scene isolation, and full suite.
3. [03_extraction_and_next_wave.md](Promts/03_extraction_and_next_wave.md)
   - Goal: execute the extraction wave, then carry the map-specific next steps in order.
   - Exit: hotspot owners have visible headroom, extraction docs/caps are updated, and the map wave is either completed or explicitly blocked on approved asset filenames.

## Continuation Launch Order

- Fresh chat read order:
  - `AGENTS.md`
  - `Docs/DOC_PRECEDENCE.md`
  - `Docs/HANDOFF.md`
  - `Docs/ROADMAP.md`
  - `Docs/Promts/01_foundation_fastlane.md`
- Execution order:
  - Prompt 01
  - Prompt 02 only after Prompt 01 closes green
  - Prompt 03 only after Prompt 02 closes green
- Prompt 01 is intentionally a short sanity pass.
  - If it comes up clean, close it quickly and continue instead of inventing extra work.

## Later Phases

### Phase D - Playtest and Telemetry

- Build a repeatable manual/headless playtest lane after the guarded and extraction passes are green.
- Capture enough run evidence to compare map feel, combat friction, and reward pacing over multiple runs.

### Phase E - Balance and Content Tuning

- Use the playtest lane to tune content and numbers without changing rule ownership.
- Focus on enemy pressure, reward cadence, economy pressure, and run consistency.

### Phase F - Asset Wave

- Bring approved visual/audio assets into the runtime with manifest-tracked provenance.
- Finish map asset hook wiring and variation cleanup after the extraction work is stable.

### Phase G - Expansion

- Open a new prompt pack for broader feature/content work only after Phases A-F are green.
- Do not widen into new systems while hotspot owners are still at cap.
