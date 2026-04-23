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

Current player-facing combat inventory rules:
- direct consumable card click is allowed and consumes the turn when the item would change HP or hunger
- exactly `1` narrow combat-time `SwapHand` action is legal per player turn:
  - only `right_hand` and `left_hand`
  - only when that hand has an eligible carried spare candidate
  - confirming the swap spends the full turn
  - `armor` and `belt` stay locked
- backpack reorder is locked during combat

## Technique MVP (Live Prompt 27 Surface)

- Combat now includes exactly `1` additional combat command family: `Technique`.
- `Technique` is a conditional main-action surface, not a persistent `2`-slot skill bar.
- The player keeps exactly `1` equipped technique between combats in the current run until a later training choice replaces it.
- If no technique is equipped, combat keeps the current `Attack` / `Defend` baseline plus direct consumable click behavior.
- If a technique is equipped, combat must expose one explicit tap target for it in the main combat action area.
- That tap target must not hide in the log, tooltip, or inventory drawer.
- The current live first-pass technique set is:
  - `cleanse_pulse` via `remove_statuses` plus a small guard pulse
  - `sundering_strike` via `attack_ignore_armor`
  - `blood_draw` via `attack_lifesteal`
  - `echo_strike` via `prime_next_attack`
- First-pass techniques stay constrained to the current combat identity:
  - single-target
  - turn-spending
  - readable without exact prediction math
  - no hand-slot swap dependency
- First-pass usage-limit policy is `once_per_combat`.
- Using a technique spends the turn and marks that technique spent for the rest of the current combat.
- The once-per-combat spent flag resets at combat start.
- Technique definitions are authored under `ContentDefinitions/Techniques/*.json`.
- `CombatResolver` owns technique effect resolution.
- `CombatFlow` owns technique availability, once-per-combat consumption, and turn-spend orchestration.
- UI and presenter surfaces may only format existing technique truth; they must not resolve legality, effect math, or command ownership.
- Still deferred from this MVP:
  - `stun`
  - multiple simultaneously carried techniques
  - a persistent top-level skill bar
  - broader loadout/save continuity
  - hand-slot swap dependent technique lanes

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

## Current Enemy Pattern Slice

- Current live enemy authoring still stays inside ordered sequential `intent_pool` lines plus boss-only optional phase-local intent pools.
- Prompt 24 Pattern Pack A now uses that narrow slice to ask clearer authored questions without opening a broader enemy-intent system:
  - `light -> heavy` timing reads through enemies such as `mossback_ram` and `dusk_pikeman`
  - `status pressure -> punish` reads through enemies such as `skeletal_hound` and `grave_chanter`
  - `greed / resource punish` reads through enemies such as `ashen_sapper` and `chain_trapper`
  - `boss phase spike` reads through `tollhouse_captain`
- These patterns are authored through ordered intent lines, threat tiers, and boss-phase swaps only.
- Current combat truth still does not include:
  - weighted intent selection
  - true multi-hit packets
  - enemy self-buff / self-guard / armor-up runtime
  - enemy-side status ownership
  - reactive trigger-based enemy routing

## Advanced Enemy Intent Expansion Target (Prompt 30, Not Live Yet)

This section records the approved advanced-intent spec target.
It is not current live runtime truth yet.

- Advanced enemy intents are a new combat rule surface, not a content-only continuation.
- Intended new advanced intent families are:
  - `setup_pass`
    - spends the current enemy action on preparation rather than immediate damage
    - may arm exactly `1` combat-local prepared follow-up payload on `enemy_self`
    - must author an explicit expiry window for that prepared follow-up
  - `multi_hit`
    - resolves an authored ordered packet list inside one enemy action
    - each packet re-runs the normal damage order independently
  - `self_state`
    - applies enemy-self guard, armor-up, or temporary stat-up changes
    - does not widen target routing beyond `enemy_self`
  - `enemy_status`
    - applies, refreshes, or removes enemy-owned statuses on `enemy_self`
- Intended target routing remains narrow even after this expansion:
  - `player`
  - `enemy_self`
- No ally, random-target, or route-wide targeting is part of this first advanced-intent target.
- Intended runtime owners are explicit:
  - `CombatState` owns combat-local enemy prepared-follow-up truth, enemy guard, enemy temporary armor/stat modifiers, enemy status instances, and any revealed packet-plan truth that survives across turns
  - `CombatResolver` owns packet-by-packet enemy-action resolution plus enemy-self guard / buff / armor / status application
  - `CombatFlow` owns lifetime ticking, expiry, reveal snapshot assembly, boss-phase interaction, and advanced combat domain-event emission
  - UI / presenter surfaces remain formatting-only; they do not own advanced intent legality or effect math
- Intended boss-phase behavior stays explicit:
  - an already revealed current intent still does not mutate mid-turn
  - boss-phase checks still happen during next-intent preparation after the full turn resolves
  - prepared follow-up state, enemy guard, enemy temporary armor/stat modifiers, and enemy-owned statuses persist across a boss-phase change only through their authored remaining duration
  - a boss-phase change alone does not silently clear or rewrite those combat-local enemy states
- Intended telegraph requirements are explicit:
  - text and icon truth remain primary
  - `setup_pass` must telegraph both the current setup turn and the prepared follow-up family/window
  - `multi_hit` must telegraph hit count and ordered pressure; it must not fake mitigation math the runtime does not own yet
  - `self_state` must visibly expose gained enemy guard / armor / attack-up truth on the enemy card and subsequent intent read
  - `enemy_status` must visibly expose active enemy-status chips/badges and remaining duration/stack truth once runtime owns that information
- Intended combat-domain-event prerequisite is explicit:
  - later implementation is expected to add at least one new combat-local domain-event family for enemy self-state changes
  - later implementation is expected to add at least one new combat-local domain-event family for multi-hit packet progression
- Still deferred even with this advanced-intent target:
  - weighted intent selection
  - reactive routing based on the player's just-chosen action
  - broader target routing beyond `player` / `enemy_self`
  - combat save-safe continuation

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
- `Defend` and combat consumable use do not consume weapon durability

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
  - base defend guard: `3`
  - shield defend bonus: `+2`
  - dual-wield defend penalty: `-1`
  - defend extra hunger cost: `+1`
  - guard decay rate: `0.75`
- `Guard` is combat-local only.
- `Guard` is consumed by incoming damage after armor reduction and before HP loss.
- `Defend` adds new guard on top of any carried remainder from the previous turn.
- `Guard` decays during the normal turn-end pass instead of clearing outright.
- current live turn-end carryover keeps roughly `25%` of the remaining guard; fractional carryover rounds to the nearest whole guard.
- a full `Defend` turn now spends the normal `1` hunger tick plus `+1` extra hunger as its explicit tempo cost.
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

## Combat Inventory Legality Rule

- Combat keeps the equipment and backpack strips as live read surfaces.
- Direct consumable click remains legal when the item would change HP or hunger.
- Narrow `SwapHand` is now legal for eligible `right_hand` or `left_hand` spares only.
- `armor`, `belt`, and backpack reorder remain locked during combat.
- Scenes must not turn the combat equipment strip into a full backpack or broad gear-management surface.

## Hand-Slot Swap (Live Prompt 29 Surface)

- Combat now includes exactly `1` additional combat command family: `SwapHand`.
- `SwapHand` stays inside the existing `Combat` state. It does not add a new main flow state, modal equipment scene, or backpack-management mode.
- Opening or closing the narrow swap surface is UI-only. Confirming a swap candidate is the turn-consuming action.
- Exactly `1` hand-slot swap may resolve per player turn.
- A confirmed hand-slot swap spends the full turn:
  - enemy action still resolves if combat is not already over
  - turn-end hunger and intent prep still happen normally
- Approved slot coverage is narrow:
  - `right_hand`
  - `left_hand`
- Explicitly excluded from the first pass:
  - `armor`
  - `belt`
  - backpack reorder
  - multi-slot-in-one-action swap
- Candidate-source rules are explicit:
  - `right_hand` candidates may only come from carried backpack `weapon` slots that are valid for `right_hand`
  - `left_hand` candidates may only come from carried backpack `shield` slots or carried backpack `weapon` slots that are valid for `left_hand`
- No combat swap affordance should appear for a slot when that slot has no eligible spare candidate in the carried backpack.
- The swap surface must stay narrow:
  - visually tied to the main combat action area or the equipment strip
  - may use a compact anchored tray, inline row, or anchored drawer
  - must not expand into a full backpack manager, freeform gear screen, or second modal
- Choosing a swap candidate swaps that backpack entry into the targeted hand slot and returns the displaced equipped hand item to the backpack through the existing inventory-owner legality rules.
- Broken-weapon timing is explicit:
  - an attack that causes a weapon to break still resolves first
  - if the right-hand weapon breaks during that attack, the broken state matters on the following player turn
  - fallback attack and swap availability are evaluated on that following turn, not during the already-resolving attack
- Once a swap resolves, the newly equipped hand item becomes the active combat truth immediately for:
  - subsequent enemy-action resolution in that same turn
  - combat previews and legality checks
  - later turns
- Shield and dual-wield consequences stay inside the current rule contract:
  - swapping a `shield` into `left_hand` only changes the existing shield defend bonus lane
  - swapping an offhand-capable `weapon` into `left_hand` only changes the existing dual-wield attack/defend modifier lane
  - no second attack packet
  - no second durability-spending engine
  - no broader stance system
- Combat UI wording expectations are explicit:
  - say which hand is being swapped
  - say when the current right-hand weapon is broken and the fallback hit is `1`
  - keep `armor`, `belt`, and backpack order plainly locked in combat copy
  - do not hide swap access behind tooltip-only or log-only messaging

## Attack Rules

- Attack uses the current right-hand weapon when it is functional.
- If the right-hand weapon is broken or missing, the player falls back to a weak default attack.
- Current fallback hit is `1` damage before enemy mitigation.

## Consumable Use Rules

- Current prototype support is intentionally narrow:
  - self-target consumables only
  - combat use limited to `heal` and `modify_hunger`
  - content-driven through `Consumables/<stable_id>.json`
- direct consumable card click is the canonical combat-time use surface
- there is no separate top-level `Use Item` button in the canonical combat layout
- a combat consumable resolves in the same player-action window as `Attack` or `Defend`
- after a combat consumable resolves:
  - enemy defeat is checked
  - enemy action still resolves if combat is not already over
  - turn-end hunger and intent prep still happen normally
- combat consumable use skips instead of spending the turn when no ready consumable would change HP or hunger

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
