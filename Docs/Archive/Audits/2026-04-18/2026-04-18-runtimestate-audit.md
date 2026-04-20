# RuntimeState Audit - 2026-04-18

Status: report-only
Method: static analysis plus grep/rg only
Code changes: none
Authority:
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`

## Scope

Audited files:
- `Game/RuntimeState/run_state.gd` - 245 lines
- `Game/RuntimeState/inventory_state.gd` - 1061 lines
- `Game/RuntimeState/map_runtime_state.gd` - 2398 lines / 146 functions
- `Game/RuntimeState/character_perk_state.gd` - 99 lines
- `Game/RuntimeState/support_interaction_state.gd` - 977 lines
- `Game/RuntimeState/combat_state.gd` - 596 lines
- `Game/RuntimeState/event_state.gd` - 216 lines
- `Game/RuntimeState/reward_state.gd` - 223 lines
- `Game/RuntimeState/level_up_state.gd` - 70 lines
- `Game/RuntimeState/map_runtime_graph_codec.gd` - 111 lines

Limitations:
- This pass is grep-based and static-analysis only.
- "Unused" means "no repo caller found with grep" and does not prove reflective invocation is impossible.
- The prompt baseline says `map_runtime_state.gd` is 2397 lines; current measured file is 2398.

## Executive Summary

Confirmed:
- `RunState` compatibility accessors are mostly dead as code surfaces. Live repo code reads `InventoryState`, `MapRuntimeState`, or `CombatState` directly rather than `RunState.weapon_instance`, `RunState.armor_instance`, `RunState.belt_instance`, `RunState.consumable_slots`, or `RunState.passive_slots`.
- `InventoryState.consumable_slots` and `InventoryState.passive_slots` no longer do unconditional `O(n)` scans on every getter read. The versioned cache pass is live.
- `MapRuntimeState` remains the largest RuntimeState owner and still mixes truth-heavy runtime behavior with legacy alias/helper surfaces.

Confirmed major drift:
- `Docs/SAVE_SCHEMA.md` still says current `MapRuntimeState` save payload includes pending node identity/type.
- Runtime save does not write `pending_node_id` or `pending_node_type` from `MapRuntimeState.to_save_dict()`.
- Pending-node continuity is currently written by `RunSessionCoordinator.get_app_state_save_data()`, and `SaveService` explicitly rejects those fields inside `run_state_data`.

Likely-safe but structurally noisy:
- Hamlet/side-quest fields exist in both `MapRuntimeState` and `SupportInteractionState`, but current code reads like a phase split, not confirmed competing ownership.

## Findings

### F1 - SAVE_SCHEMA documents `pending_node_*` under map runtime save payload, but runtime save does not emit those fields

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for fixing:
  - doc-only fix: low-risk fast lane
  - owner/shape change: high-risk escalate-first

Evidence:
- `Game/RuntimeState/map_runtime_state.gd` writes:
  - `active_map_template_id`
  - `current_node_index`
  - `current_node_id`
  - `stage_key_resolved`
  - `boss_gate_unlocked`
  - `roadside_encounters_this_stage`
  - `map_realized_graph`
  - `map_node_states`
  - `support_node_states`
  - `side_mission_node_states`
- It does not write `pending_node_id` or `pending_node_type`.
- `Game/Application/run_session_coordinator.gd` writes `pending_node_id` and `pending_node_type` under `app_state`.
- `Game/Infrastructure/save_service.gd` rejects `pending_node_id` / `pending_node_type` inside `run_state_data` as `unexpected_pending_node_id` / `unexpected_pending_node_type`.
- `Docs/SAVE_SCHEMA.md` still claims current `MapRuntimeState` save payload covers pending node identity/type.

Impact:
- This is confirmed doc drift, not a confirmed runtime bug.
- A future cleanup could mis-route pending-node continuity if someone trusts `SAVE_SCHEMA.md` literally and moves those fields into the wrong owner payload.

Recommendation:
- Update `Docs/SAVE_SCHEMA.md` so it says pending-node continuity currently lives in `RunSessionCoordinator.app_state`, not `MapRuntimeState.to_save_dict()`.

### F2 - `RunState` compatibility accessors are largely unused externally

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: high-risk escalate-first if compatibility removal is attempted

Evidence:
- `Game/RuntimeState/run_state.gd` still exposes compatibility accessors for:
  - `current_node_index`
  - `weapon_instance`
  - `armor_instance`
  - `belt_instance`
  - `consumable_slots`
  - `passive_slots`
- Repo grep found no confirmed external property callers of:
  - `run_state.weapon_instance`
  - `run_state.armor_instance`
  - `run_state.belt_instance`
  - `run_state.consumable_slots`
  - `run_state.passive_slots`
- `run_state.current_node_index` also has zero confirmed external property callers.
- `current_node_index` still survives as a save/load compatibility field, so the field is used even though the property API appears dead.

Recommendation:
- Keep these accessors for now.
- If cleanup is attempted later, treat it as compatibility-removal work, not a low-risk refactor.

### F3 - Hamlet / side-quest state shape exists in two RuntimeState owners

- Severity: Medium
- Confidence: Likely
- AGENTS risk lane estimate for cleanup:
  - medium-risk guarded lane if only documentation/bridge clarity changes
  - high-risk escalate-first if owner meaning changes

Evidence:
- `MapRuntimeState` owns `_side_mission_node_states` and persists:
  - `mission_definition_id`
  - `mission_type`
  - `mission_status`
  - `target_node_id`
  - `target_enemy_definition_id`
  - `quest_item_definition_id`
  - `reward_offers`
- `SupportInteractionState` also carries:
  - `mission_definition_id`
  - `mission_type`
  - `mission_status`
  - `target_node_id`
  - `target_enemy_definition_id`
  - `quest_item_definition_id`
  - `reward_offers`
- The bridge is explicit:
  - `SupportInteractionState.build_persisted_node_state()`
  - `RunSessionCoordinator` then calls `MapRuntimeState.save_side_quest_node_runtime_state(...)`

Interpretation:
- `Docs/SOURCE_OF_TRUTH.md` says `MapRuntimeState` owns hamlet side-quest truth and `SupportInteractionState` owns only pending support-visit choice state.
- Current code is consistent with that interpretation, but the shared field shape creates owner-drift risk.

Recommendation:
- Do not rename or move this yet.
- If cleanup starts later, document the phase split first, then reduce duplicated shape.

### F4 - `InventoryState` fixed the old getter hotspot, but now returns cached arrays by reference

- Severity: Minor
- Confidence: Likely
- AGENTS risk lane estimate for cleanup: medium-risk guarded lane

Evidence:
- `Game/RuntimeState/inventory_state.gd` now caches `consumable_slots` and `passive_slots` behind `_inventory_version`.
- Those getters no longer rescan `inventory_slots` every read.
- The getters return the cached arrays directly rather than returning a duplicate.

Impact:
- This is a valid performance improvement.
- But in-place mutation of returned arrays or contained dictionaries can bypass `_inventory_version` discipline.
- No confirmed production bug was found from current runtime callers; most live callers read or duplicate.

Recommendation:
- Keep current cache.
- If bugs appear around stale slot views, audit in-place mutation sites before changing owner semantics.

### F5 - Several RuntimeState helpers are test-only or appear dead

- Severity: Minor
- Confidence: Confirmed for grep reachability; reflective/dynamic-call uncertainty remains
- AGENTS risk lane estimate:
  - clearly dead generic helpers: low-risk fast lane
  - legacy alias removal: medium-risk guarded lane or higher

See detailed tables in sections 6 and 7.

## 1) Compatibility Accessor Map

Audit target here is the `RunState` compatibility-mirror surface. `InventoryState` compatibility views are noted later as legacy naming, but ownership remains on `InventoryState`.

| Accessor | Direct external property reads | Direct external property writes | Used / Unused / Ambiguous | Confidence | Notes |
|---|---:|---:|---|---|---|
| `current_node_index` | 0 | 0 | Used | Confirmed | Property API appears dead, but save/load compatibility still uses the field through `SaveService`, `MapRuntimeState.load_from_save_dict()`, `RewardState`, and tests. |
| `weapon_instance` | 0 | 0 | Unused | Confirmed | Live repo reads now go through `InventoryState.weapon_instance` or `CombatState.weapon_instance`. |
| `armor_instance` | 0 | 0 | Unused | Confirmed | Same pattern as `weapon_instance`. |
| `belt_instance` | 0 | 0 | Unused | Confirmed | Same pattern as `weapon_instance`. |
| `consumable_slots` | 0 | 0 | Unused | Confirmed | Live repo reads now use `InventoryState.consumable_slots` or `CombatState.consumable_slots`. |
| `passive_slots` | 0 | 0 | Unused | Confirmed | Live repo reads now use `InventoryState.passive_slots`. |

Red-flag write callers:
- None confirmed outside the compatibility setter bodies in `RunState` itself.

Interpretation:
- The repo has already mostly migrated away from `RunState` compatibility accessors.
- `current_node_index` is the only accessor with confirmed ongoing value, and even there the value survives mainly as save/schema baggage rather than an active code API.

## 2) Save Schema Drift

| Area | Runtime surface | SAVE_SCHEMA status | Finding |
|---|---|---|---|
| `RunState` scalar save | `player_hp`, `hunger`, `xp`, `current_level`, `stage_index`, `gold`, `run_seed`, `rng_stream_states`, `character_perk_state` | Matches | No confirmed drift |
| `InventoryState` schema-8 save | `backpack_slots`, `inventory_next_slot_id`, `equipped_right_hand_slot`, `equipped_left_hand_slot`, `equipped_armor_slot`, `equipped_belt_slot` | Matches | No confirmed drift |
| `InventoryState` legacy load | `inventory_slots`, `active_weapon_slot_id`, `active_armor_slot_id`, `active_belt_slot_id`, `weapon_instance`, `armor_instance`, `belt_instance`, `consumable_slots`, `passive_slots` | Matches | No confirmed drift |
| `MapRuntimeState` main save | `active_map_template_id`, `map_realized_graph`, `current_node_id`, `current_node_index`, `map_node_states`, `stage_key_resolved`, `boss_gate_unlocked`, `support_node_states`, `side_mission_node_states`, `roadside_encounters_this_stage` | Matches except pending-node docs | See F1 |
| `MapRuntimeState` pending node continuity | `load_from_save_dict()` can read `pending_node_id` / `pending_node_type` | Mismatch | Docs say current map save payload covers them; runtime owner save does not write them |
| `SupportInteractionState` save | `support_type`, `source_node_id`, `title_text`, `summary_text`, `offers`, `blacksmith_view_mode`, `blacksmith_target_page`, mission fields, `reward_offers` | Matches | No confirmed drift |
| `CharacterPerkState` save | `owned_perk_ids` | Matches | No confirmed drift |
| `RewardState` save | `source_context`, `title_text`, `offers` | Matches contract intent | No confirmed drift |
| `LevelUpState` save | `source_context`, `current_level`, `target_level`, `offers` | Matches contract intent | No confirmed drift |
| `EventState` save | `template_definition_id`, `source_node_id`, `source_context`, `title_text`, `summary_text`, `choices` | Safe-state excluded by design | Not a drift; unsupported-save policy is intentional |

No confirmed `Critical` save drift was found.

## 3) Ownership Overlap

### Confirmed owner mapping

- `RunState` owns run-level scalars and delegates map/inventory/perk persistence to closer owners.
- `InventoryState` owns backpack/equipment truth.
- `MapRuntimeState` owns node graph, node state, key/boss gate, support revisit, roadside quota, and hamlet side-quest node truth.
- `SupportInteractionState` owns the currently open support-visit pending choice state.
- `CharacterPerkState` owns run-long perk truth.

### Overlap review

| Data shape | Owners carrying similar fields | Confirmed / Likely / Unclear | Interpretation |
|---|---|---|---|
| `current_node_index` | `RunState` compat accessor, `MapRuntimeState` compat mirror, save payload field | Confirmed | Compatibility mirror only; owner is still `MapRuntimeState.current_node_id` |
| `weapon_instance` / `armor_instance` / `belt_instance` / `consumable_slots` / `passive_slots` | `RunState` compat accessors, `InventoryState` owner, `CombatState` combat-local projection | Confirmed | Phase split plus compatibility, not confirmed double ownership |
| hamlet mission fields | `MapRuntimeState._side_mission_node_states`, `SupportInteractionState` mission fields | Likely | Pending-visit projection over a node-local owner, but field duplication is large |
| reward offer lists | `RewardState.offers`, `SupportInteractionState.reward_offers`, `MapRuntimeState` side-quest persisted state | Likely | Different flows, but same generic `Array[Dictionary]` shape makes accidental owner drift easier |

## 4) Getter Complexity

### Confirmed hotspot fix already live

- `InventoryState.consumable_slots`
- `InventoryState.passive_slots`

Current state:
- They invalidate against `_inventory_version`.
- They no longer do unconditional linear scans on every getter read.

### Remaining linear or allocating getters

| File | Surface | Cost | Confidence | Notes |
|---|---|---|---|---|
| `map_runtime_state.gd` | `get_discovered_adjacent_node_ids()` | linear over adjacency list | Confirmed | Fine at current node counts |
| `map_runtime_state.gd` | `get_frontier_fog_count()` | linear over node graph | Confirmed | Current graph is still small |
| `map_runtime_state.gd` | `get_discovered_node_count()` | linear over node graph | Confirmed | Used by presenters |
| `map_runtime_state.gd` | `get_resolved_node_count()` | linear over node graph | Confirmed | Used by presenters |
| `map_runtime_state.gd` | `get_support_node_runtime_state()` | duplicate allocates | Confirmed | Returns defensive copy |
| `map_runtime_state.gd` | `get_side_quest_node_runtime_state()` / `get_side_mission_node_runtime_state()` | duplicate allocates | Confirmed | Defensive copy; alias noise remains |
| `character_perk_state.gd` | `get_owned_perk_ids()` | duplicate allocates | Confirmed | Small array today |
| `event_state.gd` | `get_choice_by_id()` | linear scan plus duplicate | Confirmed | Small fixed choice list |
| `reward_state.gd` | `get_offer_by_id()` | linear scan plus duplicate | Confirmed | Small fixed offer list |
| `level_up_state.gd` | `get_offer_by_id()` | linear scan plus duplicate | Confirmed | Small fixed offer list |
| `support_interaction_state.gd` | `get_offer_by_id()` / `has_available_offers()` | linear scan | Confirmed | Small offer windows |

Conclusion:
- No current critical getter-complexity bug was found inside RuntimeState.
- The old `InventoryState` slot-family getter hotspot has already been addressed.

## 5) Legacy Naming

| Legacy name | Where found | Classification | Confirmed / Likely / Unclear | Notes |
|---|---|---|---|---|
| `side_mission_*` | `map_runtime_state.gd`, `support_interaction_state.gd`, `SAVE_SCHEMA.md`, `SUPPORT_INTERACTION_CONTRACT.md` | Save-compat / legacy runtime naming | Confirmed | Current live node family is `hamlet`; legacy naming remains for persistence/helper compatibility |
| `LEGACY_NODE_FAMILY_SIDE_MISSION` | `map_runtime_state.gd` | Save/load compat | Confirmed | Load normalizes legacy node family to `hamlet` |
| `armor_instance` | `run_state.gd`, `inventory_state.gd`, `combat_state.gd`, `SAVE_SCHEMA.md` | Save-compat accessor naming | Confirmed | Canonical truth is explicit equipment-slot dictionaries |
| `belt_instance` | `run_state.gd`, `inventory_state.gd`, `combat_state.gd`, `SAVE_SCHEMA.md` | Save-compat accessor naming | Confirmed | Same as `armor_instance` |
| `weapon_instance` | `run_state.gd`, `inventory_state.gd`, `combat_state.gd` | Compatibility naming, not owner rename | Confirmed | Canonical truth is explicit right-hand equipment slot |
| `consumable_slots` / `passive_slots` | `run_state.gd`, `inventory_state.gd`, docs | Compatibility naming | Confirmed | Canonical truth is backpack slot array |
| `brace` | RuntimeState files | Not found | Confirmed | No RuntimeState legacy `brace` residue found |
| `node_resolve` | RuntimeState files | Not found | Confirmed | `NodeResolve` exists in flow/UI layer, not RuntimeState |

Classification note:
- None of the RuntimeState legacy names above read like a stable-ID rename task.
- They are compatibility/save-shape naming, not content-stable-ID naming.

## 6) Dead Field / Uncalled Helper

### Confirmed zero-caller or test-only surfaces

| Surface | Status | Confirmed / Likely / Unclear | Notes | AGENTS lane estimate |
|---|---|---|---|---|
| `CharacterPerkState.has_perk()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `CharacterPerkState.resolve_legacy_perk_definition_id()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `CombatState.apply_inventory_projection()` | Unused | Confirmed | No repo callers found | medium-risk guarded lane |
| `CombatState.has_boss_phases()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `CombatState.get_current_boss_phase()` | Unused | Confirmed | No repo callers found | medium-risk guarded lane |
| `CombatState.boss_phase_definitions` | Unused | Confirmed | No non-self callers found | medium-risk guarded lane |
| `CombatState.boss_phase_index` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `CombatState.inventory_slot_order` | Unused | Confirmed | No repo callers found | medium-risk guarded lane |
| `CombatState.owned_character_perk_ids` | Unused | Confirmed | No repo callers found | medium-risk guarded lane |
| `InventoryState.set_right_hand_instance()` | Unused | Confirmed | No repo callers found; setter still used indirectly via property | medium-risk guarded lane |
| `InventoryState.can_store_unequipped_slot()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `InventoryState.get_slot_by_id()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `InventoryState.find_first_slot_index_by_family()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `InventoryState.build_inventory_slot_snapshot()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `InventoryState.slot_matches_family()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `InventoryState.slot_can_equip_to()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `InventoryState.right_hand_instance` | Unused | Confirmed | No external property callers found | medium-risk guarded lane |
| `MapRuntimeState.get_node_count()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.get_stage_key_node_id()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.get_boss_node_id()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.get_frontier_fog_count()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.is_node_discovered()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `MapRuntimeState.is_node_locked()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `MapRuntimeState.is_node_resolved()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `MapRuntimeState.is_support_node()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `MapRuntimeState.is_hamlet_node()` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `MapRuntimeState.is_side_mission_node()` | Unused | Confirmed | Legacy alias candidate | medium-risk guarded lane |
| `MapRuntimeState.get_hamlet_personality()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.get_roadside_encounters_this_stage()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.get_side_mission_node_runtime_state()` | Test-only | Confirmed | Legacy alias beside `side_quest` naming | medium-risk guarded lane |
| `MapRuntimeState.save_side_mission_node_runtime_state()` | Test-only | Confirmed | Legacy alias beside `side_quest` naming | medium-risk guarded lane |
| `MapRuntimeState.list_eligible_side_mission_target_node_ids()` | Unused | Confirmed | Legacy alias candidate | medium-risk guarded lane |
| `MapRuntimeState.get_side_mission_target_enemy_definition_id()` | Unused | Confirmed | Legacy alias candidate | medium-risk guarded lane |
| `MapRuntimeState.mark_side_mission_target_completed()` | Unused | Confirmed | Legacy alias candidate | medium-risk guarded lane |
| `MapRuntimeState.build_side_mission_highlight_snapshot()` | Test-only | Confirmed | Legacy alias candidate | medium-risk guarded lane |
| `MapRuntimeState.build_family_budget_slot_snapshot()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |
| `MapRuntimeState.roadside_encounters_this_stage` | Test-only | Confirmed | Read directly only in tests; runtime logic uses internal methods | low-risk fast lane |
| `RewardState.generation_context` | Unused | Confirmed | No repo callers found | low-risk fast lane |
| `RunState.configure_run_seed()` | Test-only | Confirmed | Only test callers found | low-risk fast lane |

### Ambiguity note

This is grep-based reachability, not reflective-call proof. I found no evidence of reflective or string-driven invocation for the helpers above, but grep cannot rule that out absolutely.

## 7) Accessor / Field Classification Snapshot

Required by prompt: every audited compatibility accessor/field below has a status.

| Field / accessor | Classification | Why |
|---|---|---|
| `RunState.current_node_index` | Used | Save/load compatibility field still active even though direct property callers are absent |
| `RunState.weapon_instance` | Unused | No confirmed external property callers |
| `RunState.armor_instance` | Unused | No confirmed external property callers |
| `RunState.belt_instance` | Unused | No confirmed external property callers |
| `RunState.consumable_slots` | Unused | No confirmed external property callers |
| `RunState.passive_slots` | Unused | No confirmed external property callers |
| `MapRuntimeState side_mission_* aliases` | Ambiguous | Legacy alias surface exists; some members are test-only, some unused, cleanup risk is higher than simple grep suggests |
| `InventoryState family-slot cached getters` | Used | Live presenters and inventory flows still read them; hotspot fix is already live |

## Recommendations

1. Doc-only fix first
   - Fix `Docs/SAVE_SCHEMA.md` pending-node wording.
   - This is the cleanest confirmed drift.

2. Low-risk cleanup candidates
   - `InventoryState.build_inventory_slot_snapshot()`
   - `InventoryState.slot_matches_family()`
   - `InventoryState.get_slot_by_id()`
   - `InventoryState.find_first_slot_index_by_family()`
   - clearly test-only `MapRuntimeState` query helpers if they are not intended public API

3. Guarded cleanup candidates
   - `side_mission_*` alias review in `MapRuntimeState`
   - support/hamlet field-shape overlap audit between `MapRuntimeState` and `SupportInteractionState`
   - `CombatState` dead-surface review for boss-phase and inventory-order leftovers

4. Do not fast-lane
   - removing `RunState` compatibility accessors
   - changing `side_mission_*` persistence field names
   - moving hamlet ownership out of `MapRuntimeState`
   - changing save payload field ownership

## Validation

Expected for this report pass:
- `py -3 Tools/validate_architecture_guards.py`

No `.gd` files were modified as part of this audit.
