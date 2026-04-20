# Scene Layer Audit - 2026-04-18

Status: report-only  
Method: static analysis plus grep/rg only  
Code changes: none  
Authority:
- `AGENTS.md` non-negotiables
- `Docs/ARCHITECTURE.md`
- `Docs/HANDOFF.md` for current-state context only

## Scope

Audited scene scripts:
- `scenes/combat.gd` - 1098 lines / 60 functions / `13` `get_node_or_null(...)`
- `scenes/event.gd` - 432 lines / 22 functions / `1` `get_node_or_null(...)`
- `scenes/level_up.gd` - 411 lines / 21 functions / `5` `get_node_or_null(...)`
- `scenes/main.gd` - 228 lines / 17 functions / `11` `get_node_or_null(...)`
- `scenes/main_menu.gd` - 257 lines / 15 functions / `29` `get_node_or_null(...)`
- `scenes/map_explore.gd` - 905 lines / 68 functions / `10` `get_node_or_null(...)`
- `scenes/node_resolve.gd` - 170 lines / 10 functions / `10` `get_node_or_null(...)`
- `scenes/reward.gd` - 481 lines / 26 functions / `1` `get_node_or_null(...)`
- `scenes/run_end.gd` - 242 lines / 15 functions / `15` `get_node_or_null(...)`
- `scenes/stage_transition.gd` - 239 lines / 16 functions / `16` `get_node_or_null(...)`
- `scenes/support_interaction.gd` - 415 lines / 23 functions / `1` `get_node_or_null(...)`

Audited scene resources:
- `scenes/*.tscn` read-only

Scene-adjacent file explicitly named by the prompt and audited:
- `Game/UI/safe_menu_overlay.gd` - 643 lines / `3` `get_node_or_null(...)`

Not present in current repo snapshot:
- `scenes/boot.gd`
- `scenes/safe_menu_overlay.gd`

Limitations:
- This pass is grep/static-analysis only.
- Reachability and leak findings are based on visible callers and lifecycle code, not live runtime instrumentation.

## Executive Summary

Confirmed clean:
- No confirmed gameplay-truth leak was found in scene scripts. Current scene code mostly renders from `RunState`, `MapRuntimeState`, `CombatState`, and pending-choice owner states directly rather than keeping separate local gameplay copies.
- No confirmed display-text-as-logic pattern was found. `.text` surfaces are written for presentation, but no `if label.text == ...`-style logic gate was found.
- Scene preload/load and `.tscn` ext-resource paths audited in this pass all resolved to existing files.

Confirmed maintainability issues:
- Duplicate scene-specific `_apply_temp_theme()` and `_apply_portrait_safe_layout()` functions still exist in `11` scene scripts, and every body has drifted. This is not raw copy-paste anymore; it is repeated scene-local variation.
- `combat.gd` no longer has the old `118`-call `get_node_or_null(...)` hotspot, but it still has refresh-sensitive child traversal in the shared inventory-card post-render path.
- `map_explore.gd` has the same remaining per-card traversal pattern in its inventory-card post-render path.

Confirmed legacy reachability:
- `node_resolve.gd` is still runtime-reachable. It is not dead scene ballast yet.

Likely lifecycle watchpoint:
- Most scenes now bind/unbind viewport listeners through `SceneLayoutHelperScript`, which is good.
- `main.gd` and `Game/UI/safe_menu_overlay.gd` still rely on fire-and-forget tweens/timers without explicit cancellation; static audit cannot confirm a bug, but the style is less explicit than the newer helper-backed scenes.

## Findings

### F1 - No confirmed gameplay-truth leak in scene scripts

- Severity: None
- Confidence: Confirmed
- AGENTS risk lane estimate for any future cleanup: low-risk fast lane if it stays presentation-only

Evidence:
- `scenes/combat.gd:329-488` rebuilds the screen from `_combat_flow.combat_state` and presenter outputs on each `_refresh_ui()`.
- `scenes/map_explore.gd:257-352` rebuilds the screen from `run_state`, presenter outputs, and route binding/composer outputs rather than scene-local gameplay scalars.
- `scenes/event.gd:130-176`, `scenes/reward.gd:166-210`, `scenes/support_interaction.gd:142-176`, and `scenes/level_up.gd:182-221` render directly from their owner state objects plus presenter-built view models.

Notable local scene vars that are present but not gameplay truth:
- `scenes/combat.gd:61-69`
  - `_selected_consumable_slot_index`
  - `_pending_phase_feedback_models`
  - `_last_rendered_guard`
  - hunger-warning UI handles
- `scenes/map_explore.gd:44-56`
  - `_route_layout_offset`
  - `_board_composition_cache`
  - `_route_models_cache`
  - `_roadside_visual_state`
  - `_refresh_ui_pending`

Assessment:
- These are presentation caches, selection state, or overlay choreography state, not confirmed owner drift.

### F2 - No confirmed display-text-as-logic usage

- Severity: None
- Confidence: Confirmed
- AGENTS risk lane estimate for future cleanup: low-risk fast lane

Evidence:
- Scene grep found many `.text = ...` writes, but no confirmed logic of the form:
  - `if label.text == "Defend"`
  - `if button.text == ...`
- Representative `.text` writes are pure presentation:
  - `scenes/combat.gd:479` sets the defend button text from presenter output
  - `scenes/event.gd:161` writes event choice button copy from the presenter model
  - `scenes/support_interaction.gd:164` writes support-action button copy from the presenter model
  - `scenes/main_menu.gd:100-123` writes button and chip text without using that text as a logic key

Assessment:
- This area is currently clean.

### F3 - Duplicate scene polish functions still exist across `11` scenes, and all bodies drift

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: low-risk fast lane if extraction remains presentation-only

Confirmed counts:
- `_apply_portrait_safe_layout()` exists in `11` scene scripts
- `_apply_temp_theme()` exists in `11` scene scripts
- `_on_viewport_size_changed()` exists in `3` files (`combat.gd`, `map_explore.gd`, `safe_menu_overlay.gd`)
- `_configure_audio_players()`, `_connect_viewport_layout_updates()`, `_disconnect_viewport_layout_updates()`, `_load_texture_or_null()` no longer exist in the audited scenes as local duplicate functions

Body drift:
- `_apply_portrait_safe_layout()` -> `11` unique normalized bodies across `11` scene scripts
- `_apply_temp_theme()` -> `11` unique normalized bodies across `11` scene scripts
- `_on_viewport_size_changed()` -> `3` unique normalized bodies across `3` files

Interpretation:
- Earlier duplication has been partially extracted into helpers.
- The remaining repeated functions are not identical clones anymore; they are scene-specific drift around a shared helper vocabulary.

### F4 - `combat.gd` hot-path lookup risk is much smaller now, but per-card post-render traversal remains

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: low-risk fast lane if it stays in `Game/UI/` / `scenes/`

Confirmed `get_node_or_null(...)` reduction:
- Current `scenes/combat.gd` count: `13`
- Historical hotspot mentioned in prior prompts: `118`

Current remaining lookup classes:
1. Scene-node cache fill / fallback lookup
   - `scenes/combat.gd:167-176`
2. Secondary-root fallback lookup chain
   - `scenes/combat.gd:205-226`
3. Inventory-card child traversal after shared panel render
   - `scenes/combat.gd:731-749`
   - `7` per-card `card.get_node_or_null(...)` calls
4. Guard badge shell lookups
   - `scenes/combat.gd:787`
   - `scenes/combat.gd:797`

Hot-path assessment:
- The main scene-level refresh now mostly uses cached `@onready` nodes and `_scene_node(...)`.
- The remaining refresh-sensitive candidate is the per-card traversal in `_after_inventory_panel_render(...)`.

### F5 - `map_explore.gd` has the same shared-panel per-card traversal pattern

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: low-risk fast lane if presentation-only

Evidence:
- `scenes/map_explore.gd:388-406`
  - `7` per-card `card.get_node_or_null(...)` calls inside `_after_inventory_panel_render(...)`

Assessment:
- This mirrors the combat shared inventory panel post-render path.
- It is now much smaller than the old broad scene lookup pattern, but it is still a local node-fragility / refresh-cost spot.

### F6 - Several non-combat scenes still rely on repeated direct path lookups instead of node caches

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: low-risk fast lane

High-count scene totals:
- `scenes/main_menu.gd` - `29`
- `scenes/stage_transition.gd` - `16`
- `scenes/run_end.gd` - `15`
- `scenes/main.gd` - `11`
- `scenes/node_resolve.gd` - `10`

Interpretation:
- These are not the same hot-path problem as old `combat.gd`.
- They are still path-fragility and maintainability risk because many lookups happen in `_refresh_ui()` / `_apply_temp_theme()` rather than cached `@onready` members.

### F7 - `node_resolve.gd` is still live legacy scene code, not dead ballast

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: high-risk escalate-first if behavior changes

Runtime reachability evidence:
- Transition producer:
  - `Game/Application/run_session_coordinator.gd:672-673`
- Scene-level branch:
  - `scenes/map_explore.gd:248`
- Scene routing:
  - `Game/Infrastructure/scene_router.gd:33`

Interpretation:
- `node_resolve.gd` is legacy-leaning but still reachable.
- It should not be treated as removable dead scene code without a guarded flow audit.

### F8 - Lifecycle discipline is mostly good, but two style watchpoints remain

- Severity: Minor
- Confidence: Likely
- AGENTS risk lane estimate for cleanup: low-risk fast lane

Confirmed good pattern:
- Most scenes pair `_ready()` with `_exit_tree()` and use:
  - `SceneLayoutHelperScript.bind_viewport_size_changed(...)`
  - `SceneLayoutHelperScript.unbind_viewport_size_changed(...)`
- Representative examples:
  - `scenes/combat.gd:85`, `scenes/combat.gd:181`
  - `scenes/map_explore.gd:77`, `scenes/map_explore.gd:150`
  - `scenes/event.gd:64`, `scenes/event.gd:85`
  - `scenes/reward.gd:68`, `scenes/reward.gd:90`

Watchpoint A:
- `scenes/main.gd`
  - creates tweens/timers at `150`, `165`, `184`
  - no explicit tween cancellation in `_exit_tree()`
- Static audit cannot confirm a leak; scene destruction may be sufficient in practice.

Watchpoint B:
- `Game/UI/safe_menu_overlay.gd`
  - directly connects viewport `size_changed` at `58-64`
  - no explicit `_exit_tree()` disconnect was found
- This may still be harmless because receiver cleanup in Godot can sever dead-object connections, but the style is less explicit than the helper-backed scenes.

### F9 - Resource path health is currently clean

- Severity: None
- Confidence: Confirmed
- AGENTS risk lane estimate for future cleanup: low-risk fast lane

Confirmed:
- All audited scene-script `preload(...)` / `load(...)` paths resolved to existing files.
- No missing `res://...` `ext_resource` path was found in `scenes/*.tscn`.

## 1) Gameplay Truth Leak

### Confirmed clean

No confirmed scene-local cached gameplay owner fields were found that replace runtime truth with local truth.

What scenes are doing instead:
- holding presenter instances
- holding shared panel/controller helpers
- holding overlay choreography state
- holding UI-only temporary selections or status-line arrays

Examples:
- `scenes/combat.gd:61-69`
- `scenes/map_explore.gd:44-56`
- `scenes/event.gd:47-52`
- `scenes/reward.gd:51-57`
- `scenes/support_interaction.gd:45-48`

### Display-text-as-logic check

Confirmed:
- No `.text == ...` or `.text != ...` logic gate was found in the audited scene files.

## 2) Duplicate Pattern Matrix

Legend:
- `var` = function exists in file
- `yok` = not present
- `drift` = body is unique versus all other occurrences of the same pattern

| Scene | `_apply_portrait_safe_layout` | `_apply_temp_theme` | `_configure_audio_players` | `_connect_viewport_layout_updates` | `_disconnect_viewport_layout_updates` | `_on_viewport_size_changed` | `_load_texture_or_null` |
|---|---|---|---|---|---|---|---|
| `combat.gd` | var, drift, `1091` | var, drift, `1078` | yok | yok | yok | var, drift, `1084` | yok |
| `event.gd` | var, drift, `362` | var, drift, `192` | yok | yok | yok | yok | yok |
| `level_up.gd` | var, drift, `342` | var, drift, `231` | yok | yok | yok | yok | yok |
| `main.gd` | var, drift, `129` | var, drift, `104` | yok | yok | yok | yok | yok |
| `main_menu.gd` | var, drift, `171` | var, drift, `139` | yok | yok | yok | yok | yok |
| `map_explore.gd` | var, drift, `845` | var, drift, `751` | yok | yok | yok | var, drift, `777` | yok |
| `node_resolve.gd` | var, drift, `145` | var, drift, `122` | yok | yok | yok | yok | yok |
| `reward.gd` | var, drift, `407` | var, drift, `230` | yok | yok | yok | yok | yok |
| `run_end.gd` | var, drift, `172` | var, drift, `128` | yok | yok | yok | yok | yok |
| `stage_transition.gd` | var, drift, `212` | var, drift, `168` | yok | yok | yok | yok | yok |
| `support_interaction.gd` | var, drift, `365` | var, drift, `220` | yok | yok | yok | yok | yok |
| `safe_menu_overlay.gd` | yok | yok | yok | yok | yok | var, drift, `431` | yok |

Summary:
- `_apply_portrait_safe_layout`: `11` occurrences / `11` unique bodies
- `_apply_temp_theme`: `11` occurrences / `11` unique bodies
- `_on_viewport_size_changed`: `3` occurrences / `3` unique bodies
- The older exact duplicate helpers listed in the prompt are otherwise gone from scene scripts.

## 3) Node Reference Fragility

### `get_node_or_null(...)` counts by file

| File | Count | Notes |
|---|---:|---|
| `scenes/combat.gd` | 13 | greatly reduced from historical hotspot |
| `scenes/event.gd` | 1 | low |
| `scenes/level_up.gd` | 5 | low |
| `scenes/main.gd` | 11 | mostly refresh/theme lookups |
| `scenes/main_menu.gd` | 29 | highest remaining scene count |
| `scenes/map_explore.gd` | 10 | mostly shared panel post-render |
| `scenes/node_resolve.gd` | 10 | legacy shell |
| `scenes/reward.gd` | 1 | low |
| `scenes/run_end.gd` | 15 | medium |
| `scenes/stage_transition.gd` | 16 | medium |
| `scenes/support_interaction.gd` | 1 | low |
| `Game/UI/safe_menu_overlay.gd` | 3 | scene-adjacent helper |

### `combat.gd` hot-path breakdown

| Area | Lines | Count | Hot after init? |
|---|---|---:|---|
| `_scene_node(...)` cache fill | `167-176` | 1 | shared fallback, not the main hotspot |
| `_combat_secondary_node(...)` fallback chain | `205-226` | 3 | yes, but bounded |
| inventory card child traversal | `731-749` | 7 | yes, per shared-panel render |
| guard badge shell lookup | `787`, `797` | 2 | occasional |

### `map_explore.gd` shared-panel breakdown

| Area | Lines | Count | Hot after init? |
|---|---|---:|---|
| `_scene_node(...)` cache fill | `136-145` | 1 | shared fallback |
| inventory card child traversal | `388-406` | 7 | yes, per shared-panel render |
| menu/inventory hint lookups | `850`, `897` | 2 | occasional |

Assessment:
- The worst broad scene-tree traversal problem was already reduced.
- The remaining cache candidates are concentrated in shared inventory-card post-render code.

## 4) Lifecycle Correctness

### Confirmed good

- `_ready()` / `_exit_tree()` pairing is consistent in the main scene family.
- Viewport resize listeners are generally bound/unbound explicitly through `SceneLayoutHelperScript`.
- Child-node cleanup is explicit where dynamic lane shells are created:
  - `scenes/combat.gd:770` uses `child.queue_free()`

### Likely watchpoints

| File | Lines | Concern | Confirmed / Likely / Unclear |
|---|---|---|---|
| `scenes/main.gd` | `150`, `165`, `184` | fire-and-forget tweens/timers without explicit cancellation | Likely |
| `Game/UI/safe_menu_overlay.gd` | `58-64`, `431` | direct viewport `size_changed` connection, no explicit disconnect found | Likely |

No confirmed queue-free leak or signal-bus leak was proven by this static pass.

## 5) Legacy Scene - `node_resolve.gd`

Confirmed runtime support points:
- `Game/Application/run_session_coordinator.gd:672-673`
- `Game/Infrastructure/scene_router.gd:33`
- `scenes/map_explore.gd:248`

Assessment:
- `node_resolve.gd` is still reachable.
- It is no longer the intended mainline traversal UX, but it is not dead.

## 6) `.tscn` / `.tres` Reference Health

Confirmed:
- Every scene-script `preload(...)` / `load(...)` target checked in this pass exists.
- Every `res://...` path referenced in `scenes/*.tscn` `ext_resource` lines checked in this pass exists.

No confirmed missing-resource risk was found in the audited scene layer.

## Recommendations

1. Low-risk cleanup candidate
   - Extract the remaining shared inventory-card post-render child traversal from:
     - `scenes/combat.gd:731-749`
     - `scenes/map_explore.gd:388-406`

2. Low-risk cleanup candidate
   - Continue shrinking high-count direct-lookup scenes:
     - `main_menu.gd`
     - `run_end.gd`
     - `stage_transition.gd`
     - `node_resolve.gd`

3. Guarded-only
   - Do not remove `node_resolve.gd` based on this report alone.
   - That still needs a flow/state-machine audit decision, not a scene cleanup pass.

4. Optional lifecycle polish
   - Normalize tween/timer cleanup style in `main.gd` and `safe_menu_overlay.gd` if future shutdown/transition noise appears.

## Validation

Expected for this report pass:
- `py -3 Tools/validate_architecture_guards.py`

No scene script, `.tscn`, or authority doc was modified as part of this audit.
