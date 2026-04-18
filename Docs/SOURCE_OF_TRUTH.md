# SIMPLE RPG - Source of Truth

## Purpose

This file answers one question only:

`Who owns this value right now?`

If the owner changes later, update this file in the same patch as the code.

## Core Rule

Every critical value has one authoritative owner.
Derived data, cached data, facade reads, and UI view state do not replace that owner.

## Compatibility Facade Rule

- `RunState` compatibility accessors are transitional read surfaces, not ownership transfers.
- `AppBootstrap` is an autoload facade, not the hidden owner of gameplay truth.
- If a closer runtime owner already exists, new scene/UI/test work should prefer that owner or a narrow Application-owned surface.

## Ownership Table

| Data | Authoritative owner now | Notes |
|---|---|---|
| active flow state | `GameFlowManager` | reached through `AppBootstrap` only as a facade |
| run result, stage index, hunger, XP, gold, outside-combat HP, run seed, named RNG stream cursors | `RunState` | stable run-level scalars plus live deterministic stream continuity |
| current node id, discovery state, resolved state, locked state, pending node context, stage key state, boss-gate state, support-node revisit state, hamlet side-quest state | `MapRuntimeState` | runtime graph materialized from the active procedural stage-profile ids using center-start frontier growth plus controlled reconnect; legacy fixed templates remain load-compat only |
| backpack slots and order, plus explicit equipment slots for right hand / left hand / armor / belt | `InventoryState` | starter recipe comes from `ContentDefinitions/RunLoadouts/starter_loadout.json`; equipped gear no longer consumes backpack capacity |
| combat turn state, enemy HP, revealed intent, boss phase tracking, combat-only statuses, combat-local hunger/HP/durability mutation, combat-local guard, and combat-local interpretation of right-hand / left-hand / armor / belt loadout | `CombatState` | committed back to `RunState` at combat end; left-hand shield/offhand behavior and guard truth now live here; boss phase truth stays combat-local only |
| combat setup selection and post-combat/post-node progression routing | `RunSessionCoordinator` | orchestration owner, not long-lived state owner |
| pending event choice state | `EventState` | created, applied, and cleared by `RunSessionCoordinator`; current authored choices come from `ContentDefinitions/EventTemplates/*.json` |
| pending reward offer list | `RewardState` | created, applied, and cleared by `RunSessionCoordinator` |
| owned character perks | `CharacterPerkState` serialized through `RunState` | run-local progression bonuses loaded from `CharacterPerks`; not inventory items |
| pending level-up offer list | `LevelUpState` | perk offer window currently follows explicit top-level `authoring_order` on `CharacterPerks` |
| pending support visit offer list | `SupportInteractionState` | merchant stock reads deterministic run-seeded stage-local authored stock pools (`basic_merchant_stock.json`, `stage_1_merchant_stock_roadpack.json`, `stage_1_merchant_stock_scout.json`, `stage_2_merchant_stock.json`, `stage_2_merchant_stock_kit.json`, `stage_2_merchant_stock_forgegear.json`, `stage_3_merchant_stock.json`, `stage_3_merchant_stock_bulwark.json`, `stage_3_merchant_stock_convoy.json`); rest offers remain narrow runtime-owned slices; blacksmith offers are runtime-owned service and target-selection slices over carried weapon / armor items plus active-weapon repair; hamlet offer state carries the current stage-local authored request definition, side-quest status, marked target, optional quest-item hook, and claim offers while `SupportInteraction` is open |
| content metadata and rule blocks | `ContentDefinitions/*` | definitions are logic input, never runtime owner replacement |
| save snapshot assembly and restore orchestration | `SaveRuntimeBridge` | delegates file IO and schema validation to `SaveService` |
| file IO and save-path policy | `SaveService` | infrastructure owner only |
| UI hover, tab, panel, and animation state | UI layer | never gameplay truth |

## Current Implemented Surfaces

### App Facade

- `AppBootstrap` is the public autoload entry point for scenes.
- `AppBootstrap` does not own flow, inventory, reward, map, or save truth.
- `RunSessionCoordinator` owns the active application-side orchestration for:
  - combat setup
  - node movement resolution
  - event resolution
  - reward resolution
  - level-up resolution
  - support interaction resolution
- `SaveRuntimeBridge` owns snapshot build/restore orchestration.

### Inventory

- `InventoryState` owns:
  - `inventory_slots` as backpack truth
  - backpack slot order inside `inventory_slots`
  - `equipped_right_hand_slot`
  - `equipped_left_hand_slot`
  - `equipped_armor_slot`
  - `equipped_belt_slot`
- Current canonical inventory model:
  - equipment slots do not consume backpack capacity
  - base backpack capacity: `5`
  - equipped belt bonus comes from authored `Belts.rules.backpack_capacity_bonus`
  - backpack may carry:
    - `weapon`
    - `shield`
    - `armor`
    - `belt`
    - `consumable`
    - `passive`
    - `quest_item`
    - `shield_attachment`
- Shield attachments are stored as backpack items when detached and as `attachment_definition_id` on shield slot state when attached.
- Passive items are backpack-carried truth, not equipped-slot truth.
- Character perks are not inventory truth and do not consume backpack capacity.
- `weapon_instance`, `right_hand_instance`, `left_hand_instance`, `armor_instance`, `belt_instance`, `consumable_slots`, `passive_slots`, `active_weapon_slot_id`, `active_left_hand_slot_id`, `active_armor_slot_id`, and `active_belt_slot_id` remain compatibility views over the canonical backpack/equipment owner.
- Current schema-compatible instance fields stay narrow:
  - `definition_id`
  - `current_durability` on weapon slots
  - `upgrade_level` on weapon and armor slots
  - `current_stack` on consumable slots
- Do not treat the compatibility accessors as a second owner; canonical truth is the backpack array plus explicit equipment-slot dictionaries.
- `InventoryActions` is the mutation surface, not a competing owner.
- Current narrow mutation surface over that owner includes:
  - move carried gear between backpack and explicit equipment slots
  - backpack reorder
  - attach/detach one shield attachment on the equipped left-hand shield outside combat
  - direct out-of-combat consumable use
- `RunState` still exposes compatibility accessors for limited compatibility-focused tests and save/load compatibility lanes.
- During active combat, `CombatState` temporarily owns combat-local guard plus the interpreted equipped loadout snapshot used for attack/defend resolution.
- Combat-time gear swaps and backpack reorder are no longer part of the canonical combat loop.

### Map

- `MapRuntimeState` owns the stage-local exploration graph and all per-node runtime state.
- The current graph is realized from the active controlled-scatter stage profiles, but that does not make the content template the runtime owner.
- `RunSessionCoordinator` may:
  - validate adjacency-limited movement
  - trigger a travel-scoped roadside interruption during valid movement, then continue the preserved destination flow
  - consume pending node context
  - reopen support nodes on revisit
  - route to the next flow state
- `RunState.current_node_index` is compatibility-only.

### Event / Reward / Level-Up / Support

- `EventState`, `RewardState`, `LevelUpState`, and `SupportInteractionState` own only pending choice state.
- They are created when their flow state opens and cleared when the flow state resolves.
- Current deterministic authored inputs:
  - event choices: `EventTemplates/*`
  - reward offers: `Rewards/<source_context>.json`
  - level-up ordering: `CharacterPerks` `authoring_order`
  - merchant stock: deterministic run-seeded stage-local `MerchantStocks` pools

### Combat

- `CombatState` owns combat-local truth.
- `CombatFlow` drives combat-local resolution and presentation signals.
- `RunState.commit_combat_result()` is the handoff path back to long-lived run truth.
- Combat-time combat math still reads the canonical backpack-plus-equipment owner as setup input, but the live turn-by-turn combat truth stays inside `CombatState`.
- Combat-only statuses do not survive combat unless a closer rule contract explicitly changes that.

## Save Rule

Save snapshots must be built from the owners that actually exist today.

Current implemented baseline:
- flow state from `GameFlowManager`
- run truth from `RunState`
- map truth from `MapRuntimeState`, serialized through `RunState.to_save_dict()`
- hamlet side-quest node truth from `MapRuntimeState`, serialized through `RunState.to_save_dict()`
- inventory truth from `InventoryState`, serialized through `RunState.to_save_dict()`
- pending event truth from `EventState` when `Event` is active, but current save-safe baseline intentionally excludes `Event`
- pending reward truth from `RewardState` when `Reward` is active
- pending level-up truth from `LevelUpState` when `LevelUp` is active
- pending support truth from `SupportInteractionState` when `SupportInteraction` is active
- application continuity from `RunSessionCoordinator.get_app_state_save_data()`
- snapshot assembly and restore via `SaveRuntimeBridge`
- file IO and baseline snapshot validation via `SaveService`

## Forbidden Patterns

- gameplay truth owned by scene scripts or UI widgets
- display text used as a logic key
- static definitions mutated as runtime state
- duplicate authoritative inventory lists
- save data built from presentation state
- moving ownership into `RunState` or `AppBootstrap` just because compatibility access exists
