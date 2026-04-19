# Application Layer Audit - 2026-04-18

Status: report-only  
Method: static analysis plus grep/rg only  
Code changes: none  
Authority:
- `Docs/ARCHITECTURE.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/COMMAND_EVENT_CATALOG.md` (reference-only naming catalog)

## Scope

Audited files:
- `Game/Application/app_bootstrap.gd` - 483 lines / 54 functions / 31 public
- `Game/Application/combat_flow.gd` - 764 lines / 39 functions / 14 public
- `Game/Application/enemy_selection_policy.gd` - 124 lines / 9 functions / 5 public
- `Game/Application/event_application_policy.gd` - 101 lines / 1 function / 1 public
- `Game/Application/flow_state.gd` - 63 lines
- `Game/Application/game_flow_manager.gd` - 95 lines / 5 functions / 4 public
- `Game/Application/inventory_actions.gd` - 1087 lines / 27 functions / 22 public
- `Game/Application/inventory_overflow_resolver.gd` - 368 lines
- `Game/Application/level_up_offer_window_policy.gd` - 70 lines / 4 functions / 3 public
- `Game/Application/reward_application_policy.gd` - 91 lines / 1 function / 1 public
- `Game/Application/run_session_coordinator.gd` - 1018 lines / 45 functions / 21 public
- `Game/Application/save_runtime_bridge.gd` - 129 lines / 7 functions / 7 public
- `Game/Application/support_action_application_policy.gd` - 594 lines / 11 functions / 1 public
- `Game/Infrastructure/scene_router.gd`
- `Game/Infrastructure/save_service.gd`
- `Game/Infrastructure/save_service_legacy_loader.gd`
- `Docs/ARCHITECTURE.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/COMMAND_EVENT_CATALOG.md`
- `project.godot`

Limitations:
- This pass is grep-based and static-analysis only.
- "Unused" means "no non-definition caller found with grep" and does not prove reflective invocation is impossible.
- `COMMAND_EVENT_CATALOG.md` is reference-only by `Docs/DOC_PRECEDENCE.md`; drift there is still worth reporting because humans may trust it as the implemented surface map.

## Executive Summary

Confirmed critical drift:
- `NodeResolve` is still a broader live code transition shell than the docs currently claim. Code still allows `MapExplore -> NodeResolve`, and `NodeResolve -> Combat` is still part of the actual transition table.

Confirmed major issues:
- `AppBootstrap` has grown into a broad convenience facade. Several scenes still reach it directly through `/root/AppBootstrap`, then call getters such as `get_run_state()` and `get_flow_manager()`. That keeps ownership technically unchanged, but it widens the gameplay-facing surface.
- `Docs/COMMAND_EVENT_CATALOG.md` is behind the code. `CombatFlow` exposes `turn_phase_resolved` and emits `BossPhaseChanged`, but those are not listed.
- Invalid-state/error handling style is inconsistent across Application files: `push_error + {ok:false}`, `{ok:false}` only, silent early return, and "skipped" result objects all coexist.

Confirmed non-problem:
- Save/load orchestration is currently split in a coherent way: `SaveRuntimeBridge` owns orchestration, `SaveService` owns snapshot IO/validation, and `SaveServiceLegacyLoader` still serves active legacy schema paths.

Likely structural risk:
- Combat end orchestration is readable, but it is spread across `CombatFlow`, scene bridging, `AppBootstrap`, `RunSessionCoordinator`, and `GameFlowManager` rather than being visibly centralized in one Application owner.

## Findings

### F1 - `NodeResolve` transition contract is broader in code than in docs

- Severity: Critical
- Confidence: Confirmed
- AGENTS risk lane estimate for fixing:
  - doc-only correction: low-risk fast lane
  - code contract narrowing: medium-risk guarded lane or higher, depending on whether fallback behavior changes

Evidence:
- `Game/Application/game_flow_manager.gd` allows:
  - `MAP_EXPLORE -> NODE_RESOLVE`
  - `NODE_RESOLVE -> COMBAT`
- `Game/Application/run_session_coordinator.gd` still has a live fallback path that ends with:
  - `map_runtime_state.set_pending_node(target_node_id)`
  - `_request_transition(FlowStateScript.Type.NODE_RESOLVE)`
  - `return FlowStateScript.Type.NODE_RESOLVE`
- `scenes/map_explore.gd` still branches on `target_state == FlowState.Type.NODE_RESOLVE`.
- `Docs/GAME_FLOW_STATE_MACHINE.md` says `NodeResolve` is legacy-compat only and "reached only from direct-entry fallback for legacy `side_mission` saves or equivalent legacy-compatible pending-node restore paths."

Impact:
- The current docs describe the intended steady-state, but not the full live code contract.
- This is doc drift even if normal authored node families rarely hit the generic fallback.

Recommendation:
- Update `Docs/GAME_FLOW_STATE_MACHINE.md` to describe the remaining generic fallback more precisely, or narrow the live code path in a guarded pass.

### F2 - `AppBootstrap` facade expansion is real and scenes still lean on it directly

- Severity: Major
- Confidence: Likely
- AGENTS risk lane estimate for cleanup: medium-risk guarded lane

Evidence:
- `project.godot` autoload list contains only `AppBootstrap` and `SceneRouter`, which is architecturally clean.
- But multiple scenes still call `/root/AppBootstrap` directly:
  - `scenes/combat.gd`
  - `scenes/event.gd`
  - `scenes/level_up.gd`
  - `scenes/main.gd`
  - `scenes/main_menu.gd`
  - `scenes/map_explore.gd`
  - `scenes/node_resolve.gd`
  - `scenes/reward.gd`
  - `scenes/run_end.gd`
  - `scenes/stage_transition.gd`
  - `scenes/support_interaction.gd`
- `AppBootstrap` exposes a large public surface, including direct getters for owner/runtime objects plus gameplay commands and save/window helpers.

Interpretation:
- This is not a confirmed owner violation because `Docs/ARCHITECTURE.md` still allows `AppBootstrap` as the application facade.
- It is still a facade-expansion risk because scenes can reach deeper owners through it instead of a narrower Application action surface.

Recommendation:
- Keep current behavior for now.
- In future guarded cleanup, prefer reducing scene reliance on raw getters before adding any new convenience methods.

### F3 - Command/event catalog is behind the implemented Application surface

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for fixing: low-risk fast lane

Evidence:
- `Game/Application/combat_flow.gd` defines:
  - `signal turn_phase_resolved(phase_name: String, action_name: String, result: Dictionary)`
- `Game/Application/combat_flow.gd` emits:
  - `"BossPhaseChanged"`
- `Docs/COMMAND_EVENT_CATALOG.md` lists neither `turn_phase_resolved` nor `BossPhaseChanged`.

Impact:
- Humans reading the catalog can miss real live signal/event surfaces.
- This is naming/reference drift, not confirmed runtime breakage.

Recommendation:
- Update the catalog to include these implemented surfaces.

### F4 - Error recovery style is inconsistent across Application owners

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for fixing: medium-risk guarded lane

Evidence:
- `GameFlowManager.request_transition()` and `restore_state()` use `push_error(...)` plus structured `{ok:false}` payloads.
- `SaveRuntimeBridge` mostly returns `{ok:false}` without engine logging.
- `RunSessionCoordinator._request_transition()` silently returns when dependencies are missing.
- `AppBootstrap._request_transition()` also silently returns when `game_flow_manager` is null.
- `CombatFlow` often encodes invalid/blocked states as "skipped" or combat-local result dictionaries rather than explicit error objects.

Impact:
- The layer does not expose one consistent invalid-state policy.
- This makes telemetry, debugging, and auditability less uniform.

Recommendation:
- If this is cleaned later, standardize by family instead of globally rewriting everything at once.

### F5 - Dead/test-only surfaces remain in Application

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup:
  - test-only wrappers: low-risk fast lane
  - anything touching compat or orchestration meaning: medium-risk guarded lane

Highlights:
- `Game/Application/game_flow_manager.gd`
  - `transition_to(...)` is only a wrapper over `request_transition(...)`
- `Game/Application/app_bootstrap.gd`
  - `apply_fullscreen_mode(...)` has no non-self caller
  - `apply_resolution_by_index(...)` has no non-self caller beyond boot-time internal use
- `Game/Application/combat_flow.gd`
  - `process_player_attack`, `process_enemy_action`, `process_use_item`, `process_defend`, `process_turn_end`, and `check_combat_end` are heavily test-facing surfaces
- `Game/Application/inventory_actions.gd`
  - `_coerce_inventory_state(...)` still carries an explicit compatibility comment:
    - `# Transitional compatibility only. New callers should prefer passing InventoryState directly`
- `Game/Application/enemy_selection_policy.gd`
  - `is_combat_enemy_definition_allowed(...)` and `is_boss_enemy_definition(...)` are only used internally inside the same file

Impact:
- Not a correctness bug by itself.
- It does mean some Application surfaces are retained mostly for tests, wrappers, or past migration convenience.

### F6 - Save/load orchestration split is currently clear, and legacy loaders are still active

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: medium-risk guarded lane if changed

Evidence:
- `Game/Application/save_runtime_bridge.gd` owns orchestration:
  - save-safe flow gating
  - snapshot assembly
  - restore coordination
- `Game/Infrastructure/save_service.gd` owns snapshot creation, validation, file IO, and dispatch.
- `Game/Infrastructure/save_service_legacy_loader.gd` still serves live compatibility paths:
  - `SUPPORTED_LEGACY_SAVE_SCHEMA_VERSIONS = [1, 2, 5, 6, 7]`
  - content-version checks and schema-specific validation branches are still active.

Interpretation:
- This is not dead code.
- The earlier split appears healthy.

## 1) Facade Expansion Risk

### `AppBootstrap` public surface classification

| Method | Classification | Confirmed / Likely / Unclear | Notes |
|---|---|---|---|
| `get_flow_manager()` | Facade getter / owner leakage risk | Likely | Widely used by scenes |
| `get_run_state()` | Facade getter / owner leakage risk | Likely | Widely used by scenes |
| `get_map_runtime_state()` | Facade getter / owner leakage risk | Likely | Narrower use, still exposes owner |
| `get_reward_state()` | Facade getter / owner leakage risk | Likely | Exposes pending-choice owner directly |
| `get_level_up_state()` | Facade getter / owner leakage risk | Likely | Same pattern |
| `get_event_state()` | Facade getter / owner leakage risk | Likely | Same pattern |
| `get_support_interaction_state()` | Facade getter / owner leakage risk | Likely | Same pattern |
| `build_combat_setup_data()` | Application-owned command surface | Likely | Application composition responsibility fits |
| `save_game()` | Save bridge surface | Confirmed | Delegates to `SaveRuntimeBridge` |
| `load_game()` | Save bridge surface | Confirmed | Delegates to `SaveRuntimeBridge` |
| `build_save_snapshot()` | Save bridge surface | Confirmed | Delegates to `SaveRuntimeBridge` |
| `restore_from_snapshot()` | Save bridge surface | Confirmed | Delegates to `SaveRuntimeBridge` |
| `apply_fullscreen_mode()` | UI/window utility | Confirmed | Not a gameplay owner issue, but surface sprawl |
| `apply_ui_scale_to_active_scene()` | UI/window utility | Confirmed | Presentation/window helper |
| `apply_resolution_by_index()` | UI/window utility | Confirmed | Startup/display helper |
| `has_save_game()` | Save bridge surface | Confirmed | Delegates to `SaveRuntimeBridge` |
| `delete_save_game()` | Save bridge surface | Confirmed | Delegates to `SaveRuntimeBridge` |
| `reset_run_state_for_new_run()` | Application orchestration | Likely | Boot/new-run lifecycle |
| `ensure_run_state_initialized()` | Application orchestration | Likely | Run bootstrap guard, but broad |
| `get_last_run_result()` | Application orchestration | Likely | Facade convenience, not obvious owner drift |
| `choose_move_to_node()` | Application-owned command surface | Confirmed | Matches command catalog |
| `toggle_inventory_equipment()` | Application-owned command surface | Likely | UI-facing action wrapper over inventory session logic |
| `move_inventory_slot()` | Application-owned command surface | Likely | Same |
| `use_inventory_consumable()` | Application-owned command surface | Likely | Same |
| `resolve_pending_node()` | Application-owned command surface | Confirmed | Matches command catalog |
| `choose_reward_option()` | Application-owned command surface | Confirmed | Matches command catalog |
| `choose_event_option()` | Application-owned command surface | Confirmed | Matches command catalog |
| `resolve_combat_result()` | Application-owned command surface | Confirmed | Matches command catalog |
| `choose_level_up_option()` | Application-owned command surface | Confirmed | Matches command catalog |
| `choose_support_action()` | Application-owned command surface | Confirmed | Matches command catalog |
| `finish_boot_to_main_menu()` | Application orchestration | Confirmed | Flow/bootstrap responsibility fits |

### Conclusion

Confirmed:
- `AppBootstrap` is still functioning as a real application facade, not a hidden owner.

Likely risk:
- The getter-heavy surface makes it easy for scenes to keep bypassing narrower Application commands.

## 2) Orchestration Scatter

### Combat finish path

Confirmed path:
1. `CombatFlow` resolves combat-local action loop and emits `combat_ended_signal`.
2. `scenes/combat.gd` receives the signal and calls `AppBootstrap.resolve_combat_result(...)`.
3. `AppBootstrap` delegates to `RunSessionCoordinator.resolve_combat_result(...)`.
4. `RunSessionCoordinator` decides:
   - `Combat -> Reward`
   - `Combat -> StageTransition`
   - `Combat -> RunEnd`
5. `GameFlowManager` validates and flips the flow state.

### Reward / LevelUp continuation

Confirmed:
- `RunSessionCoordinator` also owns the post-reward and post-level-up continuation logic.

Assessment:
- Ownership is understandable.
- The choreography is still scattered across more than one Application owner plus a scene bridge.

Classification:
- Major / Likely

## 3) Dead Command / Event Path

### Confirmed deprecated-path cleanup that already landed

- `GameFlowManager.dispatch()` is gone.
- No `.dispatch(...)` caller was found in the repo.

### Remaining dead/test-only candidates

| Surface | Classification | Confirmed / Likely / Unclear | Notes |
|---|---|---|---|
| `GameFlowManager.transition_to(...)` | Minor | Confirmed | Thin wrapper over `request_transition(...)` |
| `AppBootstrap.apply_fullscreen_mode(...)` | Minor | Confirmed | No live external caller found |
| `AppBootstrap.apply_resolution_by_index(...)` | Minor | Confirmed | No live external caller found beyond internal startup path |
| `CombatFlow.process_*` helper family | Minor | Confirmed | Strongly test-facing but still useful for combat spike/status tests |
| `CombatFlow.check_combat_end()` | Minor | Confirmed | Test-facing plus internal caller usage |
| `InventoryActions._coerce_inventory_state(...)` | Minor | Confirmed | Explicit compatibility shim |
| `EnemySelectionPolicy.is_combat_enemy_definition_allowed(...)` | Minor | Confirmed | Internal helper only |
| `EnemySelectionPolicy.is_boss_enemy_definition(...)` | Minor | Confirmed | Internal helper only |

## 4) State Machine Gap

### Doc-to-code comparison

Confirmed in code:
- `MapExplore -> NodeResolve` still exists
- `NodeResolve -> Combat` still exists

Confirmed in docs:
- `Docs/GAME_FLOW_STATE_MACHINE.md` frames `NodeResolve` as legacy-compat only and not part of the live map traversal path
- It does not list `MapExplore -> NodeResolve` as a current transition
- It also does not list `NodeResolve -> Combat`

Interpretation:
- The docs describe the intended primary path.
- The code still carries a broader fallback shell.

Classification:
- Critical / Confirmed

### NodeResolve current status

Confirmed:
- `NodeResolve` is not dead.
- It is still routable by generic fallback and still has a real scene entry in `SceneRouter`.

Likely:
- Normal authored map traversal avoids it most of the time.

## 5) Error Recovery

| File | Invalid-state style | Confirmed / Likely / Unclear | Notes |
|---|---|---|---|
| `game_flow_manager.gd` | `push_error + {ok:false}` | Confirmed | Most explicit style in the layer |
| `save_runtime_bridge.gd` | `{ok:false}` only | Confirmed | Bridge-style return contract |
| `run_session_coordinator.gd` | `{ok:false}` plus some silent early returns | Confirmed | `_request_transition()` silently no-ops on missing manager |
| `app_bootstrap.gd` | delegated dict results plus some silent helper returns | Confirmed | Same pattern as coordinator |
| `combat_flow.gd` | semantic result objects / skipped actions / ended states | Confirmed | Combat local flow uses result modeling instead of error signaling |
| `inventory_actions.gd` | `{ok:false}` only | Confirmed | Consistent within the file, different from `GameFlowManager` |

Assessment:
- No single Application-wide error style exists.
- This is manageable but inconsistent.

## 6) Autoload Usage

### project.godot comparison

Confirmed autoloads:
- `AppBootstrap`
- `SceneRouter`

No extra gameplay autoload was found.

### Communication style

Confirmed:
- Scenes commonly use `/root/AppBootstrap` directly.
- `SceneRouter` directly looks up `/root/AppBootstrap`.
- `AppBootstrap` directly looks up `/root/SceneRouter`.
- Internal Application helpers use `setup(...)` injection and field references.

Assessment:
- Autoload count is still disciplined.
- Communication style is mixed direct-global plus DI, not purely one or the other.

Classification:
- Major / Likely for future maintainability
- Not a confirmed architecture break under current rules

## 7) Save/Load Orchestration

### Current split

Confirmed:
- `SaveRuntimeBridge`
  - gates save-safe flow states
  - builds snapshots
  - restores snapshots back into runtime/application owners
- `SaveService`
  - creates snapshot dictionaries
  - validates snapshot payloads
  - reads/writes save files
- `SaveServiceLegacyLoader`
  - still actively supports legacy schema versions `1, 2, 5, 6, 7`

### Legacy path status

Confirmed:
- Legacy save load paths are not dead code.
- Current validation still routes through legacy schema/content-version branches.

Assessment:
- This split is one of the clearer areas in the Application/Infrastructure boundary right now.

## Recommendations

1. Doc-only fix first
   - Update `Docs/GAME_FLOW_STATE_MACHINE.md` so `NodeResolve` reflects the real fallback contract.
   - Update `Docs/COMMAND_EVENT_CATALOG.md` for `turn_phase_resolved` and `BossPhaseChanged`.

2. Guarded cleanup candidates
   - Reduce scene dependency on `AppBootstrap` getters before adding any new facade methods.
   - Review whether `GameFlowManager.transition_to(...)` should stay as a wrapper.
   - Review dead UI/window helpers on `AppBootstrap`.

3. Keep as-is for now
   - `SaveRuntimeBridge` / `SaveService` / `SaveServiceLegacyLoader` split
   - legacy save loader branches for versions `1, 2, 5, 6, 7`

4. Do not fast-lane
   - removing `NodeResolve` code paths
   - moving orchestration ownership among `CombatFlow`, `RunSessionCoordinator`, and `GameFlowManager`
   - shrinking `AppBootstrap` by changing owner meaning rather than just narrowing scene access

## Validation

Expected for this report pass:
- `py -3 Tools/validate_architecture_guards.py`

No `.gd` files or authority docs were modified as part of this audit.
