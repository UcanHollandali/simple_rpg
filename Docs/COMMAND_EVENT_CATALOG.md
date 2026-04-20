# SIMPLE RPG - Command and Event Catalog

## Purpose

This file defines which command-like and event-like names are actually implemented today, and which names are only a future naming registry.

It is a reference catalog, not a rule authority.
It records implemented surface names plus reserved naming guidance, not every payload field.

Current prototype note:
- the only implemented formal generic command-style path today is `GameFlowManager.request_transition`
- prototype loop mutations currently route through explicit `AppBootstrap` / `RunSessionCoordinator` methods instead of scene-owned state writes
- reward-specific and level-up-specific domain events below are still intended names, not current runtime signals

## Implemented Surface Reference

### Formal Flow Command Surface

- `GameFlowManager.request_transition(target_state)`

### Explicit Application Action Surface (Implemented Methods)

These are implemented methods, not generic command messages:
- `AppBootstrap.choose_move_to_node`
- `AppBootstrap.resolve_pending_node`
- `AppBootstrap.resolve_combat_result`
- `AppBootstrap.choose_reward_option`
  - optional overflow-resolution args: `discard_slot_id`, `leave_item`
- `AppBootstrap.choose_level_up_option`
- `AppBootstrap.choose_support_action`
  - optional overflow-resolution arg: `discard_slot_id`
- `AppBootstrap.choose_event_option`
  - optional overflow-resolution args: `discard_slot_id`, `leave_item`
- `AppBootstrap.save_game`
- `AppBootstrap.load_game`

### Implemented Runtime Signals and Emitted Event Names

Implemented now:
- `GameFlowManager.flow_state_changed`
- `CombatFlow.combat_ended_signal`
- `CombatFlow.domain_event_emitted`
- `CombatFlow.turn_phase_resolved`

Current emitted `domain_event_emitted` names:
- `CombatStarted`
- `PlayerActionChosen`
- `EnemyIntentRevealed`
- `BossPhaseChanged`
- `DamageApplied`
- `StatusApplied`
- `StatusTicked`
- `StatusExpired`
- `DurabilityReduced`
- `WeaponBroken`
- `GuardGained`
- `GuardAbsorbed`
- `ConsumableUsed`
- `EnemyDefeated`

Current `turn_phase_resolved` phase names:
- `player_action`
- `enemy_action`
- `turn_end`

## Future Naming Registry Only

These names are reserved naming guidance only.
They are not active runtime surface, not proof of a generic command bus, and not proof that matching payload contracts already exist.

### Reserved Formal Command Family Names

#### Session and Flow

- `StartPrototypeRun`
- `ReturnToMainMenu`
- `SaveActiveRun`

#### Map and Choice

- `ChooseMoveToNode`
- `ChooseRewardChoice`
- `ChooseLevelUpChoice`
- `ChooseSupportAction`

#### Combat

- `ChooseAttack`
- `ChooseDefend`
- `ChooseUseItem`

### Reserved Event Family Names

#### Flow and Session

- `FlowStateChanged`
- `RunStarted`
- `ReturnedToMainMenu`
- `ActiveRunSaved`
- `SaveRejected`
- `NodeSelected`

#### Combat

- `CombatEnded`
- `CombatActionDeclared`
- `ActionRejected`

#### Reward and Progression

Reserved event names if the progression event layer is expanded later:
- `RewardGenerated`
- `RewardClaimed`
- `LevelUpOffered`
- `LevelUpChosen`

## Naming Rules

- commands use imperative naming
- command names should make player intent explicit
- events use happened/state-change naming
- event names should be understandable without reading UI code

## Change Sensitivity

Adding a new command family is architecture-sensitive.
Adding a new event family should be documented before it spreads across systems.
If a reserved command or event family becomes implemented, the same patch should name its real code owner here and move it into the implemented surface section.
