# SIMPLE RPG - Game Flow State Machine

## Purpose

This file defines the high-level flow states and allowed transitions.

## Active Flow States

- `Boot`
- `MainMenu`
- `RunSetup`
- `MapExplore`
- `NodeResolve`
- `Combat`
- `Event`
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Only one main flow state is active at a time.

## Main Principles

- state comes first, screen comes second
- UI reflects flow state; UI does not create flow state
- adjacency traversal, fog reveal, and revisit decisions stay inside `MapExplore`
- reward does not resolve inside combat
- pending choices are real runtime states, not just open popups
- current `Event` flow is backed by explicit `EventState` data, not by fixed scene button assumptions
- current player-facing event read is presented as a `Roadside Encounter`, but the technical flow state and node family remain `Event` / `event`
- current `Reward` flow is backed by explicit `RewardState` data, not by fixed scene button assumptions
- current `LevelUp` flow is backed by explicit `LevelUpState` data, not by fixed scene button assumptions
- current `SupportInteraction` flow is backed by explicit `SupportInteractionState` data, not by immediate scene return behavior

## Core Transitions

- `Boot -> MainMenu`
- `MainMenu -> RunSetup`
- `RunSetup -> MapExplore`
- `MapExplore -> NodeResolve | Combat | SupportInteraction | RunEnd`
- `NodeResolve -> Event | Reward | LevelUp | SupportInteraction | StageTransition | MapExplore | RunEnd`
- `Event -> LevelUp | MapExplore | RunEnd`
- `Combat -> Reward | StageTransition | RunEnd`
- `Reward -> LevelUp | MapExplore | RunEnd`
- `LevelUp -> MapExplore`
- `SupportInteraction -> MapExplore`
- `StageTransition -> MapExplore | RunEnd`
- `RunEnd -> MainMenu | RunSetup`

## Transition Rules

- `MapExplore` owns adjacency-based movement, local reveal updates, lock checks, and revisit decisions.
- `MapExplore -> Combat` now happens directly for combat and boss nodes without passing through `NodeResolve`.
- `MapExplore -> NodeResolve` happens when the destination node has unresolved gameplay value or gating logic (event, reward, key).
- Current combat and support-node exception:
  - `combat` and `boss` now open `Combat` directly from `MapExplore`
  - `rest`, `merchant`, `blacksmith`, and `side_mission` now open `SupportInteraction` directly from `MapExplore`
  - they no longer show a separate `NodeResolve` bridge screen first
- A low-probability roadside pass is also allowed from `MapExplore` movement:
  - `choose_move_to_node` may route directly to `Event` with `source_context = roadside_encounter`
  - it reuses the dedicated `Event` state and does not create a new flow state
  - routing uses named RNG stream `roadside_encounter_rng` and is blocked by per-stage quota
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
- `RunEnd` is terminal for the active run, even if the app later returns to `MainMenu`.
- Current `NodeResolve` runtime opens `Event` for the dedicated `event` node family.
- The dedicated `event` node family now reads as a two-choice roadside encounter/story encounter in player-facing UI without renaming the technical flow state.
- Current `MapExplore` runtime opens `Combat` directly for:
  - `combat`
  - `boss`
- Current `MapExplore` runtime opens `SupportInteraction` directly for:
  - `rest`
  - `merchant`
  - `blacksmith`
  - `side_mission`
- Resolved event nodes must stay traversable without reopening `Event` or minting a second primary outcome.
- Re-entering a resolved node must not create repeat payout just because the player revisited it.
- Resolved reward nodes and cleared combat nodes must not produce repeat primary value on revisit.
- Resolved support nodes must stay traversable on revisit without reopening `SupportInteraction`.
- Resolved side-mission nodes are the current exception:
  - accepted and completed contracts may reopen `SupportInteraction`
  - claimed contracts must fall back to pure traversal
- Boss-gate lock and stage-key checks belong at the `MapExplore` / `NodeResolve` boundary; they do not require a new main flow state.
- Current `NodeResolve` runtime also resolves the stage key back into `MapExplore` while updating runtime-owned key / boss-gate truth.
- Current `Event` runtime applies exactly one authored outcome from the active `EventState` offer and then routes to:
  - `RunEnd` if the applied event outcome defeats the player
  - `LevelUp` if the applied event outcome grants enough XP to cross the current threshold
  - `MapExplore` otherwise
- Current side-mission loop keeps combat cadence unchanged:
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
- `RunSetup`
- `NodeResolve`
- `Combat`
- `Event`

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
