# SIMPLE RPG - Source of Truth

## Purpose

This file defines the authoritative owner for critical data.

## Core Rule

Every critical value has one authoritative owner.
Derived, cached, and view data do not replace authoritative truth.

## Ownership Table

| Data | Authoritative owner |
|---|---|
| active flow state | `Application Flow State` |
| run result, stage index, hunger, XP | `RunState` |
| current map, current node, reveal state | `MapRuntimeState` |
| inventory occupancy, equipped instances | `InventoryState` |
| item instance durability | item instance runtime state |
| combat turn, enemy HP, revealed intent, temporary combat modifiers | `CombatState` |
| pending reward choices | `RewardState` |
| pending level-up choices | `LevelUpState` |
| pending support interaction choices | `SupportInteractionState` |
| content metadata and rule blocks | content definitions |
| UI hover/tab/panel state | UI layer |

## Player HP Rule

- Outside combat, player HP lives in `RunState`.
- During combat, the active authoritative combat value lives in `CombatState`.
- When combat ends, the official result is committed back to `RunState`.
- `RunState` and `CombatState` are not parallel long-term owners of HP.

## Intent Rule

- intent generation logic belongs to Core
- current revealed intent belongs to `CombatState`
- UI only renders intent from authoritative state

## Save Rule

Save snapshots are built from authoritative runtime state, not from UI or display models.

## Forbidden Patterns

- HP owned by UI widgets
- intent inferred from icons
- separate authoritative inventory lists
- current durability inside static definitions
- save data built from tooltip or screen state
