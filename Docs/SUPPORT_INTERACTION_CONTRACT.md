# SIMPLE RPG - Support Interaction Contract

## Purpose

This file defines the minimum support-node rules for prototype and early implementation work.

## Prototype Support Types

Prototype support interactions include:
- `rest`
- `merchant`
- `blacksmith`
- `hamlet`

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
- `hamlet` is outside that shared spend pool:
  - accepting a contract costs no `gold`
  - claiming a contract reward does not spend `gold`

## Merchant Rules

- `merchant` is included in the prototype baseline.
- Merchant stock may include:
  - `Consumables`
  - `Weapons`
  - `Shields`
  - `Armors`
  - `Belts`
  - `PassiveItems`
- Current prototype merchant stock is built from authored item definitions plus deterministic stage-local authored offer tables.
- Current live runtime resolves exactly `1` merchant stock definition from the current stage-local authored pool using deterministic run-seeded selection.
- Prototype merchant stock shows exactly `3` offers.
- Merchant stock is fixed once that stage-local merchant node state is generated.
- A player may buy multiple offers in one merchant visit if:
  - they can afford the cost
  - backpack capacity and equipment-slot rules allow the result
- Current live backpack-overflow rule for merchant item purchases:
  - merchant buys do not silently evict an older backpack item
  - if the chosen purchase would need a new backpack slot, runtime opens a discard prompt against the current backpack
  - discarding one carried non-quest item finalizes the purchase
  - choosing `Leave Item` cancels that purchase attempt and keeps the interaction open
- Bought offers become unavailable for the rest of that stage-local merchant node state.
- Current implemented merchant slice uses:
  - `Consumables`
  - `Weapons`
  - `Shields`
  - `Armors`
  - `Belts`
  - `PassiveItems`
- Current live authored merchant stock pools currently include:
  - stage `1`
    - `basic_merchant_stock`
    - `stage_1_merchant_stock_roadpack`
    - `stage_1_merchant_stock_scout`
  - stage `2`
    - `stage_2_merchant_stock`
    - `stage_2_merchant_stock_kit`
    - `stage_2_merchant_stock_forgegear`
  - stage `3`
    - `stage_3_merchant_stock`
    - `stage_3_merchant_stock_bulwark`
    - `stage_3_merchant_stock_convoy`

## Blacksmith Rules

- `blacksmith` is included in the prototype baseline.
- The prototype blacksmith now offers exactly `3` top-level services:
  - open carried weapon tempering targets
  - open carried armor reinforcement targets
  - repair the active weapon to full durability
- Blacksmith tempering and reinforcement target runtime item instances from the canonical inventory owner, not stage-authored replacement gear.
- Current live blacksmith upgrade rules are runtime-owned:
  - weapon tempering costs `7` gold and adds `+1` attack to the chosen weapon instance
  - armor reinforcement costs `5` gold and adds `+1` defense to the chosen armor instance
  - repair costs `4` gold and restores the active weapon's durability to full
- Blacksmith target selection may include active or non-active carried weapon / armor items.
- Weapon and armor upgrade tiers are runtime instance state on the carried slot (`upgrade_level`), not authored replacement definitions.
- Repair restores the active weapon's durability to full.
- All blacksmith services cost `gold`.
- Blacksmith services are support actions, not content reward drops.
- One blacksmith visit grants one applied service, then the node is considered resolved.
- Revisiting that resolved blacksmith node must not grant another service.
- Repair should stay cheaper than a full upgrade step.

## Hamlet Rules

- `hamlet` is included in the current prototype baseline as a dedicated contract-board stop.
- Each stage currently contains exactly `1` `hamlet` node.
- Current live runtime derives one stage-toned hamlet personality instead of saving extra node payload:
  - stage `1` -> `pilgrim`
  - stage `2` -> `frontier`
  - stage `3` -> `trade`
- Current live side-quest content is authored in `ContentDefinitions/SideMissions/*.json`.
- Current runtime-backed hamlet mission hooks are:
  - `hunt_marked_enemy`
  - `deliver_supplies`
  - `rescue_missing_scout`
  - `bring_proof`
- Current authored content now exercises all four hamlet hook types across the live `SideMissions` definitions.
- Current live runtime resolves exactly `1` hamlet request definition from the current stage-local authored pool using deterministic run-seeded selection plus a narrow personality bias.
- Current stage-local hamlet request pools are:
  - stage `1`
    - `Hunt Marked Brigand`
    - `Clear the Watchpath`
    - `Clear the Ridge Cut`
  - stage `2`
    - `Deliver Supplies`
    - `Carry the Forge Parcel`
    - `Recover the Lantern Scout`
  - stage `3`
    - `Rescue Missing Scout`
    - `Recover the Bell Scout`
    - `Bring Proof`
    - `Bring Proof from the Barricade`
- Current live `hunt_marked_enemy` loop:
  - enter the hamlet board
  - accept the request
  - one unresolved combat node on the current map becomes the marked target
  - combat setup for that marked node overrides the usual enemy rotation with one specific target enemy
  - after that marked enemy dies, the request returns to the hamlet source node
  - returning to the hamlet board presents exactly `2` deterministic run-seeded authored reward offers with a narrow hamlet-personality bias
  - the player claims `1`
- Current live personality read is intentionally narrow:
  - `frontier` leans toward harsher contract tone plus weapon / proof / aggressive payout reads
  - `pilgrim` leans toward safer-road / rescue tone plus shield / survival payout reads
  - `trade` leans toward practical-contract tone plus belt / passive / gold payout reads
- This bias stays inside the authored stage-local pools; it does not open a new quest grammar or a new weighted generic support router.
- Current non-combat hamlet hook semantics are also runtime-backed:
  - `deliver_supplies` marks a valid non-combat node, adds the configured quest cargo to the backpack on acceptance, removes that cargo on arrival, then returns the request to the hamlet
    - if that quest cargo would need a new backpack slot, the same discard prompt applies before the contract is accepted
  - `rescue_missing_scout` marks a valid non-combat or combat objective and completes on arrival or victory without minting extra cargo
  - `bring_proof` marks a valid objective and, once completed, grants the configured proof quest item for the return trip
- Current live hamlet reward pool support now includes authored:
  - `grant_gold`
  - `weapon`
  - `shield`
  - `armor`
  - `belt`
  - `passive`
  - `shield_attachment`
  - `consumable`
- Inventory-backed hamlet rewards are added through `InventoryActions`; they are not auto-equipped.
- Inventory-backed hamlet reward claims now use the same discard prompt when the backpack is full; they do not silently evict older carried loot.
- Hamlet side-quest state is node-local runtime state:
  - the runtime/save helper surface still uses legacy `side_mission_*` naming for compatibility
  - `mission_definition_id`
  - `mission_type`
  - `mission_status`
  - `target_node_id`
  - `target_enemy_definition_id`
  - `quest_item_definition_id`
  - `reward_offers`
- One hamlet node may reopen while its side quest is still active:
  - `offered` -> may open for acceptance
  - `accepted` -> may reopen for reminder/info
  - `completed` -> may reopen for reward claim
  - `claimed` -> must not grant new value and later revisit must stay traversal-only

## Rest Rules

- `rest` is included in the prototype baseline.
- A rest node is a safe haven in the prototype baseline; it does not contain ambush or trap risk.
- Rest spends `3` hunger.
- Rest heals `10` HP.
- Rest does not restore weapon durability.
- One rest visit grants one rest action, then the node is considered resolved.
- Revisiting that resolved rest node must not grant another heal or hunger trade-off.

## Revisit Semantics

- Current implemented merchant slice supports repeated buys inside one visit and save/load restore inside that active visit.
- Leaving the merchant ends the current `SupportInteractionState`.
- Support nodes remain one-shot at the node level in the current slice.
- After the player leaves a resolved `rest`, `merchant`, or `blacksmith`, revisiting that node must stay pure traversal.
- `hamlet` is the current exception:
  - accepted and completed side quests may reopen their contract state on revisit
  - claimed side quests must fall back to pure traversal
- that hamlet reopen-vs-traversal phase split is intentional in the current prototype and should stay documented as such
- A resolved support-node revisit must not reopen `SupportInteraction`, reroll stock, or mint fresh value.
- Merchant stock and one-shot action consumption still persist inside the already-open support visit and inside save/load of that active visit.

## Resolution Flow

- `MapExplore` now opens `SupportInteraction` directly for support-node families and `hamlet`.
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
- Hamlet interactions resolve in two phases:
  - accept phase
  - later claim phase after the marked objective resolves
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
  - hamlet request definition, mission type, marked target, quest item hook, and pending reward offers when that visit is active
  - whether the node has already consumed its one-shot action
- Load inside an active visit must therefore preserve merchant stock and one-shot support consumption instead of reconstructing fresh actions.
- This save-safe rule applies to the already-open `SupportInteraction` visit. It does not imply that a resolved support node may later reopen after the player has already returned to `MapExplore`.

## Content-Driven Rule

- Merchant stock should be derived from JSON content definitions plus deterministic stage-local authored stock pools.
- Current prototype note:
  - the implemented merchant slice derives offer payloads and labels from authored item definitions plus deterministic run-seeded stage-local authored stock pools
  - current live runtime still resolves exactly one authored merchant stock definition per visit; it does not use weighted generic stock routing
- Item definitions remain the canonical source for item rules, display, and family.
- Support interaction content may filter by family, tags, and weighted offer tables, but should not duplicate item rules inside UI logic.
