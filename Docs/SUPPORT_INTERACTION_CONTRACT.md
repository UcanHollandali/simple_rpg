# SIMPLE RPG - Support Interaction Contract

## Purpose

This file defines the minimum support-node rules for prototype and early implementation work.

## Prototype Support Types

Prototype support interactions include:
- `rest`
- `merchant`
- `blacksmith`
- `side_mission`

Deferred from the prototype baseline:
- dedicated healer nodes
- item selling or buyback
- barter economy
- support-node ambush or trap variants

## Economy Baseline

- The prototype run economy uses a single currency: `gold`.
- `gold` comes from combat rewards, explicit reward-node payouts, and event outcomes that grant currency.
- The prototype baseline does not allow item selling for `gold`.
- Merchant purchases and blacksmith repairs spend from the same `gold` pool.
- This shared spend pool is intentional. It creates preparation pressure between immediate power, sustain, and durability recovery.
- `side_mission` is outside that shared spend pool:
  - accepting a contract costs no `gold`
  - claiming a contract reward does not spend `gold`

## Merchant Rules

- `merchant` is included in the prototype baseline.
- Merchant stock may include:
  - `Consumables`
  - `Weapons`
  - `Armors`
- `Belts` and `PassiveItems` are deferred from the prototype merchant pool.
- Current prototype merchant stock is built from authored item definitions plus deterministic stage-indexed authored offer tables.
- Run-seeded support tables remain target direction, not current runtime truth.
- Prototype merchant stock shows exactly `3` offers.
- Merchant stock is fixed once that stage-local merchant node state is generated.
- A player may buy multiple offers in one merchant visit if:
  - they can afford the cost
  - shared inventory and equip rules allow the result
- Bought offers become unavailable for the rest of that stage-local merchant node state.
- Current implemented merchant slice uses:
  - `Consumables`
  - `Weapons`
- Current live authored merchant stock currently includes:
  - stage `1`
    - `Traveler Bread`
    - `Quick-Clot Poultice`
    - `Splitter Axe`
  - stage `2`
    - `Roadside Stew Jar`
    - `Forager Knife`
    - `Watchman Mace`
  - stage `3`
    - `Hunter Stew`
    - `Salvage Cleaver`
    - `Thorn Rapier`
- `Armors` remain contract-allowed and are now authored as equipment content, but they are not currently present in live merchant stock.

## Blacksmith Rules

- `blacksmith` is included in the prototype baseline.
- The prototype blacksmith now offers exactly `3` top-level services:
  - open carried weapon tempering targets
  - open carried armor reinforcement targets
  - repair the active weapon to full durability
- Blacksmith tempering and reinforcement target carried shared-inventory items, not stage-authored replacement gear.
- Current live blacksmith upgrade rules are runtime-owned:
  - weapon tempering costs `8` gold and adds `+1` attack to the chosen weapon instance
  - armor reinforcement costs `6` gold and adds `+1` defense to the chosen armor instance
  - repair costs `5` gold and restores the active weapon's durability to full
- Blacksmith target selection may include active or non-active carried weapon / armor items.
- Weapon and armor upgrade tiers are runtime instance state on the carried slot (`upgrade_level`), not authored replacement definitions.
- Repair restores the active weapon's durability to full.
- All blacksmith services cost `gold`.
- Blacksmith services are support actions, not content reward drops.
- One blacksmith visit grants one applied service, then the node is considered resolved.
- Revisiting that resolved blacksmith node must not grant another service.
- Repair should stay cheaper than a full upgrade step.

## Side Mission Rules

- `side_mission` is included in the current prototype baseline as a dedicated contract-board stop.
- Each stage currently contains exactly `1` `side_mission` node.
- Current live side-mission content is authored in `ContentDefinitions/SideMissions/*.json`.
- The current runtime-backed mission type is `hunt_marked_enemy`.
- Current live side-mission loop:
  - enter the contract node
  - accept the contract
  - one unresolved combat node on the current map becomes the marked target
  - combat setup for that marked node overrides the usual enemy rotation with one specific target enemy
  - after that marked enemy dies, the contract returns to the source node
  - returning to the contract node presents exactly `2` random gear offers from the authored contract reward pool
  - the player claims `1`
- Current live contract reward pool support is intentionally narrow:
  - `weapon`
  - `armor`
- Side-mission reward gear is added to the shared carried inventory through `InventoryActions`; it is not auto-equipped.
- Side-mission contract state is node-local runtime state:
  - `mission_definition_id`
  - `mission_status`
  - `target_node_id`
  - `target_enemy_definition_id`
  - `reward_offers`
- One side-mission node may reopen while its contract is still active:
  - `offered` -> may open for acceptance
  - `accepted` -> may reopen for reminder/info
  - `completed` -> may reopen for reward claim
  - `claimed` -> must not grant new value and later revisit must stay traversal-only

## Rest Rules

- `rest` is included in the prototype baseline.
- A rest node is a safe haven in the prototype baseline; it does not contain ambush or trap risk.
- Rest spends `4` hunger.
- Rest heals `8` HP.
- Rest does not restore weapon durability.
- One rest visit grants one rest action, then the node is considered resolved.
- Revisiting that resolved rest node must not grant another heal or hunger trade-off.

## Revisit Semantics

- Current implemented merchant slice supports repeated buys inside one visit and save/load restore inside that active visit.
- Leaving the merchant ends the current `SupportInteractionState`.
- Support nodes remain one-shot at the node level in the current slice.
- After the player leaves a resolved `rest`, `merchant`, or `blacksmith`, revisiting that node must stay pure traversal.
- `side_mission` is the current exception:
  - accepted and completed contracts may reopen their contract state on revisit
  - claimed contracts must fall back to pure traversal
- A resolved support-node revisit must not reopen `SupportInteraction`, reroll stock, or mint fresh value.
- Merchant stock and one-shot action consumption still persist inside the already-open support visit and inside save/load of that active visit.

## Resolution Flow

- `MapExplore` now opens `SupportInteraction` directly for support-node families and `side_mission`.
- `SupportInteraction` presents the valid actions for that node:
  - `buy`
  - `reinforce armor`
  - `repair`
  - `temper weapon`
  - `rest`
  - `accept contract`
  - `claim contract reward`
  - `leave`
- Merchant interactions may contain repeated `buy` decisions until the player leaves, runs out of valid purchases, or stock is exhausted.
- Blacksmith may open one in-visit target-selection step before the final applied service resolves the node.
- Rest and blacksmith interactions still resolve once and then exit.
- Side-mission interactions resolve in two phases:
  - accept phase
  - later claim phase after the marked target dies
- The current runtime no longer inserts a separate `NodeResolve` bridge shell before the support screen opens.
- Re-entering a fully resolved support node must not mint another support payout.
- Re-entering a fully resolved support node must now stay in `MapExplore`; it is no longer an inert reopen shell.
- When the interaction officially ends, flow returns to `MapExplore`.

## Save-Safe Rule

- `SupportInteraction` remains a save-safe state.
- If a save occurs inside `SupportInteraction`, load must restore the real pending interaction state, not reconstruct it from UI assumptions.
- The restored support state must preserve:
  - source node id
  - support node type
  - generated offers and prices
  - sold or unavailable offers
  - repair availability
  - blacksmith target-selection mode and current target page when that visit is active
  - side-mission definition, status, marked target, and pending reward offers when that visit is active
  - whether the node has already consumed its one-shot action
- Load inside an active visit must therefore preserve merchant stock and one-shot support consumption instead of reconstructing fresh actions.
- This save-safe rule applies to the already-open `SupportInteraction` visit. It does not imply that a resolved support node may later reopen after the player has already returned to `MapExplore`.

## Content-Driven Rule

- Merchant stock should be derived from JSON content definitions plus seeded support tables.
- Current prototype note:
  - the implemented merchant slice derives offer payloads and labels from authored item definitions plus deterministic stage-indexed authored stock tables
  - seeded support-table generation is still deferred
- Item definitions remain the canonical source for item rules, display, and family.
- Support interaction content may filter by family, tags, and weighted offer tables, but should not duplicate item rules inside UI logic.
