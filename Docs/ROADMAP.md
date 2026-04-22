# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-22 (post-wave architecture hardening audit refreshed hotspot measurements and validator locks; `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md` still reflects landed `MapBoardGroundBuilder` / `MapBoardFillerBuilder` ownership, the UI overhaul wave remains closed through Prompt 13, and the next broader phase remains `Phase D - Playtest and Telemetry`).

This is the single active roadmap and queue index for the repo.
It is a planning file, not an authority doc.
Gameplay and technical rules still live where `Docs/DOC_PRECEDENCE.md` says they live.

## Measured Current State

- Current stage: `UI overhaul / map visual ownership wave closed; next broader phase is Phase D - Playtest and Telemetry`.
- Prompt readiness:
  - archived closed green: `Docs/Archive/Prompts/2026-04-21-phase-a-closed/01_foundation_fastlane.md`
  - archived closed green: `Docs/Archive/Prompts/2026-04-21-phase-a-closed/02_guarded_cleanup.md`
  - archived: `Docs/Archive/Prompts/2026-04-21-phase-a-closed/03_extraction_and_next_wave.md` (`Part A-F` closed green; `Part G` superseded by Prompt 04 code-first direction, asset-hook step stays deferred and is not reopened)
  - archived measured closeout: `Docs/Archive/Prompts/2026-04-22-map-lane-closed/04_map_renderer_code_first.md` (`Part A-E` closed green on the current workspace; the code-first direction, renderer polish, semantic icon-wave scope plan, and safe no-stamp verification lane are all in place)
  - archived measured closeout: `Docs/Archive/Prompts/2026-04-22-map-lane-closed/05_map_layout_regression_fix.md` (`Part A-F` closed green on the current workspace; lower-board underuse, over-lateral clustering, clipped/disappearing route segments, and fragmented visible cluster are cleared on the final portrait lane while frozen-layout stability holds)
- Locked continuation decisions:
  - canonical pending-node owner: `MapRuntimeState`
  - live `NodeResolve` generic fallback stays until an explicit flow audit approves removal
  - existing `/root/AppBootstrap` usage may shrink only when owner meaning and live flow behavior stay unchanged
- Repo state: prototype-playable per `Docs/HANDOFF.md`.
- Git continuity note: keep the active prompt wave on `main`; do not create or switch workflow branches unless the user explicitly asks for branch work.
- Measured open facts on the current workspace:
  - `Docs/COMMAND_EVENT_CATALOG.md` now registers `turn_phase_resolved` and `BossPhaseChanged`; that catalog drift is closed.
  - active markdown internal links resolve, and the live entry docs no longer describe the whole `Docs/` tree as one flat authority surface.
  - `scenes/` contains `0` direct `AppBootstrap.` member callsites, but several scenes still resolve `/root/AppBootstrap`; public-surface growth and new lookup spread are validator-locked, but narrowing the existing dependency surface still belongs to guarded cleanup.
  - retired stage-1 boss ballast is closed on the live repo surface; only the roadmap, the foundation prompt, and archive/history docs should still mention `gate_warden`.
  - typed-owner reflection regressions are now validator-locked for `map_explore_presenter.gd`, `map_route_binding.gd`, `support_interaction_presenter.gd`, `support_interaction.gd`, `scene_router.gd`, and `combat_resolver.gd`.
  - architecture-guard hotspot locks now also cover the current shared UI owner hotspots `temp_screen_theme.gd`, `map_explore_scene_ui.gd`, `combat_scene_ui.gd`, `map_board_style.gd`, and `map_board_canvas.gd`; further growth on those files is no longer invisible to the default guard lane.
  - `NodeResolve` still has live generic-fallback and legacy-compatible pending-node restore routes; behavior-changing removal is not fast-lane work.
  - pending-node continuity still spans `RunSessionCoordinator` save orchestration and `MapRuntimeState` owner-side load/consume behavior; any owner move there is escalate-first.
- Hotspot measurements:
  - `Game/RuntimeState/map_runtime_state.gd`: `2279` lines
  - `Game/UI/map_board_composer_v2.gd`: `984` lines
  - `scenes/combat.gd`: `1199` lines
  - `scenes/map_explore.gd`: `1156` lines
  - `Game/Application/inventory_actions.gd`: `280` lines
  - `Game/UI/map_route_binding.gd`: `979` lines
  - `Game/RuntimeState/inventory_state.gd`: `1060` lines
  - `Game/Application/run_session_coordinator.gd`: `768` lines
  - `Game/RuntimeState/support_interaction_state.gd`: `976` lines
  - `Game/Application/combat_flow.gd`: `764` lines
  - shared UI owner hotspots:
    - `Game/UI/temp_screen_theme.gd`: `971` lines
    - `Game/UI/map_explore_scene_ui.gd`: `818` lines
    - `Game/UI/map_board_style.gd`: `693` lines
    - `Game/UI/map_board_canvas.gd`: `590` lines
    - `Game/UI/combat_scene_ui.gd`: `532` lines
- Measured map-pass status:
  - already landed: display-name helper, presenter wiring, topology refactor, composer path-family differentiation, graph-stable frozen full-layout filtering, board-footprint widening, lower-board scatter follow-up, padded-frame route-stability clamp, continuity restoration, procedural renderer polish, semantic icon-wave scope planning, and fresh no-stamp verification
  - measured closed green: the final Prompt 05 lane clears lower-board underuse, over-lateral clustering, clipped/disappearing route segments, and fragmented visible cluster while stage-start layout signatures stay stable across progression states
  - measured closed green: the fresh Prompt 04 no-stamp lane proves the random generated map remains acceptable with zero generated terrain stamps
  - deferred by direction: terrain asset hook wiring remains blocked; map asset-facing continuation stays in the Prompt 04 semantic icon / prop / item / portrait lane rather than terrain-transition art

## Already Applied

- The repo already has a live `MapDisplayNameHelper` and the map-facing presenter family is using it.
- The topology refactor already landed through `map_runtime_graph_codec.gd`.
- The first owner-preserving `MapRuntimeState` extraction pass now routes pure scatter adjacency/depth/path/connectivity helpers through `map_scatter_graph_tools.gd` while keeping save payload and owner meaning unchanged.
- The first `MapBoardComposerV2` extraction pass now routes layout placement/collision/crossing helpers through `map_board_layout_solver.gd` while keeping `MapBoardComposerV2` as the caller-facing derived-layout owner and preserving the frozen full-layout baseline.
- The first `InventoryActions` extraction pass now routes item mutation helpers through `inventory_item_mutation_helper.gd` while keeping `InventoryActions` as the caller-facing mutation surface and leaving save/runtime ownership unchanged.
- The first `RunSessionCoordinator` extraction pass now routes state/setup utility blocks through `run_session_state_helper.gd` while keeping pending-node/save orchestration and caller-facing owner behavior unchanged.
- The first `MapRouteBinding` extraction pass now routes local emergency-layout and route-motion math through `map_route_layout_helper.gd` and `map_route_motion_helper.gd` while keeping `MapRouteBinding` as the caller-facing board/route binding owner and preserving the frozen-layout baseline.
- `map_board_composer_v2.gd` already exposes path-family differentiation.
- `SceneRouter` and `MapExplore` overlay entry points now route through the shared state-driven overlay contract surface; remaining work is broader guarded cleanup and extraction, not overlay greenfield implementation.
- The shared `InventoryPanelLayout` owner now centralizes inventory-panel density, panel-height, flow-separation, shared child paths, and hint-line caps across the map/combat scene UI slices.
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
- Separate queue mirrors and prompt indexes are retired in favor of the roadmap plus the remaining active prompt pack under `Docs/Promts/`.
- Separate long-horizon and legacy roadmap files are retired in favor of this file.
- Historical audit-artifact recovery is no longer an active task; the live roadmap is self-contained and does not depend on archived review material.
- A standalone "`AppBootstrap.` member-call grep cleanup" prompt is retired from the active queue because the repo measures clean on that narrower grep; broader bootstrap-surface hardening still belongs to guarded cleanup if it is taken on later.

## Active Queue

1. [01_foundation_fastlane.md](Archive/Prompts/2026-04-21-phase-a-closed/01_foundation_fastlane.md)
   - Status: closed green, archived.
   - Result: authority docs and guard wording were aligned without changing owner meaning, save shape, or flow behavior.
2. [02_guarded_cleanup.md](Archive/Prompts/2026-04-21-phase-a-closed/02_guarded_cleanup.md)
   - Status: closed green, archived.
   - Result: `NodeResolve` contract, pending-node boundary isolation, bootstrap/scene shell cleanup, shared inventory-panel layout, and overlay contract hardening all landed without changing save shape or authority boundaries.
3. [03_extraction_and_next_wave.md](Archive/Prompts/2026-04-21-phase-a-closed/03_extraction_and_next_wave.md)
   - Status: archived.
   - Result: `Part A-F` closed green; the extraction wave landed across `MapRuntimeState`, `map_board_composer_v2`, `inventory_actions`, `run_session_coordinator`, and `map_route_binding` without changing save shape or owner meaning.
   - `Part G` (asset-hook wiring) is superseded by Prompt 04 code-first direction and is not part of the active queue. The asset-hook step remains deferred behind the `ASSET_PIPELINE.md` approval + manifest row contract.
4. [04_map_renderer_code_first.md](Archive/Prompts/2026-04-22-map-lane-closed/04_map_renderer_code_first.md)
   - Status: closed green, archived; `Part A-E` complete on the current workspace.
   - Goal: formalize the code-first renderer direction, polish procedural map presentation so the board reads acceptably with zero generated terrain stamps, and produce a written semantic icon wave scope plan for future AI asset work.
   - Measured outcome: code-first direction is documented, `map_board_canvas.gd` and `map_board_style.gd` were polished, `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md` now exists as a reference-only production companion, and the fresh no-stamp verification lane under `export/portrait_review/prompt04_no_stamp_after_20260422_074912/` passes the acceptance checklist.
5. [05_map_layout_regression_fix.md](Archive/Prompts/2026-04-22-map-lane-closed/05_map_layout_regression_fix.md)
   - Status: closed green, archived; `Part A-F` complete on the current workspace.
   - Goal: fix or explicitly disprove the live map layout regressions (lower-board underuse, over-lateral clustering, clipped/disappearing route segments, fragmented visible cluster) inside the composer / route binding lane while keeping the frozen full-layout baseline intact.
   - Measured outcome: the final lane under `export/portrait_review/prompt05_followup_after_20260422_074840/` clears lower-board underuse, over-lateral clustering, clipped/disappearing route segments, and fragmented visible cluster while preserving the frozen-layout baseline.
6. [06_ui_information_architecture_audit.md](Promts/06_ui_information_architecture_audit.md)
   - Status: closed green on the current workspace.
   - Goal: produce `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` as a reference-only audit of map / event / combat / inventory decision visibility plus a concrete next-step queue for Prompts 06.5-12.5.
   - Result: `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` now exists as the finalized reference-only audit covering screen-dominant-task analysis, a global state visibility matrix, top decision/readability problems, and a repo-truth-grounded Prompt 06.5-12.5 plan.
   - Constraint: docs-only pass; existing-truth rule applies; no gameplay logic, save schema, or asset hookup change.
   - Exit: complete; the audit doc exists, is reference-only, and the recommended Prompt 06.5 / Prompt 07 scope is grounded in repo truth.
7. [06_5_microcopy_audit.md](Promts/06_5_microcopy_audit.md) (`Prompt 06.5`)
   - Status: closed green on the current workspace.
   - Goal: produce `Docs/UI_MICROCOPY_AUDIT.md` as a reference-only audit of every player-facing text surface (tooltips, disabled reasons, button labels, empty / error / one-shot strings) and assign rewrite hand-offs without changing live code.
   - Result: `Docs/UI_MICROCOPY_AUDIT.md` now exists as the finalized reference-only audit and makes the rewrite ownership explicit: Prompts 07-09 handle screen-specific hierarchy copy touchpoints only where needed, Prompt 10 handles readability guardrails only, and Prompt 11.5 is the main empty / loading / error / failure-state rewrite lane.
   - Constraint: docs-only; no code change in this pack.
8. [07_inventory_equipment_drawer.md](Promts/07_inventory_equipment_drawer.md)
   - Status: closed green on the current workspace.
   - Goal: make inventory / equipment presentation context-sensitive (collapsed drawer on map, compact consumable-first surface in combat) so the dominant task on each screen is no longer drowned by an always-open backpack/equipment surface; touch copy only where the new hierarchy needs it.
   - Owner surfaces: `Game/UI/run_inventory_panel.gd`, `Game/UI/map_explore_scene_ui.gd`, `Game/UI/combat_scene_ui.gd`.
   - Result: map now defaults to a collapsed inventory/equipment drawer with contextual expand (`expand first` before interaction), and combat now presents a compact locked-equipment summary plus a consumable-first backpack surface while preserving the shared `RunInventoryPanel` owner family.
9. [08_event_modal_choice_cards.md](Promts/08_event_modal_choice_cards.md)
   - Status: closed green on the current workspace.
   - Goal: improve event-modal hierarchy and choice-card readability (cost / reward / disabled reason) using existing truth only; touch copy only where the new hierarchy needs it.
   - Result: the event modal now groups tag / title / summary more clearly, renders explicit choice-card shells with CTA footers tied to each card, and surfaces existing-truth cost / reward / availability reads when present without changing event logic or overlay contracts.
10. [09_combat_hierarchy.md](Promts/09_combat_hierarchy.md)
    - Status: closed green on the current workspace.
    - Goal: improve enemy intent / player state / primary action area hierarchy and reduce combat-log dominance using existing truth only; touch copy only where the new hierarchy needs it.
    - Result: combat now emphasizes the enemy intent card, makes the player status strip faster to scan, strengthens attack/defend card hierarchy, renames the consumable lane to `Quick Use`, and keeps the combat log expanded but visually secondary by default without adding combat prediction logic.
11. [10_font_icon_readability_guardrails.md](Promts/10_font_icon_readability_guardrails.md)
    - Status: closed green on the current workspace.
    - Goal: add minimum font / icon / touch-target / contrast readability guardrails only on portrait targets without starting a full theme/token cleanup or a semantic icon replacement wave.
    - Result: shared presentation helpers now clamp minimum readable font sizes, icon sizes, touch targets, disabled text contrast, and gameplay-value emphasis so portrait targets stay readable without changing gameplay rules or starting the full token/theme cleanup pass.
12. [10_5_first_run_hints.md](Promts/10_5_first_run_hints.md)
    - Status: closed green on the current workspace.
    - Goal: add a small save-aware `FirstRunHintController` that fires the frozen 8-hint set once per save (defend, dual-purpose left-hand, hamlet personality, roadside encounter, key-required route, belt capacity, low hunger).
    - Result: the frozen 8-hint set is fully wired across combat / map / support / event contexts, `app_state.shown_first_run_hints` now persists shown hints across runs on the same save, older saves default cleanly to `[]`, and hints never block input.
    - Constraint: this remained the wave's only additive-optional save-field pack; no tutorial mode, no rotating tips system, and no content-version bump landed.
13. [11_ui_theme_token_cleanup.md](Promts/11_ui_theme_token_cleanup.md)
    - Status: closed green on the current workspace.
    - Goal: centralize shared UI color / spacing / typography / component-state tokens after the hierarchy and readability wins land, behavior-preserving only.
    - Result: shared UI token values now live more centrally inside existing shared owners, stale local constant duplication was reduced, and screenshot regression review kept the Prompt 07-10 hierarchy/readability gains intact.
14. [11_5_empty_error_states.md](Promts/11_5_empty_error_states.md) (`Prompt 11.5`)
    - Status: closed green on the current workspace.
    - Goal: act as the main empty-state, loading/transition-state, and error/failure-state rewrite lane from `Docs/UI_MICROCOPY_AUDIT.md` so blank surfaces and failure paths feel intentional and consistent.
    - Result: empty backpack / quick-use / blocked-choice surfaces now read more intentionally, transition/boot copy is clearer, and known unavailable-action / missing-choice / missing-state failures now use more player-facing wording without changing failure semantics, retry behavior, flow, or save shape.
    - Deferred `NEEDS_FUTURE_LOGIC_SUPPORT`: no dedicated player-facing loading string exists yet; authored event choices still need modeled disabled reasons for precise unavailable text; richer combat blocker explanations still need stable runtime reason codes beyond current HP / hunger truth.
    - Constraint: presentation-only; no failure semantics or save change.
15. [12_semantic_icon_readiness.md](Promts/12_semantic_icon_readiness.md) (`Prompt 12`)
    - Status: closed green on the current workspace.
    - Goal: produce `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md` as a reference-only runtime-readiness / asset-contract / hookup-prep checkpoint for the semantic icon wave; does not unblock asset hookup by itself.
16. [12_5_accessibility_mobile_audit.md](Promts/12_5_accessibility_mobile_audit.md)
    - Status: closed green on the current workspace.
    - Goal: produce `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md` covering color contrast, color-only signaling, text scaling, motion/flash safety, focus visibility, portrait safe-area, plus mobile interaction conflicts (tap vs swipe vs drag, accidental-tap zones, touch target overlap), and emit a prioritized narrow follow-up queue.
    - Constraint: docs-only; no code change in this pack.
17. [13_map_visual_world_ownership.md](Promts/13_map_visual_world_ownership.md)
    - Status: closed green on the current workspace.
    - Goal: establish ownership and contract surfaces for the two map visual-world layers that currently have no owner in the `MapBoardComposerV2` chain: a board ground/surface owner and a filler/landmark owner. Both must derive placement from the existing seeded map state, must never become routing truth, and must ship procedural fallbacks so the pack can close without approved new art.
    - Output: the checked-in `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md` was refreshed to match repo truth, and the two new owners (`MapBoardGroundBuilder`, `MapBoardFillerBuilder`) now live inside the existing composer chain with procedural fallbacks only.
    - Constraint/result: no asset generation, no asset approval, no `UiAssetPaths` repoint, no change to `MapRuntimeState` truth or path routing logic, no new RNG stream, no save/schema/flow change; semantic icon identity remains scoped to Prompt 04 Part D + Prompt 12.

## Continuation Launch Order

- Fresh chat read order:
  - `AGENTS.md`
  - `Docs/DOC_PRECEDENCE.md`
  - `Docs/HANDOFF.md`
  - `Docs/ROADMAP.md`
  - then the closest authority docs for the chosen `Phase D - Playtest and Telemetry` task
  - if map-visual continuity is relevant, also read `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`
  - if a candidate accessibility/mobile follow-up is explicitly chosen, also read `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md`
- Git continuity note:
  - stay on `main` unless the user explicitly asks for branch work
- Closed on the current workspace:
  - Prompt 04 / Prompt 05 map lane
  - Prompt 06 through Prompt 12.5 UI overhaul wave
  - Prompt 13 map visual world ownership pack
- Prompt 13 closeout result:
  - `MapBoardGroundBuilder` and `MapBoardFillerBuilder` now live inside the existing `MapBoardComposerV2` chain
  - both owners derive from the existing seeded map state and remain non-routing
  - `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md` records the landed owner contracts
  - no asset was generated, approved, or hooked
- Candidate-only follow-ups:
  - the narrow owner-scoped items in `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md` remain optional and inactive by default
- Broader roadmap movement:
  - the next broader phase remains `Phase D - Playtest and Telemetry`
- Prompt 01, Prompt 02, and Prompt 03 stay archived on the current workspace
  - do not reopen them unless a new measured drift appears later

## Later Phases

### Phase D - Playtest and Telemetry

- Build a repeatable manual/headless playtest lane after the guarded and extraction passes are green.
- Capture enough run evidence to compare map feel, combat friction, and reward pacing over multiple runs.

### Phase E - Balance and Content Tuning

- Use the playtest lane to tune content and numbers without changing rule ownership.
- Focus on enemy pressure, reward cadence, economy pressure, and run consistency.

### Phase F - Asset Wave

- Bring approved visual/audio assets into the runtime with manifest-tracked provenance.
- Finish map asset hook wiring and variation cleanup only after the extraction work is stable, the Prompt 04/05 map baseline stays green in live playtests, and the asset approval/manifest gates are satisfied.
- Treat `SourceArt/Generated/new` as the current candidate prototype kit, not as an authority doc surface.

### Phase G - Expansion

- Open a new prompt pack for broader feature/content work only after Phases A-F are green.
- Do not widen into new systems while hotspot owners are still at cap.
