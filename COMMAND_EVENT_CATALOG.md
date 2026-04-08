# SIMPLE RPG - Command and Event Catalog

## Purpose

This file defines the early official command and domain event families.

It documents the public contract shape, not every payload field.

## Command Families

### Session and Flow

- `StartPrototypeRun`
- `ReturnToMainMenu`
- `SaveActiveRun`

### Map and Choice

- `ChooseMoveToNode`
- `ChooseRewardChoice`
- `ChooseLevelUpChoice`
- `ChooseSupportAction`

### Combat

- `ChooseAttack`
- `ChooseBrace`
- `ChooseUseItem`

## Event Families

### Flow and Session

- `FlowStateChanged`
- `RunStarted`
- `ReturnedToMainMenu`
- `ActiveRunSaved`
- `SaveRejected`
- `NodeSelected`

### Combat

- `CombatStarted`
- `PlayerActionChosen`
- `EnemyIntentRevealed`
- `DamageApplied`
- `StatusApplied`
- `StatusExpired`
- `DurabilityReduced`
- `WeaponBroken`
- `EnemyDefeated`
- `CombatEnded`
- `CombatActionDeclared`
- `ActionRejected`

### Reward and Progression

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
