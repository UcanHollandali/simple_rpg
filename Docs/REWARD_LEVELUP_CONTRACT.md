# SIMPLE RPG - Reward and Level-Up Contract

## Purpose

This file defines the minimum reward and progression rules for prototype and early implementation work.

## Reward Baseline

- `Reward` is a separate flow state.
- Non-boss combat victory enters `Reward` before any return to `MapExplore`.
- Current prototype reward truth is backed by a dedicated `RewardState`.
- Standard combat rewards present exactly `3` offers and the player claims `1`.
- Reward-node rewards present exactly `2` smaller offers and the player claims `1`.
- Reward choice should read as constrained salvage, not as an infinite free chest:
  - the player takes exactly one spoil or cache-find
  - the rest is considered left behind
- Reward nodes are one-shot stage interactions.
- Current prototype reward generation is content-backed and deterministic:
  - combat victory -> `Rewards/combat_victory.json`
  - reward node -> `Rewards/reward_node.json`
- Current runtime-backed generation uses authored `offer_pool` content with seeded run-level reward streaming:
  - `selection_mode = seeded_reward_rng`
  - `present_count`
  - run-level `reward_rng` continuity from `RunState`
  - context salt built from `source_context`, `current_node_id`, `stage_index`, and `current_level`
- compatibility note:
  - `current_node_index` may still appear in legacy compatibility payloads, but active reward generation truth should read only from `current_node_id`
- same `run_seed` plus the same reward-generation order now reproduces the same reward windows.

## Reward Offer Types

Current prototype reward offers may include:
- HP restore
- active weapon repair
- XP grant
- gold bundle

Deferred from the prototype reward baseline:
- `Consumables`
- `Weapons`
- `Armors`
- `Belts`
- direct status unlocks
- permanent stat-up rewards
- multi-claim reward screens

Current application path note:
- Inventory-adjacent reward claims resolve through the transitional `InventoryActions` surface against `InventoryState`, exposed via `AppBootstrap`.
- Scenes do not mutate `RunState` inventory data directly.

## Reward Eligibility Rule

- Generated rewards should be legally claimable under current inventory and equip rules.
- If a reward would create an impossible claim state, it should be filtered out before presentation.
- Reward choice is meant to be a real decision, not a UI trap caused by invalid offers.

## Reward Node Revisit Rule

- Claiming a reward from a reward node consumes that node's primary payout.
- Re-entering a resolved reward node must not generate a fresh offer set.
- Re-entering a resolved reward node must not refill previously consumed offers.
- A resolved reward node may still exist as traversable map space, but it should not reopen `Reward` with new value by default.
- This one-shot rule does not change the current non-boss combat reward cadence.

## Side Mission Reward Rule

- Side-mission contract payout is not part of the normal `Reward` flow state.
- After a marked side-mission target dies, the normal combat reward cadence still happens first.
- The contract payout is claimed only by returning to the side-mission node through `SupportInteraction`.
- Current live contract payout rules are:
  - authored side-mission content provides a reward pool of gear definitions
  - runtime presents exactly `2` random offers from that pool
  - the player claims `1`
  - the claimed gear is added to the shared carried inventory, not auto-equipped
- Current live contract payout support is intentionally narrow:
  - `Weapons`
  - `Armors`

## Hold-Vs-Use Rule

- This is a secondary consumable pressure, not the main inventory framing.
- Current reward slice does not yet generate actual consumable offers.
- Actual hold-vs-use pressure currently comes from carried consumables during combat rather than reward-table consumable picks.
- Future weapon or consumable rewards may later create freshness and hold-vs-use tradeoffs, but that is not yet part of the runtime-backed slice.
- `gold` rewards intentionally defer value into later merchant or blacksmith decisions.
- Current reward content surface is intentionally narrow:
  - `heal`
  - `repair_weapon`
  - `grant_xp`
  - `grant_gold`
- New reward content inside that effect set should not require new code.
- New reward definitions may now widen authored variety through `offer_pool` without adding new runtime code.
- New reward effect families still require explicit runtime and validator work.

## Combat Reward Topology

Current prototype truth:
- Normal combat victory enters the full `Reward` flow state.
- Boss clear is currently a stage-progression outcome, not a reward-cadence branch:
  - non-final boss clear -> `StageTransition`
  - stage `3` boss clear -> `RunEnd`
- Combat defeat still ends in `RunEnd`.
- `Reward` is currently guaranteed after non-boss combat victory; current boss clear does not enter `Reward`.
- Reward-node one-shot behavior does not change that cadence; combat victory still resolves through `Reward`.

Current topology:

```text
normal victory:
COMBAT -> REWARD -> optional LEVEL_UP -> MAP_EXPLORE

boss clear:
COMBAT -> STAGE_TRANSITION or RUN_END

any defeat:
COMBAT -> RUN_END
```

`encounter_tier` note:
- Enemy definitions may still carry `encounter_tier` metadata.
- In the current prototype, `encounter_tier` does not change combat exit flow.
- Runtime, tests, and flow docs should therefore not infer boss/non-boss reward cadence from authored `encounter_tier` alone.
- If two-tier reward cadence returns later, it must be reintroduced as explicit flow, validator, and test work rather than inferred from existing content alone.

Deferred target direction:
- A future version may still experiment with low-ceremony payouts for lighter encounters and full reward screens for higher-payoff encounters.
- That target direction is not part of the current implementation contract.
- Until new transition, state, and UX support lands, prototype truth stays:
  - non-boss combat victory -> `Reward`
  - boss clear -> `StageTransition` or `RunEnd`

## XP Sources

- XP is granted from combat victories.
- Current prototype combat victory grant is `5` XP.
- Current boss clear path does not apply a boss-specific XP bonus before `StageTransition` or `RunEnd`.
- Node rewards or event outcomes may grant explicit bonus XP when authored to do so.
- Support nodes do not grant XP by default.

## Level Threshold Baseline

- `LevelUp` is a separate flow state.
- Current prototype level-up truth is backed by a dedicated `LevelUpState`.
- Prototype XP thresholds use an increasing curve:
  - level 2: `10`
  - level 3: `25`
  - level 4: `45`
  - level 5: `70`
- Prototype target progression is roughly `3-5` level-ups across a successful full run.
- If stage pacing later proves too flat, the threshold curve may be rebalanced without changing the flow contract.

## Level-Up Offer Rules

- Each `LevelUp` presents exactly `3` choices and the player claims `1`.
- Prototype level-up choices are drawn from `PassiveItems` family definitions.
- Current prototype generation is application-owned and deterministic:
  - `LevelUpState` is built from the current authored `PassiveItems` definition set loaded from content definitions
  - seeded progression pools remain target direction, not current runtime truth
- Level-up passives are intended to strengthen a build direction, not create a large skill-bar.

## Shared Inventory Interaction

- Chosen level-up passives now occupy the same shared carried-inventory pool as weapons, armor, belts, and consumables.
- Current prototype capacity is:
  - base inventory: `5`
  - equipped belt bonus: `+2`
- Current prototype temporary rule:
  - if shared inventory is full, the oldest carried non-active item is displaced automatically
  - active equipped weapon / armor / belt are protected from this automatic displacement
  - explicit replacement UI remains deferred
- Current prototype passive acquisition resolves through `InventoryActions` against `InventoryState`, not through the `LevelUp` scene.
- Level-up does not create hidden overflow storage.
- This replacement pressure is intentional; it keeps builds small but distinct inside the shared bag.

## Reward -> Level-Up Chain

- XP is awarded from the resolved encounter outcome before flow returns to free exploration.
- `Reward` and `LevelUp` are never active at the same time.
- Official order:
  1. combat or reward-producing node resolves
  2. `Reward` state resolves
  3. XP threshold check runs
  4. if eligible, enter `LevelUp`
  5. after `LevelUp`, return to `MapExplore`
- If multiple level thresholds are crossed at once, resolve one `LevelUp` choice at a time until the current XP total is below the next threshold requirement.

## Save-Safe Rule

- `Reward` and `LevelUp` remain save-safe flow states.
- If a save occurs during either state, load must restore the actual pending choice set, not regenerate a new one from UI assumptions.
- Restored reward state must preserve:
  - `RewardState.offers`
  - claim availability
  - `RewardState.source_context`
- future reward generation after load must continue from the restored run-level `reward_rng` stream state, not restart a fresh sequence
- Restored level-up state must preserve:
  - `LevelUpState.offers`
  - `LevelUpState.current_level`
  - `LevelUpState.target_level`
  - current shared inventory capacity situation
  - replacement requirement if shared inventory is already full

## Event Contract Alignment

- Current prototype reward slice does not yet emit dedicated `RewardGenerated` or `RewardClaimed` domain events.
- If reward-specific events are added later, those names are still the intended event contract.
- Current prototype level-up slice does not yet emit dedicated `LevelUpOffered` or `LevelUpChosen` domain events.
- If progression-specific events are added later, those names are still the intended event contract.
