# SIMPLE RPG - Combat Rule Contract

## Purpose

This file defines the official combat rules and timing.

## Combat Identity

- single-target
- turn-based
- intent-visible
- minimal action set
- attrition-aware

## Player Actions

Top-level action buttons:
- `Attack`
- `Defend`
- `Use Item`

Current player-facing combat inventory rules:
- direct consumable card click is allowed and consumes the turn when the item would change HP or hunger
- gear swaps are locked during combat
- backpack reorder is locked during combat

## Turn Order

1. Turn Start Effects
2. Conditional or Threshold Checks
3. Player Action Selection
4. Player Action Resolve
5. Enemy Defeat Check
6. Enemy Action Resolve
7. Player Defeat Check
8. Turn End Effects
9. Status Cleanup
10. Combat Hunger Tick
11. Next Intent Preparation

Combat hunger officially resolves at `turn_end`.

## Damage Order

Current canonical damage order for enemy hits:
1. calculate raw damage from intent plus attacker bonuses
2. apply flat armor reduction
3. absorb the remainder with current `Guard`
4. apply the remaining damage to `HP`

This order is the only truthful live baseline.

## Hunger Rules

- Hunger is an integer in the range `0-20`.
- A run starts with hunger at `20`.
- Combat Hunger Tick spends `1` hunger at step 10 of each combat turn.
- Each node transition spends `1` hunger.
- Hunger is clamped to `0-20`; it does not underflow or overflow.
- Hunger threshold states:
  - `Hungry` at `6` or lower: apply a minor combat penalty of `-1` attack power.
  - `Starving` at `2` or lower: apply a major combat penalty of `-2` attack power.
- At `0` hunger:
  - starvation damage is guaranteed at each Combat Hunger Tick
  - the player loses `1` HP at each Combat Hunger Tick
  - the player does not die instantly just for reaching `0`
  - the run may still end from starvation damage reducing HP to `0`
- Hunger may be restored by food consumables and explicit recovery node effects such as rest or support events.
- Outside combat, hunger lives in `RunState`.
- During combat, the active turn-by-turn hunger value lives in `CombatState`.
- When combat ends, the official hunger result is committed back to `RunState`.

## Intent Rule

- first intent is shown before the first player choice
- current intent is meaningful, not cosmetic
- next intent is prepared only after the current turn resolves

## Marked Contract Target Rule

- An accepted `hamlet` contract may bind one specific combat node to one specific enemy definition.
- When the player enters that marked combat node, combat setup must use the contract-bound enemy instead of the default stage-rotation enemy selection.
- Defeating that marked enemy completes the contract, but it does not change combat exit flow:
  - non-boss marked victory still routes through the normal `Combat -> Reward` path
  - the later contract reward is claimed only by returning to the side-mission node

## Boss Phase Rule

- Boss phases are combat-local only.
- Boss phase truth lives inside `CombatState`; it does not persist into `RunState` or save payloads.
- Current truthful authored support is optional `Enemies.rules.boss_phases`.
- Phase `0` is active at combat start.
- Later phases activate when enemy HP falls at or below the authored threshold percent.
- Current prototype checks for phase changes during next-intent preparation at turn end.
  - the already revealed current intent for the active turn does not retroactively change mid-turn
  - if a threshold is crossed during the player's action, the new phase starts on the next revealed intent, not on the already-telegraphed enemy action
- On phase change:
  - the active boss intent pool switches to the new phase pool
  - intent rotation resets to the first intent in that new phase
  - a dedicated `BossPhaseChanged` feedback signal is emitted for presentation/audio hooks

## Durability Rule

- a valid attack attempt that starts resolving consumes durability
- dodge or miss does not refund durability
- durability behavior must be deterministic
- weapon durability spend comes from `Weapons.rules.stats.durability_cost_per_attack` plus `Weapons.rules.stats.durability_profile`
- current live durability profiles:
  - `sturdy` = `0.5x`
  - `standard` = `1x`
  - `fragile` = `1.5x`
  - `heavy` = `2x`
- profile scaling resolves before flat durability modifiers such as `corroded`
- `Defend` and `Use Item` do not consume weapon durability

## Equipment Rule

Current combat lanes:
- `right_hand`
- `left_hand`
- `armor`
- `belt`
- carried passive items from the backpack

Current truthful combat semantics:
- `right_hand` determines the main attack profile
- `left_hand` may be:
  - a `shield`
  - an offhand-capable `weapon`
- `armor` provides flat incoming-damage reduction before guard
- `belt` remains the narrow utility lane
- carried passive items still apply while the item remains in the backpack

Current live stat support from equipped or carried gear remains narrow:
- `incoming_damage_flat_reduction`
- `attack_power_bonus`
- `durability_cost_flat_reduction`

Current live forge integration:
- weapon `upgrade_level` adds `+1` attack power per level
- armor `upgrade_level` adds `+1` flat incoming-damage reduction per level
- those upgrade tiers live on the runtime inventory slot instance, not on content definitions

## Defend / Guard Rules

- Everyone can `Defend`.
- `Defend` raises temporary `Guard`.
- Current live config-driven baseline:
  - base defend guard: `2`
  - shield defend bonus: `+2`
  - dual-wield defend penalty: `-1`
  - guard decay rate: `0.75`
- `Guard` is combat-local only.
- `Guard` is consumed by incoming damage after armor reduction and before HP loss.
- `Defend` adds new guard on top of any carried remainder from the previous turn.
- `Guard` decays during the normal turn-end pass instead of clearing outright.
- current live turn-end carryover keeps roughly `25%` of the remaining guard; fractional carryover rounds to the nearest whole guard.
- `Guard` is not a content-authored status and does not require a `Statuses` definition.

## Left-Hand Rules

- If the left hand holds a `shield`:
  - `Defend` gains the shield guard bonus
- If the left hand holds an offhand-capable `weapon`:
  - the player gains a dual-wield attack bonus
  - the player suffers the dual-wield defend penalty
- Dual wield is currently a loadout modifier only:
  - not a second independent attack
  - not an extra hit packet
  - not a separate durability-spending engine

Current live config-driven dual-wield baseline:
- `+1` attack power on player attacks
- `-1` guard generated by `Defend`

## Equipment Lock Rule

- Combat-time gear swapping is no longer part of the canonical combat loop.
- Combat-time backpack reorder is no longer part of the canonical combat loop.
- Scenes may still show the equipment and backpack strips as live read surfaces, but not as combat-time gear-management actions.

## Attack Rules

- Attack uses the current right-hand weapon when it is functional.
- If the right-hand weapon is broken or missing, the player falls back to a weak default attack.
- Current fallback hit is `1` damage before enemy mitigation.

## Use Item Rules

- Current prototype support is intentionally narrow:
  - self-target consumables only
  - combat use limited to `heal` and `modify_hunger`
  - content-driven through `Consumables/<stable_id>.json`
- `Use Item` resolves in the same player-action window as `Attack` or `Defend`.
- After `Use Item` resolves:
  - enemy defeat is checked
  - enemy action still resolves if combat is not already over
  - turn-end hunger and intent prep still happen normally
- `Use Item` skips instead of spending the turn when no ready consumable would change HP or hunger.

## Status Rules

- Current prototype status support is intentionally narrow:
  - a small combat-local player-status pool
  - enemy intent may apply those statuses to the player
  - status ownership remains inside `CombatState`
- current canonical statuses:
  - `poison`
  - `bleed`
  - `weakened`
  - `fortified`
  - `enraged`
  - `stunned`
  - `corroded`
- `poison` currently:
  - deals `2` damage at turn end
  - lasts `2` turn-end ticks
- `bleed` currently:
  - deals `1` damage at turn end
  - lasts `3` turn-end ticks
  - does not persist into `RunState`
- `weakened` currently:
  - reduces player attack power by `2`
  - lasts `2` turn-end ticks
  - does not persist into `RunState`
- `fortified` currently:
  - grants flat incoming damage reduction while active
  - lasts `2` turn-end ticks by default
  - does not persist into `RunState`
- `enraged` currently:
  - increases player attack power while also making incoming hits harsher
  - lasts `2` turn-end ticks by default
  - does not persist into `RunState`
- `stunned` currently:
  - skips the next player action that would resolve while the status is active
  - consumes the turn; enemy action, turn-end status tick, and hunger tick still continue normally
  - does not persist into `RunState`
- `corroded` currently:
  - increases weapon durability loss on valid attack attempts while active
  - lasts `3` turn-end ticks by default
  - does not persist into `RunState`

## Dodge Rule

- dodge must be telegraphed
- dodge must be explainable to the player
- dodge does not cancel the fact that the attack attempt happened

## Simultaneous Death Priority

If edge cases produce simultaneous lethal outcomes:
- enemy defeat is checked after player action resolve
- player defeat is checked after enemy action resolve
- exact simultaneous-death resolution must follow this ordering, not ad-hoc scene logic

## Invalid States That Must Not Be Silent

- dead enemy resolving action
- negative durability
- invalid target damage application
- duplicate authoritative intent
- negative status duration
