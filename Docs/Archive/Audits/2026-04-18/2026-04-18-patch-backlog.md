# Patch Backlog — Audit Sentezi — 2026-04-18

Status: report-only  
Method: synthesis of A1-A6 audit outputs plus overlap check against `Docs/Promts/Archive/CODEX_POLISH_PROMPTS.md`  
Code changes: none  
Authority:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md` for current-state context only

## Executive Summary

Confirmed:
- `Docs/Audit/2026-04-18-maintainability-audit.md` is not present in the repo. The A6 findings below are reconstructed from the current-session maintainability scan notes, not from a checked-in audit artifact.
- `CODEX_POLISH_PROMPTS.md` already covers much of the 2026-04-18 cleanup plan, but several audit findings are either still open, only partially covered, or were converted into report-only planning work rather than implementation.

This backlog count is a synthesized patch list, not a 1:1 count of every source-audit sentence.

- Toplam backlog maddesi: 19
- Critical: 2 | Major: 12 | Minor: 5
- Quick Wins: 6 | Strategic: 6 | Escalate: 5 | Optional: 2
- `CODEX_POLISH_PROMPTS` ile çakışan veya kısmen örtüşen: 9
- Çakışmasız yeni iş: 10

## Source Coverage Note

- A1: `Docs/Audit/2026-04-18-runtimestate-audit.md`
- A2: `Docs/Audit/2026-04-18-application-audit.md`
- A3: `Docs/Audit/2026-04-18-scene-audit.md`
- A4: `Docs/Audit/2026-04-18-ui-audit.md`
- A5: `Docs/Audit/2026-04-18-architecture-audit.md`
- A6: checked-in report missing; session-derived maintainability findings are recorded here as `MAINT-F*`

## Raw Finding Register

Each row is one synthesized raw finding line as requested: source finding ID + summary + scope + raw recommendation.

| Source ID | Ham bulgu özeti | Kapsam | Ham öneri |
|---|---|---|---|
| META-1 | Maintainability audit artifact missing from repo | `Docs/Audit/2026-04-18-maintainability-audit.md` | recreate the missing report before treating A6 as durable audit truth |
| RS-F1 | `SAVE_SCHEMA` pending-node ownership drift | `Docs/SAVE_SCHEMA.md`, `Game/RuntimeState/map_runtime_state.gd`, `Game/Application/run_session_coordinator.gd` | doc-only correction unless owner move is explicitly approved |
| RS-F2 | `RunState` compatibility accessors mostly dead externally | `Game/RuntimeState/run_state.gd` | plan compatibility cleanup, do not fast-delete |
| RS-F3 | Hamlet / side-quest state shape duplicated across owners | `Game/RuntimeState/map_runtime_state.gd`, `Game/RuntimeState/support_interaction_state.gd` | owner split audit before any cleanup |
| RS-F4 | `InventoryState` cached getters return mutable cached arrays | `Game/RuntimeState/inventory_state.gd` | harden accessor semantics or document mutating-read caveat |
| RS-F5 | Several RuntimeState helpers are dead or test-only | `Game/RuntimeState/*` | prune dead helpers and privatize test-only surface where safe |
| APP-F1 | `NodeResolve` code contract broader than docs | `Game/Application/game_flow_manager.gd`, `Game/Application/run_session_coordinator.gd`, `scenes/map_explore.gd` | align docs or narrow fallback path |
| APP-F2 | `AppBootstrap` facade too broad and scenes depend on it directly | `Game/Application/app_bootstrap.gd`, `scenes/*` | narrow scene dependence before adding more facade methods |
| APP-F3 | Command/event catalog drift | `Game/Application/combat_flow.gd`, `Docs/COMMAND_EVENT_CATALOG.md` | update catalog for live surfaces |
| APP-F4 | Error recovery style inconsistent across Application | `Game/Application/*` | standardize invalid-state handling family-by-family |
| APP-F5 | Dead/test-only surfaces remain in Application | `Game/Application/game_flow_manager.gd`, `app_bootstrap.gd`, `combat_flow.gd`, `inventory_actions.gd`, `enemy_selection_policy.gd` | prune wrappers, demote internals, keep test surfaces explicit |
| APP-F6 | Save/load orchestration split is healthy; legacy loaders still live | `Game/Application/save_runtime_bridge.gd`, `Game/Infrastructure/save_service*.gd` | no urgent patch; keep under guard |
| SCN-F1 | No confirmed gameplay-truth leak in scenes | `scenes/*` | no action beyond guard maintenance |
| SCN-F2 | No confirmed display-text-as-logic in scenes | `scenes/*` | no action beyond guard maintenance |
| SCN-F3 | `_apply_portrait_safe_layout` and `_apply_temp_theme` still duplicated with drift across 11 scenes | `scenes/*` | finish extraction/consolidation pass |
| SCN-F4 | `combat.gd` still has per-card post-render traversal hotspot | `scenes/combat.gd` | move card child access behind shared panel/card handles |
| SCN-F5 | `map_explore.gd` has same per-card traversal hotspot | `scenes/map_explore.gd` | same shared panel/card-handle fix |
| SCN-F6 | Several scenes still use direct path lookups instead of caches | `scenes/main_menu.gd`, `run_end.gd`, `stage_transition.gd`, `main.gd`, `node_resolve.gd` | reduce fragile lookup density where hot or drift-prone |
| SCN-F7 | `node_resolve.gd` still runtime-reachable | `scenes/node_resolve.gd`, `Game/Infrastructure/scene_router.gd` | treat as live fallback until contract decision is made |
| SCN-F8 | Lifecycle style mostly good, but tween/signal cleanup is inconsistent | `scenes/main.gd`, `Game/UI/safe_menu_overlay.gd` | add explicit cleanup where low-risk |
| SCN-F9 | Resource path health is clean | `scenes/*.gd`, `scenes/*.tscn` | no patch needed |
| UI-F1 | Presenter/view boundary mostly clean | `Game/UI/*` | no patch needed beyond guard maintenance |
| UI-F2 | Inventory display-name helper duplicated | `Game/UI/event_presenter.gd`, `reward_presenter.gd` | extract narrow shared formatter/helper |
| UI-F3 | Texture loader helper logic duplicated | `Game/UI/inventory_card_factory.gd`, `map_board_canvas.gd`, `scene_layout_helper.gd` | consolidate around one loader policy |
| UI-F4 | Portrait layout policy fragmented across UI files | `Game/UI/combat_scene_ui.gd`, `map_explore_scene_ui.gd`, `safe_menu_overlay.gd`, `temp_screen_theme.gd` | centralize density/breakpoint constants |
| UI-F5 | Theme usage mixed between helper and inline styleboxes/colors | `Game/UI/temp_screen_theme.gd` plus multiple UI files | centralize remaining inline style rules |
| UI-F6 | Accessibility floor not consistently met | `Game/UI/inventory_card_factory.gd`, `run_status_strip.gd`, `safe_menu_overlay.gd` | raise compact font/tap-target floors |
| UI-F7 | Signal lifecycle style inconsistent | `Game/UI/safe_menu_overlay.gd`, helper-backed UI files | standardize connect/disconnect style |
| UI-F8 | No confirmed dead public UI API | `Game/UI/*` | no action needed |
| ARCH-F1 | No confirmed Core -> UI/scene violation | `Game/Core/*` | no action needed |
| ARCH-F2 | `AppBootstrap` autoload breadth weakens layer discipline | `project.godot`, `Game/Application/app_bootstrap.gd`, `scenes/*` | narrow facade usage |
| ARCH-F3 | `InventoryState` getters have hidden write side-effects | `Game/RuntimeState/inventory_state.gd` | treat as high-risk cleanup if semantics change |
| ARCH-F4 | `SceneRouter` is tightly coupled to scene-specific choreography strings | `Game/Infrastructure/scene_router.gd` | harden routing contract |
| ARCH-F5 | Command/event architecture mostly centralized, but catalog drift remains | `Game/Application/combat_flow.gd`, `Docs/COMMAND_EVENT_CATALOG.md` | update docs and optionally add guard coverage |
| ARCH-F6 | Architecture guard coverage has gaps | `Tools/validate_architecture_guards.py` | add checks for drift/cycles/autoload breadth if worthwhile |
| ARCH-F7 | Most constants are owner-centralized; one unnamed map heuristic stands out | `Game/RuntimeState/map_runtime_state.gd:1961` | name/extract the `0.75` heuristic |
| MAINT-F1 | `500+` line hotspot count is still high (`17`) | `Game/*`, `scenes/*` | continue extraction-first on largest files |
| MAINT-F2 | `28` functions exceed `80` lines | `Game/*`, `scenes/*` | split longest functions by concern |
| MAINT-F3 | Deeply nested hotspots cluster in map/save/support policy logic | `Game/UI/map_board_composer_v2.gd`, `Game/Infrastructure/save_service*.gd`, `Game/Application/support_action_application_policy.gd` | flatten control flow and isolate validators |
| MAINT-F4 | Legacy naming persists (`side_mission_`, `node_resolve`) though snake_case is otherwise clean | runtime/application/scene files | keep legacy names only where compat/stable-ID requires it |
| MAINT-F5 | No TODO/FIXME/HACK/XXX comments, but stale compatibility comments remain | `Game/Infrastructure/save_service.gd`, `Game/Application/flow_state.gd`, `Game/RuntimeState/run_state.gd` | prune stale comments with dead code cleanup |
| MAINT-F6 | Many public Core/Application functions have no direct test-name hits | `Game/Core/*`, `Game/Application/*` | distinguish smoke-only coverage from missing unit coverage |
| MAINT-F7 | High-signal duplicate code families remain in `Game/` | `_hash_seed_string`, deep-copy loops, inventory-family mapping, policy branches | extract shared helpers only where owner meaning stays intact |
| MAINT-F8 | Several public wrappers/helpers appear dead or stale | `Game/Application/game_flow_manager.gd`, `Game/Infrastructure/playtest_logger.gd`, `Game/Infrastructure/save_service.gd`, `Game/RuntimeState/map_runtime_state.gd`, `Game/UI/*` | prune or privatize confirmed dead paths |
| MAINT-F9 | Tooling is mostly healthy, but `validate_content.py` is large and local cache artifacts exist | `Tools/*` | optional tooling hygiene pass |

## Blockers (Critical, tercihen öncesinde escalate)

- [B-1] Missing maintainability audit artifact
  - Kapsam: `Docs/Audit/2026-04-18-maintainability-audit.md`
  - Risk lane: Fast
  - Tip: Doc drift / process gap
  - Effort × Value: `S × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`
  - Kaynak audit bulgu ID'leri: `META-1`, `MAINT-F1..MAINT-F9`
  - `CODEX_POLISH_PROMPTS` ref: none
  - Not: A6 findings are currently reconstructable from session notes, but not durable as a checked-in report.

- [B-2] Align `NodeResolve` live fallback contract with docs
  - Kapsam: `Game/Application/game_flow_manager.gd`, `Game/Application/run_session_coordinator.gd`, `scenes/map_explore.gd`, `Game/Infrastructure/scene_router.gd`, `Docs/GAME_FLOW_STATE_MACHINE.md`
  - Risk lane: Guarded
  - Tip: Flow/doc drift
  - Effort × Value: `M × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `APP-F1`, `SCN-F7`
  - `CODEX_POLISH_PROMPTS` ref: none
  - Not: Doc-only correction is fast-lane; code narrowing is guarded.

## Quick Wins (Fast Lane)

- [P-01] Fix `SAVE_SCHEMA` pending-node ownership drift
  - Kapsam: `Docs/SAVE_SCHEMA.md`
  - Risk lane: Fast
  - Tip: Doc drift
  - Effort × Value: `S × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`
  - Kaynak audit bulgu ID'leri: `RS-F1`
  - `CODEX_POLISH_PROMPTS` ref: none

- [P-02] Update command/event catalog for live combat surfaces
  - Kapsam: `Docs/COMMAND_EVENT_CATALOG.md`
  - Risk lane: Fast
  - Tip: Doc drift
  - Effort × Value: `S × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`
  - Kaynak audit bulgu ID'leri: `APP-F3`, `ARCH-F5`
  - `CODEX_POLISH_PROMPTS` ref: none

- [P-03] Extract duplicated inventory display-name/family mapping helper
  - Kapsam: `Game/UI/event_presenter.gd`, `Game/UI/reward_presenter.gd`, new helper under `Game/UI/`
  - Risk lane: Fast
  - Tip: Extraction / duplicate cleanup
  - Effort × Value: `S × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_event_node.gd test_reward_node.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `UI-F2`, `MAINT-F7`
  - `CODEX_POLISH_PROMPTS` ref: none

- [P-04] Consolidate texture loading around one shared helper
  - Kapsam: `Game/UI/inventory_card_factory.gd`, `Game/UI/map_board_canvas.gd`, `Game/UI/scene_layout_helper.gd`
  - Risk lane: Fast
  - Tip: Extraction / optimization
  - Effort × Value: `S × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `UI-F3`, `MAINT-F7`
  - `CODEX_POLISH_PROMPTS` ref: `covered by Faz 2.1` (follow-up, not duplicate)

- [P-05] Prune stale wrappers and obvious dead public aliases
  - Kapsam: `Game/Application/game_flow_manager.gd:transition_to`, `Game/Infrastructure/save_service.gd:is_supported_save_state_now`, compatible dead/stale wrappers found by grep
  - Risk lane: Fast
  - Tip: Dead code kaldır
  - Effort × Value: `S × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; targeted tests for touched slice; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `RS-F5`, `APP-F5`, `MAINT-F8`
  - `CODEX_POLISH_PROMPTS` ref: `covered by Faz 1.1` only for `dispatch()`; this is adjacent cleanup, not duplicate work

- [P-06] Add narrow guard coverage for catalog drift and stale wrapper regressions
  - Kapsam: `Tools/validate_architecture_guards.py`
  - Risk lane: Fast
  - Tip: Tooling hardening
  - Effort × Value: `M × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `ARCH-F6`, `APP-F3`, `MAINT-F8`
  - `CODEX_POLISH_PROMPTS` ref: none

## Strategic (Guarded Lane)

- [P-10] Narrow scene dependence on `AppBootstrap` raw getters
  - Kapsam: `Game/Application/app_bootstrap.gd`, `scenes/*`
  - Risk lane: Guarded
  - Tip: Owner clean / architecture hardening
  - Effort × Value: `L × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `APP-F2`, `ARCH-F2`
  - `CODEX_POLISH_PROMPTS` ref: none

- [P-11] Standardize Application invalid-state/error handling style
  - Kapsam: `Game/Application/run_session_coordinator.gd`, `app_bootstrap.gd`, `combat_flow.gd`, `save_runtime_bridge.gd`, `game_flow_manager.gd`
  - Risk lane: Guarded
  - Tip: Architecture / bug-hardening
  - Effort × Value: `M × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; targeted flow/save/combat tests; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `APP-F4`
  - `CODEX_POLISH_PROMPTS` ref: none

- [P-12] Finish scene theme/layout consolidation for the remaining 11 drifted scene functions
  - Kapsam: `scenes/*.gd`, `Game/UI/scene_layout_helper.gd`, `Game/UI/temp_screen_theme.gd`, `Game/UI/scene_audio_players.gd`
  - Risk lane: Guarded
  - Tip: Extraction / UI consistency
  - Effort × Value: `L × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `SCN-F3`, `UI-F4`, `UI-F5`
  - `CODEX_POLISH_PROMPTS` ref: `conflict with Faz 2.1 / Faz 2.2` only in the sense that those prompts were partial; this is the remaining follow-up

- [P-13] Remove shared inventory-panel post-render traversal hotspots
  - Kapsam: `Game/UI/run_inventory_panel.gd`, `Game/UI/inventory_card_factory.gd`, `scenes/combat.gd`, `scenes/map_explore.gd`
  - Risk lane: Guarded
  - Tip: Optimization / extraction
  - Effort × Value: `M × H`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_inventory_card_interaction_handler.gd test_button_tour.gd test_phase2_loop.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `SCN-F4`, `SCN-F5`
  - `CODEX_POLISH_PROMPTS` ref: `covered by Faz 4.2` (partial; cache pass landed, card-child traversal still remains)

- [P-14] Centralize portrait density constants, theme rhythm, and accessibility floors
  - Kapsam: `Game/UI/combat_scene_ui.gd`, `map_explore_scene_ui.gd`, `safe_menu_overlay.gd`, `temp_screen_theme.gd`, `inventory_card_factory.gd`, `run_status_strip.gd`
  - Risk lane: Guarded
  - Tip: UI polish / accessibility
  - Effort × Value: `M × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; portrait captures; map/combat isolation; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `UI-F4`, `UI-F5`, `UI-F6`, `UI-F7`
  - `CODEX_POLISH_PROMPTS` ref: none

- [P-15] Harden `SceneRouter` overlay contract away from scene-specific string choreography
  - Kapsam: `Game/Infrastructure/scene_router.gd`, overlay-opening scene methods, related docs
  - Risk lane: Guarded
  - Tip: Architecture / extraction
  - Effort × Value: `M × M`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: `ARCH-F4`
  - `CODEX_POLISH_PROMPTS` ref: none

## Escalate-First (High-Risk)

- [E-1] Implement the `MapRuntimeState` extraction plan
  - Kapsam: `Game/RuntimeState/map_runtime_state.gd`, planned helper files from `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
  - Risk lane: High-Risk-Escalate
  - Tip: Extraction / owner clean
  - Effort × Value: `L × H`
  - Doğrulama: escalate-first decision, then full suite plus map-specific tests and smoke
  - Kaynak audit bulgu ID'leri: `RS-F3`, `ARCH-F7`, `MAINT-F1`, `MAINT-F2`, `MAINT-F3`
  - `CODEX_POLISH_PROMPTS` ref: `covered by Faz 3.4` (report-only planning complete; implementation still open)
  - Decision needed: whether owner-preserving extraction is worth the risk now.

- [E-2] Remove or collapse `RunState` compatibility accessors
  - Kapsam: `Game/RuntimeState/run_state.gd`, callers/tests/save compat surfaces
  - Risk lane: High-Risk-Escalate
  - Tip: Owner clean / compatibility cleanup
  - Effort × Value: `M × M`
  - Doğrulama: escalate-first decision, then save roundtrip + full suite
  - Kaynak audit bulgu ID'leri: `RS-F2`
  - `CODEX_POLISH_PROMPTS` ref: none
  - Decision needed: keep frozen forever or actively retire with migration policy.

- [E-3] Untangle hamlet side-quest state ownership split
  - Kapsam: `Game/RuntimeState/map_runtime_state.gd`, `Game/RuntimeState/support_interaction_state.gd`, related bridge code/docs
  - Risk lane: High-Risk-Escalate
  - Tip: Owner clean
  - Effort × Value: `L × H`
  - Doğrulama: escalate-first decision, then support/map/save targeted tests + full suite
  - Kaynak audit bulgu ID'leri: `RS-F3`
  - `CODEX_POLISH_PROMPTS` ref: none

- [E-4] Rework `InventoryState` cached getter semantics to remove hidden write side-effects
  - Kapsam: `Game/RuntimeState/inventory_state.gd` and any getter callers
  - Risk lane: High-Risk-Escalate
  - Tip: Architecture hardening / optimization follow-up
  - Effort × Value: `M × M`
  - Doğrulama: escalate-first decision, then inventory/save tests + full suite
  - Kaynak audit bulgu ID'leri: `RS-F4`, `ARCH-F3`
  - `CODEX_POLISH_PROMPTS` ref: `conflict with Faz 4.3` only in the sense that Faz 4.3 introduced the cache and this item evaluates a semantic hardening after the optimization landed

- [E-5] Resolve `zz_` event-template stable-ID rename debt
  - Kapsam: `ContentDefinitions/EventTemplates/*.json`, all refs/tests/docs using those IDs
  - Risk lane: High-Risk-Escalate
  - Tip: Rename / content cleanup
  - Effort × Value: `M × M`
  - Doğrulama: `py -3 Tools/validate_content.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
  - Kaynak audit bulgu ID'leri: none in A1-A6 audits; carried forward as explicit open debt from existing patch plan and HANDOFF
  - `CODEX_POLISH_PROMPTS` ref: `covered by Faz 1.3` (blocked by stable-ID rename escalation)
  - Decision needed: whether stable-ID churn is worth the content migration noise.

## Optional / Low Confidence

- [O-1] Optional accessibility polish pass for compact UI
  - Kapsam: `Game/UI/inventory_card_factory.gd`, `run_status_strip.gd`, `safe_menu_overlay.gd`
  - Risk lane: Fast
  - Tip: UI polish
  - Effort × Value: `S × M`
  - Doğrulama: portrait captures; targeted scene isolation; full suite if behavior touched
  - Kaynak audit bulgu ID'leri: `UI-F6`, `UI-F7`
  - `CODEX_POLISH_PROMPTS` ref: none
  - Not: this is a quality choice, not a confirmed correctness bug.

- [O-2] Optional tooling hygiene pass
  - Kapsam: `Tools/validate_content.py`, local cache artifacts, stale helper comments, runner docs
  - Risk lane: Fast
  - Tip: Maintainability / tooling
  - Effort × Value: `S × S`
  - Doğrulama: `py -3 Tools/validate_architecture_guards.py`; tool-specific validators as needed
  - Kaynak audit bulgu ID'leri: `MAINT-F5`, `MAINT-F9`
  - `CODEX_POLISH_PROMPTS` ref: none

## Overlap Matrix

| Audit Finding / Backlog Item | `CODEX_POLISH_PROMPTS` Ref | Action |
|---|---|---|
| `dispatch()` dead path cleanup | `Faz 1.1` | covered by completed patch; no new backlog item |
| `sfx_brace` -> `sfx_defend` rename | `Faz 1.2` | covered by completed patch; no new backlog item |
| `zz_` event-template rename | `Faz 1.3` | backlog `E-5`; blocked by stable-ID rename escalation |
| `gate_warden` unused content | `Faz 1.4` | covered by prior decision; keep parked unless boss/content strategy changes |
| Scene layout/audio duplication | `Faz 2.1`, `Faz 2.2` | backlog `P-12`; partial coverage landed, remaining drift still open |
| `scenes/combat.gd` extraction | `Faz 3.1` | covered by completed patch; residual traversal issue tracked in `P-13` |
| `scenes/map_explore.gd` extraction | `Faz 3.2` | covered by completed patch; residual traversal issue tracked in `P-13` |
| `save_service.gd` split | `Faz 3.3` | covered by completed patch; no new backlog item |
| `map_runtime_state.gd` extraction planning | `Faz 3.4` | report-only coverage complete; implementation backlog stays in `E-1` |
| `combat` deep-copy reduction | `Faz 4.1` | no direct audit blocker currently; revisit only if perf evidence demands it |
| `get_node_or_null` cache pass | `Faz 4.2` | backlog `P-13`; partial coverage landed, per-card traversal remains |
| `InventoryState` slot-family getter cache | `Faz 4.3` | backlog `E-4`; optimization landed, semantic hardening still open |
| Stage opening info card | `Faz 5.3` | covered by completed patch; no new backlog item |

## Open Questions (insan/sen karar)

- `NodeResolve` generic fallback gerçekten canlı contract olarak korunacak mı, yoksa docs kadar daraltılmalı mı?
- `RunState` compatibility accessors dondurulmuş compat yüzeyi olarak mı kalmalı, yoksa migration planı ile kaldırılmalı mı?
- Hamlet side-quest alanları iki owner arasında bilinçli phase split olarak mı kalacak, yoksa net owner cleanup yapılacak mı?
- `InventoryState` cached getter’larında yazan-read semantiği kabul edilebilir mi, yoksa explicit accessor API’ye mi dönülmeli?
- `zz_` event-template rename borcu gerçekten çözülmek isteniyor mu, yoksa stable-ID churn’den kaçınmak için bırakılacak mı?
- `gate_warden` içerik ve asset’leri test/rezerv içerik olarak mı kalmalı, yoksa gerçekten archive / 4th boss planı mı yapılmalı?
- Eksik A6 audit artifact’i yeniden oluşturulmadan bu audit seti “tam ve durable” kabul edilecek mi?
