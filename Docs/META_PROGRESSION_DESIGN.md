# SIMPLE RPG - Meta Progression Design

## Status

This document is a design proposal only.
It is not implemented truth.
If implementation starts later, authority docs must be updated in the same patch as code.

## Purpose

Define a run-between progression model that:
- adds long-term motivation
- preserves the current preparation-first run identity
- avoids flattening difficulty with permanent raw stat inflation
- fits the current `MainMenu -> RunSetup -> MapExplore -> ... -> RunEnd` spine

## Current Truth

Certain facts from the current repo:
- The game is a `3`-stage, portrait-first, preparation-focused roguelite.
- The current active run is owned by `RunState`, `MapRuntimeState`, `InventoryState`, `CombatState`, and pending-choice states.
- Current save support is run-local safe-state save, not profile/meta save.
- `RunSetup` already exists as a main flow state, but it currently auto-advances into the run.
- Starter loadout is content-backed through `RunLoadouts/starter_loadout.json`.
- `DEFERRED_DECISIONS.md` explicitly says meta progression should be revisited only after the core loop stands on its own.

## Design Goals

Meta progression should:
- reward repeated runs without invalidating short-run tension
- increase variety before increasing permanent power
- reinforce build identity experiments already present in `EXPERIMENT_BANK.md`
- keep defeat understandable and fair
- avoid turning the game into a grind economy

Meta progression should not initially:
- add permanent HP inflation
- add permanent passive-slot inflation
- add permanent consumable-slot inflation
- bypass route, hunger, durability, or intent-reading pressure

## Proposed System

### 1. Meta Currency

Proposed currency: `Waymarks`

Theme intent:
- fragments of route knowledge, warding signs, and trail memory carried between runs
- thematically aligned with the current dark-forest wayfinder direction

Why currency exists:
- gives every failed run a small long-term outcome
- lets unlock pacing stay explicit instead of hiding progression in free giveaways

### 2. Currency Earning Rule

Recommended payout model: coarse, result-based, and hard to farm.

Proposed payout table:
- run start: `0`
- reach stage 2: `+2`
- reach stage 3: `+3`
- full clear: `+5`
- first clear bonus on a not-yet-cleared difficulty: `+3`

Optional later extension, not part of the first implementation slice:
- tiny bonus for boss kills on higher difficulties

Recommended red line:
- do not award currency per normal node, per combat, or per micro-action
- do not let retreat/farming loops become the optimal meta strategy

### 3. Permanent Unlock Types

The first meta layer should unlock `variety`, not raw account power.

#### A. Run-Start Kits

Recommended first unlock family: starter kits reusing `RunLoadouts`.

Design intent:
- each unlocked kit embodies one build hypothesis
- selection happens before the run, not mid-run

Proposed starter kits:
- `iron_wall_kit`
  - durable weapon
  - one sustain consumable
  - one defensive consumable
- `glass_edge_kit`
  - aggressive weapon
  - low sustain
  - tempo-biased opener
- `scavenger_kit`
  - flexible consumables
  - medium weapon
  - value from hold-vs-use choices
- `scrap_keeper_kit`
  - durability-friendly weapon
  - repair/sustain-biased opener

Important note:
- current `RunLoadouts` grammar is narrow
- if richer kit composition is desired later, that is a separate content/runtime widening

#### B. Content Unlock Packs

Recommended second unlock family: enable additional authored content in existing pools.

Examples:
- unlock new weapons into merchant or reward rotation
- unlock new passive items into level-up windows
- unlock new consumables into merchant stock

Why this is preferred over flat stat upgrades:
- preserves run-level decision making
- increases strategic space without invalidating early enemies
- scales better with content-driven architecture

#### C. Difficulty Modes

Recommended third unlock family: opt-in difficulty modifiers.

Base difficulty:
- `Standard` is available from the start

Unlockable difficulty modes:
- `Hard Road`
  - unlocked after first full clear
  - intended as the first post-clear challenge
- `Hollow Stomach`
  - unlocked after reaching stage 3
  - emphasizes route and hunger pressure
- `Rustbound`
  - unlocked after a durability-focused milestone
  - emphasizes durability pressure

Recommended rule:
- difficulty modes increase reward payout modestly
- difficulty modes should not be mandatory for the core progression track

### 4. Statistics Tracking

Recommended lifetime stats:
- total_runs_started
- total_runs_finished
- total_runs_cleared
- highest_stage_reached
- fastest_clear_seconds
- total_combats_won
- total_bosses_defeated
- total_enemies_defeated
- total_gold_earned
- total_waymarks_earned

Recommended profile milestones:
- first stage 1 boss clear
- first stage 2 boss clear
- first full clear
- first clear on each unlocked difficulty

These stats should support:
- unlock conditions
- simple profile summary on `MainMenu`
- later balance observation

## Proposed UX / Flow Fit

## No New Main Flow State In Phase 1

Recommendation:
- do **not** add a new `MetaProgression` main flow state in the first implementation slice

Reason:
- current flow machine already has the correct slots:
  - `MainMenu` for profile summary and unlock visibility
  - `RunSetup` for run-start kit and difficulty selection
- adding a new flow state early would widen architecture before the need is proven

### MainMenu

Proposed responsibilities:
- show current `Waymarks`
- show next unlock preview
- show highest clear / best milestone summary
- optionally expose a secondary `Progress` button only if the menu becomes crowded later

### RunSetup

Recommended evolution:
- stop being an auto-advance hold screen
- become the place where the player selects:
  - starter kit
  - unlocked difficulty mode

This keeps:
- flow surface small
- run-start choice explicit
- new-state pressure low

## Architectural Impact Analysis

### Recommended New Owners

If implemented, the clean ownership split is:

| Data | Proposed owner | Why |
|---|---|---|
| meta currency, unlocked kits, unlocked content packs, unlocked difficulty modes, lifetime stats | `MetaProgressionState` | run-independent, profile-scoped truth |
| profile save/load IO | `ProfileSaveService` | infrastructure concern, separate from run safe-state file IO |
| applying end-of-run payouts and unlock checks | `MetaProgressionApplicationPolicy` or narrow `RunSessionCoordinator` integration | application orchestration, not UI |

### What Should Not Own Meta Truth

Do not put meta progression truth in:
- `RunState`
- `AppBootstrap`
- `MainMenu` scene script
- `RunSetup` scene script

Reason:
- meta truth is not run-local
- current `RunState` already owns active run scalars and active deterministic streams
- widening it into a permanent profile bucket would blur runtime ownership

### Save Schema Impact

Recommended approach:
- keep current run safe-state snapshot separate
- add a **parallel profile save** instead of stuffing meta truth into the current run snapshot root

Proposed new file:
- `user://simple_rpg_meta_profile.json`

Proposed profile metadata:
- `profile_schema_version`
- `profile_content_version`
- `created_at`
- `updated_at`

Proposed profile payload:
- `waymarks`
- `unlocked_run_loadout_ids`
- `unlocked_definition_ids`
- `unlocked_difficulty_mode_ids`
- `lifetime_stats`
- `milestones`

Recommendation:
- do not overload current `save_schema_version` with profile-only fields if run safe-state and profile save can stay separate

Why:
- run save and profile save have different lifecycles
- run save can be deleted or overwritten without losing account progression
- profile migrations should not be coupled to pending `Reward/LevelUp/SupportInteraction` safe-state rules

### Flow State Impact

Phase 1 recommendation:
- new main flow state required: `no`

Possible later revisit:
- if `MainMenu` becomes overloaded with progression, unlock browsing, and challenge toggles, add a dedicated `MetaHub` flow state later
- that should be treated as a separate escalation item, not assumed now

### Likely Files To Change On Implementation

Runtime / application:
- `Game/RuntimeState/meta_progression_state.gd` `new`
- `Game/Infrastructure/profile_save_service.gd` `new`
- `Game/Application/meta_progression_application_policy.gd` `new`
- `Game/Application/app_bootstrap.gd`
- `Game/Application/run_session_coordinator.gd`
- `Game/Application/save_runtime_bridge.gd` only if a shared save bootstrap is needed

UI / scenes:
- `scenes/main_menu.gd`
- `scenes/run_setup.gd`
- relevant presenters under `Game/UI/`

Content:
- new `RunLoadouts/*` beyond `starter_loadout`
- likely new content family for difficulty modes or meta unlock definitions

Docs:
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md` only if flow changes
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/HANDOFF.md`

Tests:
- profile save/load tests
- unlock gating tests
- run-start kit selection tests
- difficulty unlock tests

## Recommended Scope Locks

The first implementation of meta progression should include:
- one meta currency
- 3-4 unlockable starter kits
- 2-3 unlockable difficulty modes
- a small lifetime stats table

The first implementation should exclude:
- permanent stat trees
- branching upgrade webs
- passive-slot expansion
- combat verb unlocks
- permanent armor/belt slot expansion
- meta-only currencies beyond the main one

## Implementation Plan

### Task 1. Profile Runtime And Persistence

- add `MetaProgressionState`
- add `ProfileSaveService`
- define profile schema and migration baseline
- load profile at boot
- keep run save and profile save independent

### Task 2. End-Of-Run Meta Payout And Unlock Logic

- compute `Waymarks` at `RunEnd`
- evaluate unlock milestones
- persist updated profile
- add tests for deterministic payout and unlock thresholds

### Task 3. MainMenu / RunSetup Integration

- surface profile summary on `MainMenu`
- turn `RunSetup` into actual pre-run selection
- allow only unlocked starter kits and difficulty modes
- keep current main flow state set unchanged

### Task 4. Content Gating And Regression Coverage

- gate unlockable loadouts, items, and difficulties through profile truth
- add tests for:
  - locked content inaccessible
  - unlocked content available
  - profile save/load persistence
  - run-start kit selection continuity

## Risks

### Risk: Flattened Difficulty

If meta progression gives raw permanent power, the core run loop loses clarity.

Mitigation:
- prefer unlock variety over stat inflation

### Risk: Save Coupling

If profile truth is mixed into run safe-state snapshots, migration complexity will spike.

Mitigation:
- separate profile save from run save

### Risk: MainMenu Bloat

If all meta UI lands in `MainMenu`, the entrypoint can become an admin shell.

Mitigation:
- keep profile summary compact
- move selection to `RunSetup`
- add a dedicated meta flow state only if later justified

## Recommended Decision

Recommended path:
- approve a **small, profile-based, variety-first** meta progression slice
- keep current run save separate
- reuse `RunSetup` instead of adding a new flow state
- unlock kits and challenge modes before adding permanent power

## Certain Facts Vs Proposal

Certain facts:
- current repo has no run-between meta progression
- `RunSetup` exists already
- current safe-state save is run-focused, not profile-focused
- `Meta Progression` is explicitly deferred in `DEFERRED_DECISIONS.md`

Proposal:
- add a separate profile-owned meta progression lane
- use `Waymarks` as the first meta currency
- unlock kits, content packs, and difficulty modes before adding permanent stats
- keep the first implementation inside existing `MainMenu` and `RunSetup` flow states
