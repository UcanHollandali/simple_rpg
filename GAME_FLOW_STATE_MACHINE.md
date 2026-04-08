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
- `Reward`
- `LevelUp`
- `SupportInteraction`
- `StageTransition`
- `RunEnd`

Only one main flow state is active at a time.

## Main Principles

- state comes first, screen comes second
- UI reflects flow state; UI does not create flow state
- reward does not resolve inside combat
- pending choices are real runtime states, not just open popups

## Core Transitions

- `Boot -> MainMenu`
- `MainMenu -> RunSetup`
- `RunSetup -> MapExplore`
- `MapExplore -> NodeResolve`
- `NodeResolve -> Combat | Reward | LevelUp | SupportInteraction | StageTransition | MapExplore | RunEnd`
- `Combat -> Reward | RunEnd`
- `Reward -> LevelUp | MapExplore | RunEnd`
- `LevelUp -> MapExplore`
- `SupportInteraction -> MapExplore`
- `StageTransition -> MapExplore | RunEnd`
- `RunEnd -> MainMenu | RunSetup`

## Transition Rules

- `Combat` must not jump directly back into free map exploration without resolving its official exit result.
- `Reward` must not appear before combat officially ends.
- `LevelUp`, `Reward`, and `SupportInteraction` are separate flow states even if they use modal-style UI.
- `RunEnd` is terminal for the active run, even if the app later returns to `MainMenu`.

## Save-Safe States

Initial safe-state save support is limited to:
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

## Autosave Note

Initial baseline does not include combat autosave.
Do not treat partial combat state as save-safe by default.

## UI Rule

Popups and drawers are not main flow states.

Examples:
- inventory drawer open
- tooltip open
- compare popup open

These may exist inside a main flow state without replacing it.
