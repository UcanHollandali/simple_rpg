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
- `Brace`
- `Use Item`

Contextual shared-inventory actions:
- click carried `weapon`, `armor`, or `belt` card to equip or unequip it
- click carried `consumable` card to use it directly
- drag carried inventory cards to reorder them without spending the turn

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

- An accepted `side_mission` may bind one specific combat node to one specific enemy definition.
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

## Equipped Armor And Belt Rule

- Current equipped combat lanes now include:
  - `weapon`
  - `armor`
  - `belt`
  - carried passive items from shared inventory
- `armor` and `belt` resolve through the same narrow authored behavior slice already used by passive items:
  - `trigger = passive`
  - `target = self`
  - `effect.type = modify_stat`
- Current truthful supported combat stats for equipped armor and belts are:
  - `incoming_damage_flat_reduction`
  - `attack_power_bonus`
  - `durability_cost_flat_reduction`
- Armor is the dedicated defense lane:
  - the intended baseline use is flat incoming damage reduction
  - that reduction applies before `Brace` halves the remaining hit
- Current live forge integration:
  - weapon `upgrade_level` adds `+1` attack power per level
  - armor `upgrade_level` adds `+1` flat incoming-damage reduction per level
  - those upgrade tiers live on the carried inventory slot instance, not on content definitions
- Belt is the narrow utility lane:
  - the current truthful baseline is passive combat utility such as attack-power adjustment or durability-cost reduction
  - equipped belts also add `+2` shared carried-inventory capacity outside combat
- Equipped armor and belt are active combat truth when their inventory instances are non-empty.
- Starter loadout still begins with both lanes empty.

## Equipment Swap Rules

- The shared inventory strip may swap or unequip carried `weapon`, `armor`, or `belt` items during combat.
- The interaction surface is direct card click on the shared inventory strip, not a hidden scene-only command.
- Swapping equipment resolves in the same player-action window as `Attack`, `Brace`, and `Use Item`.
- Swapping equipment consumes the turn:
  - enemy defeat is checked after the swap resolves
  - enemy action still resolves if combat is not already over
  - turn-end hunger and intent prep still happen normally
- Swapping equipment does not consume weapon durability by itself.
- The newly chosen carried slot becomes the active combat-local equipped slot immediately for preview, enemy-hit mitigation, and the next attack.
- Clicking the currently equipped `weapon`, `armor`, or `belt` card is an unequip action for that family.
- Unequipping the active belt must fail instead of silently overflowing carried capacity when current used slots would exceed the post-belt limit.
- During active combat, equipped weapon / armor / belt slot selection is combat-local truth on `CombatState`; the chosen slot ids are committed back to `InventoryState` when combat ends.

## Inventory Reorder Rule

- Dragging a carried inventory card to another shared slot lane reorders `inventory_slots` truth.
- Combat-time reorder is UI/inventory management only:
  - it does not consume the player turn
  - it does not trigger enemy action
  - it does not change hunger by itself
- If combat later commits back into `RunState`, the reordered shared inventory order is committed too.

## Brace Rules

- `Brace` reduces incoming damage by `50%` for the current turn.
- Current prototype rounds the reduced damage up, so `Brace` does not turn a positive hit into zero damage by itself.
- In the baseline turn order, that protection matters against the enemy action that resolves later in the same turn.
- `Brace` does not deal damage, reflect damage, counterattack, or grant dodge.
- `Brace` does not consume weapon durability.
- `Brace` does not prevent Hunger Tick or any other normal turn-end resolution.
- `Brace` is resolved inline as an explicit combat rule, not as a content-defined status.
- The baseline brace behavior does not require a `Statuses` definition under `ContentDefinitions/Statuses/`.
- Repeated `Brace` on consecutive turns is allowed, but the effect is always the same and does not stack across turns.
- If the enemy does not threaten meaningful damage on that turn, `Brace` should usually be weaker than `Attack` or `Use Item`. This is intentional.

## Use Item Rules

- Current prototype support is intentionally narrow:
  - one starter consumable stack
  - self-target food/consumable effects limited to `heal` and `modify_hunger`
  - content-driven through `Consumables/<stable_id>.json`
- `Use Item` resolves in the same player-action window as `Attack` or `Brace`.
- After `Use Item` resolves:
  - enemy defeat is checked
  - enemy action still resolves if combat is not already over
  - turn-end hunger and intent prep still happen normally
- `Use Item` does not consume weapon durability.
- Clicking a combat consumable card is the primary current interaction:
  - if that consumable would heal HP or restore hunger, it resolves immediately and consumes the turn
  - if it would not change HP or hunger right now, it fails without spending the turn
- The `Use Item` button remains a fallback action surface for the current ready consumable, but direct card click is the clearer primary path.
- `Use Item` skips instead of spending the item when no ready self-target consumable would change HP or restore hunger.
- Generic item effects beyond self-target `heal` / `modify_hunger`, ally targets, enemy targets, and status-driven consumables remain reserved for later runtime support.

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
  - is authored with normal status duration semantics, so enemy-applied stun must survive the same-turn end pass to matter on the next player choice
  - does not persist into `RunState`
- `corroded` currently:
  - increases weapon durability loss on valid attack attempts while active
  - lasts `3` turn-end ticks by default
  - does not persist into `RunState`
- Status application currently resolves from enemy intent effects, not from a generic effect router.
- Status ticking currently resolves during the combat turn-end pass, before hunger tick.
- Status cleanup removes expired entries in the same turn-end pass after the tick is applied.
- Current truthful status modifier support includes:
  - `attack_power_bonus`
  - `incoming_damage_flat_reduction`
  - `durability_cost_flat_reduction`
  - `skip_player_action`
- Status-driven consumables, enemy-side status ownership, and broad target routing remain reserved for later runtime support.

## Dodge Rule

- dodge must be telegraphed
- dodge must be explainable to the player
- dodge does not cancel the fact that the attack attempt happened

## Fallback Attack Rule

If the active weapon breaks:
- the player does not become unable to act
- the player falls back to a weak default attack
- fallback is intentionally inferior to a proper weapon

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

## Combat Information Model

### Purpose

This section defines what the player should know during combat.

### Main Rule

Combat should be hard because of decision pressure, not hidden information.

The intended player reaction after a loss is:
"I made the wrong call,"
not
"the game hid something important."

### Minimum Visible Information

The first playable version must show:
- player HP
- player hunger
- active weapon
- critical durability state
- player statuses
- enemy name or type
- enemy HP
- enemy current intent
- enemy important statuses
- three core player actions

### Intent Visibility

- the first enemy intent is shown before the player's first turn
- intent shows action family
- intent shows relative threat strength
- optional short side hint is allowed
- full future scripting is not shown

### Trait and Tendency Hints

Short trait hints are allowed when they improve readability.

Examples:
- armored
- heal-prone
- dodge-prone
- crit-resistant

These hints should answer:
"What kind of enemy is this?"
They should not answer:
"What exactly will it do three turns from now?"

### Information Layers

#### Primary

Always visible:
- HP
- intent
- actions
- critical statuses
- critical durability warning

#### Secondary

Easy-access helper:
- short trait hints
- short item explanations
- short status explanations
- compact combat log

#### Tertiary

Optional deeper explanation:
- expanded log
- extra enemy notes

### Combat Log Role

The combat log is a support layer, not the main information channel.

It should help answer:
- what just happened
- why damage or status changed
- why durability dropped

It should not replace:
- intent display
- HP display
- action availability

### Hidden By Default

Do not show by default:
- full resolver internals
- full RNG tables
- full future enemy script
- technical IDs
- hidden weighting tables

### Boss Clarity Rule

Bosses may show clearer threat telegraphs than normal enemies.
They still should not reveal full script order or phase internals by default.
