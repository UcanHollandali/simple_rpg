# SIMPLE RPG - Game Flow State Machine

## Purpose

This file defines the high-level flow states and allowed transitions.

## Active Flow States

- `Boot`
- `MainMenu`
- `MapExplore`
- `Combat`
- `Event`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Only one main flow state is active at a time.

## Legacy-Compat Flow State

- `NodeResolve`

`NodeResolve` remains implemented as a legacy transition-shell state.
Current repo truth:
- current runtime-backed direct-entry node families bypass it in the normal path
- generic pending-node fallback can still route `MapExplore -> NodeResolve`
- legacy-compatible pending-node restore paths can still route into it
- locked continuation decision: this live generic fallback is an explicit legacy-compat path for now, not an accidental stale branch to remove opportunistically

## Main Principles

- state comes first, screen comes second
- UI reflects flow state; UI does not create flow state
- adjacency traversal, fog reveal, and revisit decisions stay inside `MapExplore`
- reward does not resolve inside combat
- pending choices are real runtime states, not just open popups
- current `Event` flow is backed by explicit `EventState` data, not by fixed scene button assumptions
- planned map `event` nodes are currently presented to the player as `Trail Event`
- `Roadside Encounter` is reserved for the movement-triggered interruption, while the technical flow state and node family remain `Event` / `event`
- current `Reward` flow is backed by explicit `RewardState` data, not by fixed scene button assumptions
- current `LevelUp` flow is backed by explicit `LevelUpState` data, not by fixed scene button assumptions
- current `SupportInteraction` flow is backed by explicit `SupportInteractionState` data, not by immediate scene return behavior

## Core Transitions

- `Boot -> MainMenu`
- `MainMenu -> MapExplore`
- `MapExplore -> Combat | Event | Reward | SupportInteraction | RunEnd | MainMenu`
- `Event -> LevelUp | MapExplore | RunEnd`
- `Combat -> Reward | StageTransition | RunEnd`
- `Reward -> LevelUp | MapExplore | RunEnd | MainMenu`
- `LevelUp -> MapExplore | MainMenu`
- `SupportInteraction -> MapExplore | MainMenu`
- `StageTransition -> MapExplore | RunEnd | MainMenu`
- `RunEnd -> MainMenu`

## Legacy-Compat Transition

- `NodeResolve -> Event | Reward | LevelUp | SupportInteraction | StageTransition | MapExplore | RunEnd`
- `MapExplore -> NodeResolve` still exists as the generic pending-node fallback when direct-entry family routing does not claim the destination

## Transition Rules

- `MapExplore` owns adjacency-based movement, local reveal updates, lock checks, and revisit decisions.
- `MapExplore -> Event` now happens directly for:
  - the dedicated `event` node family
  - low-probability roadside encounters triggered during movement
- `MapExplore -> Reward` now happens directly for the dedicated `reward` node family.
- `MapExplore -> Combat` now happens directly for combat and boss nodes without passing through `NodeResolve`.
- Current combat and support-node exception:
  - `combat` and `boss` now open `Combat` directly from `MapExplore`
  - `rest`, `merchant`, `blacksmith`, and `hamlet` now open `SupportInteraction` directly from `MapExplore`
  - they no longer show a separate `NodeResolve` bridge screen first
- Current reward and event-node exception:
  - `event` now opens `Event` directly from `MapExplore`
  - `reward` now opens `Reward` directly from `MapExplore`
  - they no longer show a separate `NodeResolve` bridge screen first
- A low-probability roadside pass is also allowed from `MapExplore` movement:
  - `choose_move_to_node` may route directly to `Event` with `source_context = roadside_encounter`
  - it reuses the dedicated `Event` state and does not create a new flow state
  - routing uses named RNG stream `roadside_encounter_rng`, is blocked by per-stage quota, and may skip roadside-tagged templates whose optional trigger condition does not match the current run state
- Pure traversal across already resolved space may stay inside `MapExplore`; it does not require a new main flow state.
- Current zero-hunger starvation on map movement may route `MapExplore -> RunEnd` without passing through `NodeResolve`.
- `Combat` must not jump directly back into free map exploration in the current prototype.
- Current non-boss combat victory path is `Combat -> Reward`.
- Current boss victory path is:
  - `Combat -> StageTransition` on stages `1-2`
  - `Combat -> RunEnd` on stage `3`
- If an inline-drop victory path is added later, it must land with explicit state-machine, application, and test support; it is not part of the current allowed transition set.
- `Reward` must not appear before combat officially ends.
- `Event`, `LevelUp`, `Reward`, and `SupportInteraction` are separate flow states even if they use modal-style UI.
- Current save-safe screens may return directly to `MainMenu` through the in-run safe menu:
  - `MapExplore`
  - `Reward`
  - `LevelUp`
  - `SupportInteraction`
  - `StageTransition`
- This safe-menu exit path does not add a new flow state and does not change save ownership; it only routes the active save-safe state back to the menu shell.
- `RunEnd` is terminal for the active run, even if the app later returns to `MainMenu`.
- `NodeResolve` remains implemented as a legacy transition-shell state, but the current mainline runtime-backed node families do not route into it.
- Current intended compat entry is narrow:
  - direct-entry fallback for legacy `side_mission` save restoration
  - equivalent pending-node restore paths that still deserialize that legacy family
- Current generic-fallback note:
  - if direct-entry family routing does not claim a destination, runtime may still open `NodeResolve`
  - `NodeResolve -> Combat` therefore remains part of the live transition table even though normal `combat` / `boss` routing is direct
  - behavior-changing removal of that fallback requires a dedicated flow audit; prompt cleanup should only make the path explicit, not silently remove it
- The dedicated `event` node family now reads as `Trail Event` in player-facing UI, while `Roadside Encounter` is reserved for the movement-triggered interruption.
- Current `MapExplore` runtime opens `Combat` directly for:
  - `combat`
  - `boss`
- Current `MapExplore` runtime opens `Event` directly for:
  - `event`
- Current `MapExplore` runtime opens `Reward` directly for:
  - `reward`
- Current `MapExplore` runtime opens `SupportInteraction` directly for:
  - `rest`
  - `merchant`
  - `blacksmith`
  - `hamlet`
- Current technique continuity note:
  - first-pass training acquisition stays inside the existing `MapExplore -> SupportInteraction` hamlet route
  - using a technique stays inside the existing `Combat` state
  - no `Training`, `TechniqueSelect`, or equivalent new main flow state is approved
- Current hand-slot swap note:
  - hand-slot swap stays inside the existing `Combat` state
  - no `SwapMenu`, `EquipmentMenu`, or equivalent new main flow state is approved
  - a compact anchored swap tray or inline swap strip inside combat does not become a main flow state
- Future advanced enemy intent note:
  - advanced enemy intents stay inside the existing `Combat` state
  - no `EnemyPrep`, `EnemyBuff`, `EnemyStatus`, or equivalent new main flow state is approved
  - setup/pass windows, multi-hit packet resolution, enemy self-buff windows, and enemy-owned status windows are combat-local substates only
  - later implementation may add new combat-local domain events for feedback/telegraphing, but not a new main flow state
- Resolved event nodes must stay traversable without reopening `Event` or minting a second primary outcome.
- Re-entering a resolved node must not create repeat payout just because the player revisited it.
- Resolved reward nodes and cleared combat nodes must not produce repeat primary value on revisit.
- Resolved support nodes must stay traversable on revisit without reopening `SupportInteraction`.
- Resolved hamlet nodes are the current exception:
  - accepted and completed side quests may reopen `SupportInteraction`
  - claimed side quests must fall back to pure traversal
- Boss-gate lock and stage-key checks belong at the `MapExplore` movement boundary; they do not require a new main flow state.
- Current key-node runtime resolves the stage key in-place on `MapExplore` while updating runtime-owned key / boss-gate truth.
- Current `Event` runtime applies exactly one authored outcome from the active `EventState` offer and then routes to:
  - `RunEnd` if the applied event outcome defeats the player
  - `LevelUp` if the applied event outcome grants enough XP to cross the current threshold
  - `MapExplore` otherwise
- Current hamlet side-quest loop keeps combat cadence unchanged:
  - marked target victory still routes `Combat -> Reward`
  - later returning to the contract node routes `MapExplore -> SupportInteraction` for claim

## Save-Safe States

Current architectural safe-state set:
- `MapExplore`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Current implemented safe-state baseline is intentionally the same list today:
- `MapExplore`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Initial non-save-safe states:
- `Boot`
- `Combat`
- `Event`

Legacy-compat non-save-safe state:
- `NodeResolve`

## Autosave Note

Initial baseline does not include combat or event autosave.
Do not treat partial combat state or mid-event pending choice state as save-safe by default.

## UI Rule

Popups and drawers are not main flow states.

Examples:
- inventory drawer open
- tooltip open
- compare popup open

These may exist inside a main flow state without replacing it.
