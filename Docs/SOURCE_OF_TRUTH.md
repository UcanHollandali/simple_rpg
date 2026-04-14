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
| current node id, discovery state, resolved state, locked state, pending node context, stage key state, boss-gate state, support-node revisit state, side-mission contract state | `MapRuntimeState` | runtime graph materialized from stage-scaffold rotation `procedural_stage_corridor_v1.json` / `procedural_stage_openfield_v1.json` / `procedural_stage_loop_v1.json`; legacy fixed templates remain load-compat only |
| shared carried inventory slots, carried-slot order, plus out-of-combat active equipped weapon / armor / belt slot ids | `InventoryState` | starter recipe comes from `ContentDefinitions/RunLoadouts/starter_loadout.json`; all carried item families now live in one shared inventory pool |
| combat turn state, enemy HP, revealed intent, boss phase tracking, combat-only statuses, combat-local hunger/HP/durability mutation, combat-local equipped weapon / armor / belt slot selection | `CombatState` | committed back to `RunState` at combat end; boss phase truth stays combat-local only |
| combat setup selection and post-combat/post-node progression routing | `RunSessionCoordinator` | orchestration owner, not long-lived state owner |
| pending event choice state | `EventState` | created, applied, and cleared by `RunSessionCoordinator`; current authored choices come from `ContentDefinitions/EventTemplates/*.json` |
| pending reward offer list | `RewardState` | created, applied, and cleared by `RunSessionCoordinator` |
| pending level-up offer list | `LevelUpState` | passive offer window currently follows explicit top-level `authoring_order` on `PassiveItems` |
| pending support visit offer list | `SupportInteractionState` | merchant stock reads the deterministic stage-indexed authored stock table (`basic_merchant_stock.json`, `stage_2_merchant_stock.json`, `stage_3_merchant_stock.json`); rest offers remain narrow runtime-owned slices; blacksmith offers are runtime-owned service and target-selection slices over carried weapon / armor items plus active-weapon repair; side-mission offer state carries the current contract status, marked target, and claim offers while `SupportInteraction` is open |
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
  - `inventory_slots`
  - carried slot order inside `inventory_slots`
  - `active_weapon_slot_id`
  - `active_armor_slot_id`
  - `active_belt_slot_id`
- `weapon_instance`, `armor_instance`, `belt_instance`, `consumable_slots`, and `passive_slots` remain compatibility views over that shared owner.
- `armor_instance` and `belt_instance` are still active equipped lanes.
- Current truthful active-lane behavior:
  - `armor_instance` supplies passive combat-defense modifiers
  - `belt_instance` supplies passive combat-utility modifiers
  - equipped belt also adds `+2` shared inventory capacity
  - starter runs still begin with both empty
- Shared carried-inventory baseline:
  - base capacity: `5`
  - equipped belt bonus: `+2`
  - carried families share the same pool:
    - `weapon`
    - `armor`
    - `belt`
    - `consumable`
    - `passive`
- Current schema-compatible instance fields stay narrow:
  - `definition_id`
  - `current_durability` on weapon slots
  - `upgrade_level` on weapon and armor slots
  - `current_stack` on consumable slots
- Do not treat the compatibility accessors as a second owner; the shared `inventory_slots` array is the actual runtime truth.
- `InventoryActions` is the mutation surface, not a competing owner.
- Current narrow mutation surface over that owner includes:
  - equip / unequip toggle for carried `weapon`, `armor`, and `belt`
  - carried-slot reorder
  - direct out-of-combat consumable use
- `RunState` still exposes compatibility accessors for limited compatibility-focused tests and save/load compatibility lanes.
- During active combat, `CombatState` temporarily owns the active equipped weapon / armor / belt slot ids so combat-time gear swaps can stay combat-local until the combat result is committed.

### Map

- `MapRuntimeState` owns the stage-local exploration graph and all per-node runtime state.
- The current graph is scaffold-based and procedurally filled, but that does not make the content template the runtime owner.
- `RunSessionCoordinator` may:
  - validate adjacency-limited movement
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
  - level-up ordering: `PassiveItems` `authoring_order`
  - merchant stock: stage-indexed `MerchantStocks/basic_merchant_stock.json`, `MerchantStocks/stage_2_merchant_stock.json`, `MerchantStocks/stage_3_merchant_stock.json`

### Combat

- `CombatState` owns combat-local truth.
- `CombatFlow` drives combat-local resolution and presentation signals.
- `RunState.commit_combat_result()` is the handoff path back to long-lived run truth.
- Combat-time equipment swaps use shared carried inventory as input, but the selected active weapon / armor / belt slot ids remain combat-local until `RunState.commit_combat_result()` writes them back.
- Combat-only statuses do not survive combat unless a closer rule contract explicitly changes that.

## Save Rule

Save snapshots must be built from the owners that actually exist today.

Current implemented baseline:
- flow state from `GameFlowManager`
- run truth from `RunState`
- map truth from `MapRuntimeState`, serialized through `RunState.to_save_dict()`
- side-mission node truth from `MapRuntimeState`, serialized through `RunState.to_save_dict()`
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
