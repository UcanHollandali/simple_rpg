# SIMPLE RPG - Content Balance Tracker

Last updated: 2026-04-17

This file is reference-only.
It is a current content inventory and balance-reading snapshot, not a gameplay authority.
If it conflicts with `GDD.md`, a rule contract, or live definitions under `ContentDefinitions/`, those authority sources win.

## Purpose

Use this file to answer:
- what content currently exists
- what mechanics are live right now
- which items and enemies are actually in the current prototype slice
- where the balance pressure currently comes from
- what was intentionally removed from the old baseline

## Core Run And Balance Baseline

- run length target: `3` stages
- run start:
  - HP: `60`
  - hunger: `20`
  - gold: `0`
  - level: `1`
  - XP: `0`
- starter loadout:
  - right hand: `iron_sword`
  - backpack: `wild_berries x1`
- backpack baseline:
  - base backpack size: `5`
  - belts add authored backpack capacity
- current combat XP:
  - normal non-boss victory: `6`
- current level thresholds:
  - level `2`: `10`
  - level `3`: `25`
  - level `4`: `45`
  - level `5`: `70`

## Live Mechanics Snapshot

### Combat

- top-level actions:
  - `Attack`
  - `Defend`
  - `Use Item`
- the old temporary mitigation action is removed
- damage order:
  - raw damage
  - armor reduction
  - guard absorption
  - HP loss
- defend / guard:
  - base defend guard: `2`
  - shield defend bonus: `+2`
  - dual-wield defend penalty: `-1`
  - turn-end guard decay rate: `75%`
  - effective carryover target: about `25%`
- dual wield:
  - offhand weapon bonus: `+1` attack
  - offhand weapon penalty: `-1` defend guard
- hunger combat penalty:
  - hunger `6` or lower: `-1` attack
  - hunger `2` or lower: `-2` attack
  - hunger `0`: lose `1` HP at combat hunger tick
- fallback attack:
  - broken or missing weapon -> `1` damage before mitigation

### Attrition And Economy

- movement cost: `1` hunger per step
- starvation on movement:
  - if a move leaves hunger at `0`, lose `1` HP
- support costs:
  - rest: `3` hunger, heal `10`
  - blacksmith weapon temper: `7` gold
  - blacksmith armor reinforce: `5` gold
  - blacksmith repair: `4` gold
- current economy pressure:
  - merchant prices were tightened in the 2026-04-17 pre-playtest balance pass
  - generic reward gold was slightly reduced in the same pass

### Rewards And Progression

- combat victory reward:
  - `3` offers, claim `1`
- reward node:
  - `2` offers, claim `1`
- level up:
  - `3` perk offers, claim `1`
- perks are permanent for the current run
- passive items are backpack-carried bonuses, not level-up progression

### Map And Route Pressure

- each stage currently realizes:
  - `1` start
  - `6` non-boss combat
  - `1` planned event
  - `1` reward node
  - `1` hamlet
  - `2` support nodes
  - `1` key
  - `1` boss
- roadside interruptions:
  - max `3` per stage
  - preserve destination resolution after the interruption closes

## Removed / Retired Baseline

- removed mechanic:
  - the old temporary mitigation action
- removed combat loop assumptions:
  - combat-time gear swap as a normal player-facing loop
  - combat-time backpack reorder as a normal player-facing loop
- removed live flow role:
  - `NodeResolve` as the active map-to-interaction bridge
- removed live music lane:
  - old `temp_01` music set

## Current Content Counts

- Weapons: `13`
- Shields: `5`
- Armors: `6`
- Belts: `7`
- PassiveItems: `16`
- Consumables: `22`
- ShieldAttachments: `5`
- QuestItems: `3`
- Enemies: `24`
- EventTemplates: `28`
- MerchantStocks: `9`
- SideMissions: `10`
- CharacterPerks: `15`
- Rewards: `2`
- MapTemplates: `7`

## Active Player Content

### Weapons

| id | name | dmg | durability | profile | notes |
|---|---|---:|---:|---|---|
| `iron_sword` | Iron Sword | 6 | 20 | sturdy | starter weapon |
| `hedge_sabre` | Hedge Sabre | 5 | 24 | sturdy | durable early merchant / hunt reward sword |
| `watchman_mace` | Watchman Mace | 5 | 28 | sturdy | durable slower blunt lane |
| `salvage_cleaver` | Salvage Cleaver | 5 | 40 | sturdy | extreme durability lane |
| `bandit_hatchet` | Bandit Hatchet | 5 | 16 | fragile | offhand-capable attack option |
| `briar_knife` | Briar Knife | 4 | 17 | fragile | offhand-capable status-leaning knife |
| `forager_knife` | Forager Knife | 6 | 18 | standard | stronger offhand-capable knife |
| `warden_spear` | Warden Spear | 6 | 24 | sturdy | reliable late spear |
| `moonspur_pike` | Moonspur Pike | 7 | 22 | sturdy | quest reward polearm |
| `gatebreaker_club` | Gatebreaker Club | 7 | 20 | heavy | high-damage, high-wear blunt lane |
| `splitter_axe` | Splitter Axe | 8 | 14 | heavy | high burst, fragile merchant axe |
| `emberhook_blade` | Emberhook Blade | 8 | 18 | standard | quest reward weapon |
| `thorn_rapier` | Thorn Rapier | 10 | 10 | fragile | glass-edge finisher weapon |

### Shields

| id | name | passive effect |
|---|---|---|
| `weathered_buckler` | Weathered Buckler | no extra passive stat; pure shield lane |
| `watchman_shield` | Watchman Shield | no extra passive stat; balanced shield lane |
| `thornwood_buckler` | Thornwood Buckler | `+1 attack` |
| `pilgrim_board` | Pilgrim Board | `-1 durability cost` |
| `gatewall_kite_shield` | Gatewall Kite Shield | `+1 flat damage reduction` |

### Armors

| id | name | passive effect |
|---|---|---|
| `watcher_mail` | Watcher Mail | `+1 flat damage reduction` |
| `patched_buffcoat` | Patched Buffcoat | `+1 reduction`, `-1 durability cost` |
| `trailwarden_cloak` | Trailwarden Cloak | `+1 reduction`, `-1 durability cost` |
| `bastion_plate` | Bastion Plate | `+2 reduction` |
| `gatebound_cuirass` | Gatebound Cuirass | `+2 reduction`, `-1 attack` |
| `gravehide_plates` | Gravehide Plates | `+2 reduction` |

### Belts

| id | name | backpack bonus |
|---|---|---:|
| `wayfarer_frame` | Wayfarer Frame | 1 |
| `duelist_knot` | Duelist Knot | 2 |
| `packhook_sash` | Packhook Sash | 2 |
| `scavenger_strap` | Scavenger Strap | 2 |
| `trailhook_bandolier` | Trailhook Bandolier | 2 |
| `caravan_harness` | Caravan Harness | 3 |
| `provisioner_belt` | Provisioner Belt | 3 |

### Passive Items

#### Offense

- `iron_grip_charm`: `+1 attack`
- `razor_relic`: `+2 attack`, `-1 reduction`
- `rushnail_loop`: `+2 attack`, `-1 reduction`, `-1 durability cost`
- `whetstone_loop`: `+1 attack`, `-1 durability cost`
- `wolfspur_ring`: `+3 attack`, `-1 reduction`, `+1 durability cost`

#### Defense / Survival

- `sturdy_wraps`: `+1 reduction`
- `lean_pack_token`: `+1 attack`, `+1 reduction`
- `marchwarden_talisman`: `+1 reduction`, `-1 durability cost`
- `packrat_clasp`: `+1 reduction`, `-2 durability cost`
- `scavenger_straps`: `+1 reduction`, `-1 durability cost`
- `hearth_knot_charm`: `-1 durability cost`
- `tempered_binding`: `-1 durability cost`

#### Heavy Tradeoff

- `bulwark_reliquary`: `+2 reduction`, `-1 attack`
- `gate_oak_idol`: `+2 reduction`, `-1 attack`
- `salvager_rivet`: `-3 durability cost`, `-1 attack`
- `scrap_ledger_clasp`: `-2 durability cost`, `-1 attack`

### Shield Attachments

- `briar_spikes`: `+1 attack`
- `lantern_crest`: `-1 durability cost`
- `pilgrim_seal`: `+1 reduction`
- `reinforced_rim_lining`: `+1 reduction`
- `warden_boss_plate`: `+1 reduction`

### Consumables

#### Healing Only

- `minor_heal_potion`: heal `12`
- `stout_tonic`: heal `18`
- `last_draught`: heal `20`
- `quick_clot_poultice`: heal `10`
- `clotleaf_dressing`: heal `9`

#### Food / Mixed Sustain

- `wild_berries`: heal `4`, hunger `-3`
- `traveler_bread`: heal `8`, hunger `-2`
- `war_biscuit`: heal `4`, hunger `-2`
- `field_broth`: heal `6`, hunger `-2`
- `hunter_stew`: heal `8`, hunger `-4`
- `pilgrim_broth_flask`: heal `12`, hunger `-1`
- `embergrain_loaf`: heal `8`, hunger `-3`
- `embersalt_ration`: heal `5`, hunger `-3`
- `roadside_stew_jar`: heal `6`, hunger `-2`
- `salt_pork_strip`: heal `3`, hunger `-4`
- `salted_crumbs`: heal `2`, hunger `-2`
- `cured_meat`: heal `14`, hunger `-1`

#### Hunger Only

- `forager_tea`: hunger `-4`
- `lantern_tea`: hunger `-5`
- `pepper_bark_lozenge`: hunger `-3`

#### Repair

- `binding_resin`: repair active weapon
- `tinker_oil`: repair active weapon

## Active Enemy Content

### Stage 1 Minor Enemies

| id | hp | base dmg | dodge | role |
|---|---:|---:|---:|---|
| `ash_gnawer` | 14 | 2 | 0 | tutorial skirmisher |
| `lantern_cutpurse` | 16 | 2 | 10 | evasive early brigand |
| `skeletal_hound` | 16 | 3 | 20 | high-dodge bleed beast |
| `carrion_runner` | 19 | 3 | 10 | attrition scavenger |
| `mossback_ram` | 20 | 2 | 0 | early guard / armor check |

### Stage 2 Minor Enemies

| id | hp | base dmg | dodge | role |
|---|---:|---:|---:|---|
| `briar_alchemist` | 22 | 3 | 0 | poison / corroded attrition |
| `cutpurse_duelist` | 22 | 4 | 15 | evasive bleed pressure |
| `chain_trapper` | 24 | 4 | 0 | control / bleed combo |
| `grave_chanter` | 24 | 3 | 0 | stun timing check |
| `thornwood_warder` | 26 | 3 | 0 | shielded defense test |

### Stage 3 Minor Enemies

| id | hp | base dmg | dodge | role |
|---|---:|---:|---:|---|
| `ember_harrier` | 25 | 4 | 15 | evasive poison threat |
| `rotbound_reaver` | 28 | 5 | 10 | bleed executioner |
| `dusk_pikeman` | 30 | 5 | 0 | soldier guard test |
| `ashen_sapper` | 32 | 5 | 0 | corrosive endurance threat |
| `gatebreaker_brute` | 34 | 6 | 0 | telegraphed high-threat brute |

### Live Stage Bosses

| stage | id | hp | base dmg | balance read |
|---|---|---:|---:|---|
| 1 | `tollhouse_captain` | 34 | 5 | early teachable pattern boss; now slightly longer |
| 2 | `chain_herald` | 40 | 5 | status + timing boss; now more endurance pressure |
| 3 | `briar_sovereign` | 46 | 6 | final attrition boss; now more solving pressure |

### Legacy / Non-Active Boss Content

- `gate_warden`
  - still exists as valid content and test surface
  - not part of the current live stage boss breadth
  - keep in mind when reading enemy counts so you do not overestimate live boss variety

## Status Pool

| id | effect |
|---|---|
| `poison` | `2` damage for `2` turn-end ticks |
| `bleed` | `1` damage for `3` turn-end ticks |
| `weakened` | `-2 attack` for `2` turn-end ticks |
| `fortified` | `+2 reduction` for `2` turn-end ticks |
| `enraged` | `+2 attack`, `-1 reduction` for `2` turn-end ticks |
| `stunned` | skips next player action while active |
| `corroded` | `+1` durability cost for `3` turn-end ticks |

## Rewards And Economy Surface

### Generic Combat Reward Gold

- stage 1 brigand gold roll: `7`
- stage 2 brigand gold roll: `10`
- stage 3 brigand gold roll: `13`

### Reward Node Gold

- loose coins cache: `6`

### Merchant Price Bands

- stage 1 price band:
  - cheapest live slot: `6`
  - most expensive live slot: `14`
- stage 2 price band:
  - cheapest live slot: `9`
  - most expensive live slot: `20`
- stage 3 price band:
  - cheapest live slot: `11`
  - most expensive live slot: `27`

### Blacksmith Prices

- temper weapon: `7`
- reinforce armor: `5`
- repair active weapon: `4`

## Reward Pools

### Combat Victory Pool

The current combat-victory reward pool intentionally mixes:
- `Field Provisions`
- `Quick Refit`
- `Scavenger's Find`

Current stage read:
- stage 1:
  - bread
  - repair
  - early shield / belt
  - small brigand gold
- stage 2:
  - biscuit or ration sustain
  - repair
  - mid gear: `bandit_hatchet`, `briar_knife`, `pilgrim_board`, `patched_buffcoat`, `packhook_sash`, `packrat_clasp`, `sturdy_wraps`
  - medium brigand gold
- stage 3:
  - resin / oil repair
  - late gear: `gatebreaker_club`, `warden_spear`, `gatewall_kite_shield`, `bastion_plate`, `caravan_harness`
  - large brigand gold

### Reward Node Pool

Current reward-node pool is intentionally smaller and cleaner:
- stage 1:
  - bread
  - resin
  - early belt / shield
  - small gold
- stage 2:
  - biscuit
  - repair
  - `packrat_clasp`
  - `sturdy_wraps`
  - `briar_knife`
  - `patched_buffcoat`
  - `packhook_sash`
- stage 3:
  - resin / oil
  - `warden_spear`
  - `gatewall_kite_shield`
  - `bastion_plate`
  - `caravan_harness`

## Merchant Stock Catalog

### Stage 1 Merchant Pools

- `basic_merchant_stock`
  - `traveler_bread` `6`
  - `binding_resin` `8`
  - `watchman_shield` `13`
- `stage_1_merchant_stock_roadpack`
  - `quick_clot_poultice` `7`
  - `trailhook_bandolier` `14`
  - `thornwood_buckler` `12`
- `stage_1_merchant_stock_scout`
  - `embersalt_ration` `7`
  - `hedge_sabre` `12`
  - `wayfarer_frame` `10`

### Stage 2 Merchant Pools

- `stage_2_merchant_stock`
  - `war_biscuit` `9`
  - `bandit_hatchet` `18`
  - `pilgrim_board` `20`
- `stage_2_merchant_stock_forgegear`
  - `tinker_oil` `10`
  - `patched_buffcoat` `20`
  - `packhook_sash` `17`
- `stage_2_merchant_stock_kit`
  - `forager_tea` `9`
  - `briar_knife` `19`
  - `sturdy_wraps` `20`

### Stage 3 Merchant Pools

- `stage_3_merchant_stock`
  - `gatebreaker_club` `25`
  - `gatewall_kite_shield` `26`
  - `lean_pack_token` `27`
- `stage_3_merchant_stock_bulwark`
  - `hunter_stew` `11`
  - `warden_spear` `24`
  - `watcher_mail` `25`
- `stage_3_merchant_stock_convoy`
  - `lantern_tea` `12`
  - `bastion_plate` `26`
  - `caravan_harness` `23`

## Side Mission Catalog

### Stage 1 Hamlet Pool

- `trail_contract_hunt`
  - rewards: `bandit_hatchet` / `trailhook_bandolier` / `war_biscuit`
- `watchpath_hunt`
  - rewards: `thornwood_buckler` / `field_broth` / `8 gold`
- `ridge_contract_hunt`
  - rewards: `hedge_sabre` / `wayfarer_frame` / `embersalt_ration`

### Stage 2 Hamlet Pool

- `deliver_supplies`
  - rewards: `provisioner_belt` / `pilgrim_seal` / `hunter_stew`
- `carry_forge_parcel`
  - rewards: `packrat_clasp` / `binding_resin` / `9 gold`
- `lantern_scout_recovery`
  - rewards: `patched_buffcoat` / `packrat_clasp` / `binding_resin` / `10 gold`

### Stage 3 Hamlet Pool

- `rescue_missing_scout`
  - rewards: `watchman_shield` / `sturdy_wraps` / `hunter_stew` / `10 gold` / `hearth_knot_charm` / `warden_boss_plate`
- `recover_bell_scout`
  - rewards: `watcher_mail` / `sturdy_wraps` / `field_broth` / `12 gold`
- `bring_proof`
  - rewards: `briar_spikes` / `scavenger_strap` / `binding_resin` / `12 gold`
- `ash_barricade_proof`
  - rewards: `bastion_plate` / `caravan_harness` / `tinker_oil` / `14 gold`

## Event Catalog

### Planned Trail Events

#### Stage 1

- `watchfire_ruin_cache`
- `weathered_signal_tree`
- `woodsmoke_bunkhouse`

#### Stage 2

- `wardenless_gate_toll`
- `woundvine_altar`

#### Stage 3

- `wayfarer_grave_goods`
- `wayhouse_ember_offer`
- `wrecked_bell_tower`

#### Shared / generic planned events still in the live pool

- `forest_shrine_echo`
- `ghost_lantern_bargain`
- `moss_waystone_tithe`
- `trickster_stump_feast`
- `zz_ash_tree_ledger`
- `zz_dry_well_cache`
- `zz_watch_post_embers`

### Roadside Encounters

#### Stage 1

- `yellowed_traveler_wreck`
- `zz_old_road_sign`

#### Stage 2

- `whispering_barricade`
- `yellow_road_cutpurses`
- `yew_guard_hut`
- `zz_broken_bridge_crossing`
- `zz_suspicious_merchant`

#### Stage 3

- `wrenched_supply_cart`
- `zigzag_wolf_sign`
- `zz_silent_grave_mound`

#### Shared / generic roadside pool

- `zz_barrow_crows`
- `zz_split_axle_verge`
- `zz_sunken_toll_fire`

## Character Perk Catalog

### Offense

- `thorn_grip_training`: `+1 attack`
- `whetstone_discipline`: `+1 attack`, `-1 durability cost`
- `razor_instinct`: `+2 attack`, `-1 reduction`
- `rushnail_method`: `+2 attack`, `-1 reduction`, `-1 durability cost`
- `wolfspur_frenzy`: `+3 attack`, `-1 reduction`, `+1 durability cost`

### Defense

- `sturdy_stance`: `+1 reduction`
- `bulwark_doctrine`: `+2 reduction`, `-1 attack`
- `gate_oak_posture`: `+2 reduction`, `-1 attack`

### Survival

- `scavenger_stride`: `+1 reduction`, `-1 durability cost`
- `tempered_maintenance`: `-1 durability cost`
- `lean_kit_training`: `+1 attack`, `+1 reduction`

### Economy / Route

- `ledger_method`: `-2 durability cost`, `-1 attack`
- `marchwarden_drill`: `+1 reduction`, `-1 durability cost`
- `packrat_routine`: `+1 reduction`, `-2 durability cost`
- `salvager_eye`: `-3 durability cost`, `-1 attack`

## Current Balance Read

### What Is Strong

- item/content breadth is now large enough that route and build choices matter
- stage 1 teaches the loop with moderate enemy damage and a readable boss
- stage 2 introduces real control/status checks
- stage 3 now asks for actual preparation, not just incidental snowball
- hamlet rewards still feel like special value instead of generic filler

### Current Pressure Points

- the player still starts with only one small sustain tool and no starting armor/shield
- stage 2-3 shop buys are now meaningfully more expensive than casual gold picks
- generic gold choices are weaker than before, so free-salvage value is less likely to brute-force the economy
- late bosses are now longer fights, so durability and consumable timing matter more

### What Still Needs Real Playtest

- whether stage 1 merchant access now comes too late relative to early damage taken
- whether stage 2 economy feels tense instead of stingy
- whether stage 3 boss endurance is satisfying instead of dragging
- whether reward-node top-end gear still appears too freely
- whether offensive perk stacking plus late shields still creates a dominant solved line
