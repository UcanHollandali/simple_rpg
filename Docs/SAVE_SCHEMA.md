# SIMPLE RPG - Save Schema

## Purpose

This file defines what the project saves and what it deliberately does not save.

## Main Rule

Save stores authoritative runtime truth, not presentation data.

## Ownership Status Note

- Current save-sensitive truth lives in implemented owners only:
  - `GameFlowManager` for active flow state
  - `RunState` for current run-level data
  - `MapRuntimeState` for the current controlled-scatter stage-local realized graph slice, current node identity, realized graph truth, node-state truth, stage-local key / boss-gate truth, stage-local support-node local state, stage-local side-mission local state, roadside encounter quota state, and pending-node continuity, serialized through `RunState`
  - `InventoryState` for backpack slot order plus explicit equipment-slot dictionaries
  - `CombatState` for active combat-only truth
  - `EventState` for pending event offer truth during the dedicated `Event` flow
  - `RewardState` for pending reward offers and source context
  - `LevelUpState` for pending perk offers and target level
  - `SupportInteractionState` for pending support offers, support type, active support source node id, and active side-mission contract offer state when `SupportInteraction` is open
  - current blacksmith target-selection view mode and page also live here when that visit is active
  - `RunSessionCoordinator` for a few transitional orchestration fields such as `last_run_result`
- `MapRuntimeState` is now an implemented repo class; broader map-graph ownership is still later architecture.
- Current map save payload now includes stable node identity, exact realized graph payload, and per-node gameplay state for the live procedural slice.
- `save_schema_version = 8` writes the current exact-restore procedural payload, run-level deterministic stream continuity, the explicit backpack-plus-equipment inventory payload, character perk ownership, side-mission node persistence, roadside encounter quota state, and item-taxonomy fields for quest cargo plus shield attachments.
- `save_schema_version = 2` is still accepted for backward-compatible load of the pre-seeded reward baseline.
- `save_schema_version = 1` is still accepted for backward-compatible load and rebuilds the old fixed template path from `fixed_stage_cluster.json` / `fixed_stage_detour.json`.
- `save_schema_version = 6` is still accepted for backward-compatible load of the pre-perk equipment-plus-backpack baseline.
- `save_schema_version = 5` is still accepted for backward-compatible load of the earlier shared-bag inventory payload.
- Save work must therefore distinguish between current implementation truth and target save split.

## Required Metadata

- `save_schema_version`
- `content_version`
- `created_at`
- `updated_at`
- `save_type`
- optional `game_build_version`

## Versioning Rule

- `save_schema_version` tracks file structure
- `content_version` tracks gameplay content set

These are different concepts and should not be merged.

Current baseline:
- snapshots write `content_version`
- snapshots now write `content_version = prototype_content_v7`
- snapshots now write `save_schema_version = 8`
- load validation requires `content_version` to be present
- load validation rejects saves whose `content_version` does not match the current runtime baseline
- old eventless `prototype_content_v1` saves are therefore rejected instead of being silently reconstructed under the current event-node baseline
- load validation still accepts legacy `save_schema_version = 1`, `save_schema_version = 2`, `save_schema_version = 5`, `save_schema_version = 6`, and `save_schema_version = 7` snapshots for compatibility

## Stable ID Rule

Content references in save data use stable technical IDs, not display names.

## Save Scope Baseline

The architecture is save-ready from the start.
The first supported saves are safe-state saves only.

Terminology lock:
- `architectural safe-state set` means the flow states the architecture intends to keep save-safe
- `implemented safe-state baseline` means the states the current save/load code actually supports

Current repo note:
- the architectural safe-state set and the implemented safe-state baseline are intentionally the same list today
- they must still keep separate names so future drift is visible instead of implied

Current architectural safe-state set:
- `MapExplore`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Current implemented safe-state baseline:
- `MapExplore`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Not supported first:
- `Boot`
- `NodeResolve`
- `Combat`
- `Event`

Combat save is intentionally deferred until the baseline is stable.
Mid-event save is also intentionally unsupported in the current event v1 slice.

Current prototype note:
- The current playable loop now exercises `MapExplore`, `Reward`, `LevelUp`, `SupportInteraction`, `StageTransition`, and `RunEnd`.
- `EventState` now exists as explicit pending event truth, but `Event` is still outside the safe-state baseline.
- `SupportInteractionState` now exists as explicit pending support truth.
- `FlowState.is_architecturally_save_safe`, `FlowState.is_implemented_save_safe_now`, and `SaveService.is_implemented_save_safe_now` now name the split explicitly.
- The older names `FlowState.is_save_safe` and `SaveService.is_supported_save_state_now` remain compatibility aliases only.

## Persisted Runtime Areas

Current implementation owners relevant to future save work:
- active flow state
- `RunState`
- `MapRuntimeState` serialized through `RunState`
- `InventoryState` serialized through `RunState`
- `EventState`
- `RewardState`
- `LevelUpState`
- `SupportInteractionState`
- transitional `RunSessionCoordinator` fields that still affect run continuity
- `SaveRuntimeBridge` for snapshot assembly and restore orchestration
- `SaveService` for snapshot file IO and baseline validation
- RNG stream state

Target split after runtime-state expansion:
- inventory and equipment runtime state
- pending reward state if relevant
- pending level-up state if relevant
- pending support interaction state if relevant

Do not write save code as if the target split already exists.

Current baseline note:
- implemented safe-state snapshots are built only from:
  - `GameFlowManager`
  - `RunState`
  - `MapRuntimeState` serialized through `RunState`
  - `InventoryState` serialized through `RunState`
  - no `EventState` payload in the current baseline
  - `RewardState` when active
  - `LevelUpState` when active
  - `SupportInteractionState` when `SupportInteraction` is active
  - transitional `RunSessionCoordinator.last_run_result` continuity when `RunEnd` is active
- `RunEnd` restore currently depends on transitional `RunSessionCoordinator.last_run_result` continuity from `app_state`.
- `CombatState` is intentionally excluded from the baseline save file
- `EventState` is intentionally excluded from the baseline save file
- save/load attempts while `Event` is the active flow must fail with `unsupported_save_state`; the current baseline does not reconstruct mid-event choice surfaces
- current run-level seeded reward continuity is now part of the baseline snapshot through `RunState`:
  - `run_seed`
  - `rng_stream_states`
  - current truthful live stream: `reward_rng`
- Current schema-6 `RunState` inventory payload now includes:
- Current schema-7 `RunState` progression payload now also includes:
  - `character_perk_state`
  - `character_perk_state.owned_perk_ids`
- Current schema-8 `RunState` inventory payload still includes:
  - `backpack_slots`
  - `inventory_next_slot_id`
  - `equipped_right_hand_slot`
  - `equipped_left_hand_slot`
  - `equipped_armor_slot`
  - `equipped_belt_slot`
- Current schema-8 shield slot payload may also include:
  - `attachment_definition_id` on `shield` slot dictionaries
- Current schema-8 backpack slots may now also use:
  - `inventory_family = quest_item`
  - `inventory_family = shield_attachment`
- The array order of `backpack_slots` is current truthful backpack order and must survive save/load.
- Current schema-6 backpack slot entries may also carry:
  - `upgrade_level` on `weapon` and `armor` slots
- Legacy schema-1 / schema-2 / schema-5 / schema-6 payloads may still carry:
  - `inventory_slots`
  - `active_weapon_slot_id`
  - `active_armor_slot_id`
  - `active_belt_slot_id`
  - `weapon_instance`
  - `armor_instance`
  - `belt_instance`
  - `consumable_slots`
  - `passive_slots`
- Current load still accepts those legacy lane fields and hydrates the backpack-plus-equipment owner from them.
- Current schema-7 load also migrates legacy progression passives from older save shapes into `character_perk_state` and clears those migrated passives from backpack truth.
- Current `MapRuntimeState` save payload covers:
  - `active_map_template_id`
  - `map_realized_graph`
  - `current_node_id`
  - compatibility `current_node_index`
  - `map_node_states` as a compatibility/validation mirror of per-node state
  - `stage_key_resolved`
  - `boss_gate_unlocked`
  - `support_node_states`
  - `side_mission_node_states`
  - `roadside_encounters_this_stage`
  - pending node identity/type when that context exists in runtime
- `map_realized_graph` is the exact restore truth for schema-2 procedural saves; load does not rely on re-running scaffold fill from seed alone.
- Legacy schema-1 map saves still rebuild the old fixed authored adjacency graph from content under the matching `content_version` baseline.
- Current safe-state support snapshots may also carry blacksmith-local pending UI truth inside `SupportInteractionState`:
  - `blacksmith_view_mode`
  - `blacksmith_target_page`
  - those fields are runtime-owned pending-choice state, not free UI state
- Current safe-state support snapshots may also carry side-mission pending-choice truth inside `SupportInteractionState`:
  - `mission_definition_id`
  - `mission_status`
  - `target_node_id`
  - `target_enemy_definition_id`
  - `reward_offers`

## RNG Persistence

Current baseline:
- persist `run_seed` through `RunState`
- persist named stream state for live deterministic run streams such as:
  - `reward_rng`
  - `side_mission_accept`

Deferred target direction:
- persist named stream state for `map_rng`
- persist named stream state for `combat_rng`

Current prototype note:
- current map continuity is preserved through exact `map_realized_graph` restore, not through `map_rng` replay
- reward generation now consumes the run-level `reward_rng` stream and save/load preserves that stream cursor for future reward generation
- side-mission acceptance now consumes the run-level `side_mission_accept` stream and save/load preserves that stream cursor for future contract targeting
- current combat setup still does not persist a dedicated `combat_rng` stream
- save code must not invent unused RNG state; only live named streams should be written

## Must Not Be Saved

- tooltip text
- screen formatting
- hover state
- panel state
- duplicate derived summaries
- content definition copies
- display-only convenience strings that can be deterministically rebuilt from authoritative runtime state

## Invariants

Load should not silently accept broken truth.

Required invariants include:
- no duplicate authoritative ownership
- no invalid stable ID references
- no impossible flow state
- no negative durability
- no negative weapon or armor `upgrade_level`
- current node belongs to current map
- pending choice state matches current flow state

## Compatibility Rules

- stable IDs are the reference key
- the current baseline does not implement content-version migration
- missing or mismatched `content_version` is rejected during load validation
- legacy `save_schema_version = 1` files remain loadable for the old fixed-template map slice
- `save_schema_version = 2` files remain loadable for the pre-seeded reward baseline
- current `save_schema_version = 8` files require:
  - `active_map_template_id`
  - `map_realized_graph`
  - `run_seed`
  - `rng_stream_states`
  - `character_perk_state`
  - roadside encounter stream history is preserved inside `rng_stream_states` for deterministic `roadside_encounter_rng` roll replay
  - `backpack_slots`
  - `equipped_right_hand_slot`
  - `side_mission_node_states`
    - legacy-named persistence surface for current runtime-backed `hamlet` request node state
  - `roadside_encounters_this_stage`
- legacy `save_schema_version = 5` files still require:
  - `inventory_slots`
  - `active_weapon_slot_id`
- broken or missing content references should not silently map to random substitutes

## Pending Choice Rule

If a save occurs in a safe pending-choice state, the pending choice must restore as runtime state, not as UI guesswork.

Current prototype note:
- `EventState` now exists as explicit pending event truth for the dedicated `Event` flow, including a narrow `source_context` (`node_event`/`roadside_encounter`) field used by runtime copy.
- `EventState` is not part of the current safe-state save surface, so the existing mid-event unsupported save policy still applies.
- `RewardState` now exists as explicit pending reward truth
- `LevelUpState` now exists as explicit pending level-up truth
- `SupportInteractionState` now exists as explicit pending support truth
- the current safe-state baseline may still cache pending-choice titles, labels, or summaries inside those pending-choice owners when they are part of restoring the exact active choice surface
- those cached strings are allowed only inside the authoritative pending-choice runtime state; they are not separate UI-owned save data
- before safe-state save support is widened, remaining pending choice states must become explicit runtime truth rather than scene assumptions
