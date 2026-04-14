# SIMPLE RPG - Content Architecture Specification

## Purpose

This file defines the canonical format and current truth boundaries for gameplay content.

## Core Principle

Most new content should be added by new data, not new special-case code.

## Status Note

- This spec distinguishes between `supported now` and `reserved later`.
- `Supported now` means the current prototype runtime, validator, and canonical content all agree.
- `Reserved later` means the field or pattern may remain part of the target architecture, but current runtime should not be treated as if it supports it.

## Content Growth Discipline

- Most future growth should come from new content data inside the current grammar.
- Adding new `Weapons`, `Consumables`, `PassiveItems`, `Rewards`, and `Enemies` inside the current grammar should be relatively easy.
- The current starter run loadout and current merchant stock slices are now content-backed through narrow dedicated families, not hardcoded runtime tables.
- Broader support-table growth still is not a generic runtime surface; widening it requires explicit implementation work.
- Adding a new resource axis, slot type, combat verb, currency, node family, trigger matrix, or progression track is not routine content work and requires explicit contract review.

## Canonical Format

- Canonical gameplay content lives in `JSON`
- Path: `ContentDefinitions/<family>/<stable_id>.json`
- One definition per file
- One stable ID per file

## Supported Families

- `Weapons`
- `Armors`
- `Belts`
- `Consumables`
- `PassiveItems`
- `Enemies`
- `Statuses`
- `Effects`
- `Rewards`
- `RouteConditions`
- `EventTemplates`
- `RunLoadouts`
- `MerchantStocks`
- `MapTemplates`
- `SideMissions`

Supported family does not mean full runtime support already exists for that family.
Families currently without authored content: Effects, RouteConditions.
`EventTemplates` is now a narrow runtime-backed canonical family:
- the current prototype places runtime-backed `event` map nodes through the procedural map v1 scaffolds
- the current runtime resolves `EventTemplates` into the dedicated `Event` flow only
- the current event surface stays fixed at 2 authored choices and the exact v1 outcome list documented below

## Required Top-Level Fields

- `schema_version`
- `definition_id`
- `family`
- `tags`
- `display`
- `rules`

## Family-Specific Required Fields

### Ordered Runtime Families

The current prototype has two runtime surfaces where authored definition order is gameplay-relevant:
- normal combat enemy rotation
- level-up passive offer windows

`authoring_order` rules:
- top-level integer field
- required for every `Enemies` definition
- required for every `PassiveItems` definition
- must be a positive integer
- must be unique within its family
- purpose:
  - locks deterministic authored order without depending on file-name sort
  - is not a display sort hint or UI label

### RunLoadouts

The current prototype uses one authored starter run loadout for new-run inventory setup.

`RunLoadouts` rules:
- `rules.weapon_definition_id`
  - required non-empty string
  - references a canonical `Weapons/` definition
- `rules.consumable_slots`
  - required array
  - each entry uses:
    - `definition_id`
    - `current_stack`
  - each `definition_id` references a canonical `Consumables/` definition
- current status:
  - runtime-backed for the starter weapon instance and starter consumables inside the shared inventory owner
  - armor, belt, and passive starter emptiness remain part of the narrow fixed starter baseline, not a broader generic authored loadout system

### MerchantStocks

The current prototype uses deterministic stage-indexed authored merchant stock definitions for merchant-node offer generation.

`MerchantStocks` rules:
- `rules.stock`
  - required non-empty array
  - array order is the current runtime offer order
  - each entry requires:
    - `offer_id`
    - `definition_id`
    - `effect_type`
    - `cost_gold`
- current supported `effect_type` values:
  - `buy_consumable`
    - requires positive integer `amount`
    - `definition_id` references `Consumables/`
  - `buy_weapon`
    - does not use `amount`
    - `definition_id` references `Weapons/`
- current status:
  - runtime-backed only for the merchant-node stock slice
  - current runtime chooses one authored stock by `RunState.stage_index`
  - labels remain derived from referenced item definitions
  - seeded shop generation or generic support-table routing remains deferred

### EventTemplates

The current prototype uses authored event templates for dedicated event-node resolution.

`EventTemplates` rules:
- `rules.choices`
  - required array with exactly `2` entries
  - each entry requires:
    - `choice_id`
    - `label`
    - `summary`
    - `effect_type`
- current supported `effect_type` values:
  - `grant_gold`
    - requires positive integer `amount`
  - `grant_xp`
    - requires positive integer `amount`
  - `heal`
    - requires positive integer `amount`
  - `modify_hunger`
    - requires non-zero integer `amount`
  - `repair_weapon`
    - does not use `amount`
  - `damage_player`
    - requires positive integer `amount`
- current status:
  - runtime-backed only for the dedicated `Event` flow slice
  - template selection is currently deterministic stage-scoped rotation over stable-id sort
  - no generic multi-effect event matrix, weighted event table, or authored event-graph routing exists in the current truthful slice

### MapTemplates

The current prototype uses authored scaffold templates for stage-local exploration topology.

`MapTemplates` rules:
- `rules.nodes`
  - required non-empty array
  - each entry requires:
    - `node_id`
    - `adjacent_node_ids`
    - and either:
      - `node_family`
      - `slot_type`
- current supported `node_family` values:
  - `start`
  - `combat`
  - `event`
  - `reward`
  - `rest`
  - `merchant`
  - `blacksmith`
  - `key`
  - `boss`
- current supported `slot_type` values:
  - `opening_support`
  - `late_primary`
  - `late_event`
  - `late_side_mission`
- current status:
  - runtime-backed for the current scaffold-based procedural map v1 slice
  - `MapRuntimeState` still owns node discovery, resolution, locking, current position, and support-node revisit state
  - current scaffold fill keeps fixed opening readability while randomizing late-slot family placement under fixed quotas
  - current scaffold fill now also resolves one dedicated `late_event` slot into the `event` node family without reducing the existing stage floor
  - current scaffold fill now also resolves one dedicated `late_side_mission` slot into the `side_mission` node family without reducing the existing stage floor
  - exact realized graph restore now lives in save data
  - legacy fixed templates remain in `MapTemplates/` only for backward-compatible schema-1 load reconstruction

### SideMissions

The current prototype uses authored side-mission definitions for contract-board detours that mark one combat target and later pay out one piece of gear.

`SideMissions` rules:
- `rules.mission_type`
  - required non-empty string
  - current supported value:
    - `hunt_marked_enemy`
- required non-empty text fields:
  - `briefing_text`
  - `accept_label`
  - `accepted_text`
  - `reminder_label`
  - `completed_text`
  - `claimed_text`
  - `claimed_label`
- `rules.reward_pool`
  - required array with at least `2` entries
  - each entry requires:
    - `offer_id`
    - `inventory_family`
    - `definition_id`
  - current supported `inventory_family` values:
    - `weapon`
    - `armor`
- current status:
  - runtime-backed only for the dedicated side-mission contract slice
  - current runtime picks exactly `1` combat node target and exactly `1` enemy definition when the contract is accepted
  - current runtime presents exactly `2` reward offers from the authored reward pool when the contract is completed
  - generic multi-step quest chains, multiple objectives, and non-gear contract rewards remain deferred

### Enemies

Enemy definitions require the standard top-level fields plus:
- `design_intent_question`

`design_intent_question` rules:
- top-level string field
- required for every `Enemies` definition
- human-readable design sentence
- purpose:
  - states what combat question the enemy is asking the player
  - exists for design review discipline, not for runtime resolution

Optional reserved enemy metadata:
- `encounter_tier`

`encounter_tier` rules:
- top-level string field if present
- allowed values:
  - `minor`
  - `elite`
- current status:
  - reserved metadata only
  - current prototype runtime ignores it for combat exit flow
  - current prototype flow contract remains `Combat victory -> Reward`

## Naming Rules

- `definition_id` uses `lower_snake_case`
- display name is separate from stable ID
- logic never depends on display text

## Display vs Rules

`display` may contain:
- name
- short description
- icon key
- presentation labels

`rules` may contain:
- stats
- behaviors
- family-specific helper blocks

## Supported-Now Matrix

| Area | Supported now | Reserved later / not truthful yet |
|---|---|---|
| top-level schema | required top-level fields, family/path match, stable ID/file-name match, non-empty `display.name` | richer schema families and reference graphs |
| event content surface | `EventTemplates.rules.choices` with exactly 2 authored choices, deterministic stage-scoped template rotation, dedicated `Event` flow resolution, and the narrow event outcome list `grant_gold` / `grant_xp` / `heal` / `modify_hunger` / `repair_weapon` / `damage_player` | weighted event pools, generic multi-effect events, authored event graph routing, or broader effect matrices |
| enemy metadata | `design_intent_question`, optional `encounter_tier` enum check | `encounter_tier`-driven flow behavior |
| enemy intent selection | first intent on setup, then sequential advance by index; boss-only optional `rules.boss_phases[*].intent_pool` with turn-end threshold swaps | weighted or authored-random intent selection |
| enemy `intent_pool` effects | `deal_damage`, narrow `apply_status` for combat-local player-status definitions using current DoT and supported stat-modifier keys | broader non-damage intent effects, buff/heal/status resolution beyond the current small player-status slice |
| behavior triggers in canonical runtime-backed content | `passive` on enemy, passive-item, armor, and belt definitions | generic trigger families such as `on_turn_start`, `on_turn_end`, `on_damage_taken`, `on_use`, `on_equip`, `on_break` |
| behavior effects in canonical runtime-backed content | `modify_stat` on passive enemy, passive-item, armor, and belt behaviors | `heal`, `apply_status`, `remove_status`, `reduce_durability`, `restore_durability`, generic multi-family effect routing |
| deterministic authored ordering | top-level `authoring_order` on `Enemies` and `PassiveItems` for the current deterministic rotation/window surfaces | file-name sort or any implicit directory order affecting gameplay |
| run-start loadout | narrow `RunLoadouts.rules.weapon_definition_id` plus `consumable_slots` for the current starter baseline | broader authored equipment/passive start profiles or a generic run-setup system |
| merchant stock | narrow `MerchantStocks.rules.stock` array with `buy_consumable` / `buy_weapon` entries | seeded shop generation, generic support-table families, or richer merchant effect types |
| map template topology | narrow `MapTemplates.rules.nodes` scaffold grammar for the current bounded procedural map v1 slice, including one dedicated `late_event` slot resolved into the runtime-backed `event` node family | broader authored graph libraries, free-form graph generation, or generic runtime-authored event-node placement |
| condition support | direct source/target dictionary comparisons with `always`, `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `has_tag`, `not_has_tag` | nested path lookups, global queries, broad computed-stat library |
| target semantics | authoring field may be present as `self` or `enemy` for current rule-block shape; first status slice implicitly targets the player from enemy intent | generic runtime target dispatch, `equipped_weapon`, arbitrary target routing |
| `random_roll_percent` | internal placeholder value injected as `100` by current combat flow | authored proc-chance contract, real RNG-driven combat authoring |
| `weight` | not supported for current canonical content | weighted intent selection |
| `use_effect` helper | `Consumables.rules.use_effect` with `trigger = on_use`, `target = self`, and `effects[*].type = heal` or `modify_hunger` for the current self-food slice | broader consumable effect families, multi-target use rules |
| status definitions | `Statuses.rules.stats.duration_turns`, `max_stacks`, plus either `damage_per_turn` or narrow `stat_modifiers` keys `attack_power_bonus` / `incoming_damage_flat_reduction` / `durability_cost_flat_reduction` / `skip_player_action` for the current combat-local player-status pool | generic status behavior blocks, broader modifier families, enemy-side status ownership, status-driven routing |
| boss phase authoring | boss-only optional `Enemies.rules.boss_phases[*]` with ordered threshold swaps and phase-local intent pools | phase-persistent save state, generic enemy phase graphs, or non-boss phase routing |
| reward generation from content | deterministic seeded reward generation through `Rewards.rules.offer_pool`, `present_count`, and `selection_mode = seeded_reward_rng` using current reward effect types plus run-level `reward_rng` continuity | richer eligibility graphs and broader generic reward-pool routing |

## Current Runtime-Backed Combat Slice

Current canonical combat-backed content should stay inside this narrow slice:

- `Enemies.rules.intent_pool[*].effects[*]`
  - current supported effect types:
    - `deal_damage`
    - `apply_status` with `params.definition_id` pointing to a canonical `Statuses/` definition that matches the current combat-local player-status slice
- `Enemies.rules.boss_phases[*]`
  - current supported fields:
    - `phase_id`
    - `display_name`
    - optional `enter_at_or_below_percent` on later phases
    - `intent_pool`
  - current runtime truth:
    - phase `0` is active at combat start
    - later phases switch only during next-intent preparation at turn end
    - switching to a new phase resets intent rotation to that phase's first intent
- `Enemies.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
    - direct stat comparison object with supported operators
- `PassiveItems.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported target: `self`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `Armors.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported target: `self`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `Belts.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported target: `self`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- weapon and enemy `rules.stats`
  - current runtime reads basic numeric combat stats from this block
- `Consumables.rules.use_effect`
  - current supported trigger: `on_use`
  - current supported target: `self`
  - current supported effect type: `heal`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `Statuses.rules.stats`
  - current supported keys:
    - `duration_turns`
    - `max_stacks`
    - `damage_per_turn`
    - `stat_modifiers.attack_power_bonus`
    - `stat_modifiers.incoming_damage_flat_reduction`
    - `stat_modifiers.durability_cost_flat_reduction`
    - `stat_modifiers.skip_player_action`
  - current canonical runtime-backed status definitions:
    - `poison`
    - `bleed`
    - `weakened`
    - `fortified`
    - `enraged`
    - `stunned`
    - `corroded`
- `Rewards.rules.offers`
  - current supported deterministic pool fields:
    - `selection_mode = seeded_reward_rng`
    - `present_count`
    - `offer_pool`
  - current supported offer fields inside `offers` / `offer_pool`:
    - `offer_id`
    - `label`
    - `effect_type`
    - `amount` for numeric reward effects
  - current supported reward effect types:
    - `heal`
    - `repair_weapon`
    - `grant_xp`
    - `grant_gold`
  - current canonical runtime-backed reward definitions:
    - `combat_victory`
    - `reward_node`
- `EventTemplates.rules.choices`
  - current supported fields:
    - `choice_id`
    - `label`
    - `summary`
    - `effect_type`
    - `amount` for numeric event outcomes
  - current supported event effect types:
    - `grant_gold`
    - `grant_xp`
    - `heal`
    - `modify_hunger`
    - `repair_weapon`
    - `damage_player`
  - current canonical runtime-backed event definitions:
    - `forest_shrine_echo`
    - `ghost_lantern_bargain`
    - `moss_waystone_tithe`
    - `trickster_stump_feast`

## Condition and State Lookup Truth

- Current resolver only reads direct keys from the provided `source_state` and `target_state` dictionaries.
- It does not support:
  - nested paths
  - object traversal
  - global lookups
  - generic computed stat registries
- Current authored content should therefore avoid pretending that rich query syntax already exists.

`random_roll_percent` note:
- the current combat flow injects `random_roll_percent = 100` into `player_state`
- this is an implementation placeholder, not a stable authoring contract
- current canonical content should not rely on authored proc-chance behavior yet

## Intent Selection Truth

- `intent_pool` defines possible intents.
- Current runtime:
  - takes the first intent on combat setup
  - rotates enemy definitions by explicit top-level `authoring_order`, not by file-name sort
  - advances by sequential index each turn
- `weight` is intentionally not part of the current truthful content surface.

## Build Engine Scope

- The current intended build engine is intentionally narrow.
- Current carried inventory capacity stays intentionally small:
  - base shared inventory: `5`
  - equipped belt bonus: `+2`
- Level-up passives consume shared inventory space and may displace the oldest carried non-active item when the bag is full.
- Current level-up passive offer generation reads `PassiveItems.authoring_order` for deterministic authored windows.
- Build identity should mostly come from equipment direction, `1-2` passive synergies, and consumable/resource planning.
- Intended synergies should stay small and linear.
- Build variety should come from strong content combinations inside the current grammar, not from expanding that grammar.

## Reserved / Deferred Patterns

These remain part of target architecture direction, but not current runtime truth:

- weighted intent selection via `weight`
- authored chance procs via `random_roll_percent`
- consumable `use_effect` resolution beyond self-target `heal` + `modify_hunger`
- generic status-tick or routing runtime beyond the current small player-status pool
- generic target routing
- generic trigger/effect matrix across all families
- weighted reward generation through `Rewards`
- weighted or tag-driven event template selection
- generic multi-effect event resolution beyond the current 2-choice / 1-outcome-per-choice slice

## Design-Rejected Growth Directions

- exponential combo scaling
- broad trigger web expansion
- second build-family explosion
- solving content problems by opening a new generic mechanic surface

## Example Reference

Runtime-aligned examples:
- `ContentDefinitions/Weapons/iron_sword.json`
- `ContentDefinitions/Enemies/bone_raider.json`
- `ContentDefinitions/Enemies/barbed_hunter.json`
- `ContentDefinitions/Enemies/drain_adept.json`
- `ContentDefinitions/Enemies/venom_scavenger.json`
- `ContentDefinitions/Consumables/minor_heal_potion.json`
- `ContentDefinitions/Consumables/wild_berries.json`
- `ContentDefinitions/Consumables/traveler_bread.json`
- `ContentDefinitions/Consumables/cured_meat.json`
- `ContentDefinitions/RunLoadouts/starter_loadout.json`
- `ContentDefinitions/MerchantStocks/basic_merchant_stock.json`
- `ContentDefinitions/MerchantStocks/stage_2_merchant_stock.json`
- `ContentDefinitions/MerchantStocks/stage_3_merchant_stock.json`
- `ContentDefinitions/MapTemplates/procedural_stage_cluster_v1.json`
- `ContentDefinitions/MapTemplates/procedural_stage_detour_v1.json`
- `ContentDefinitions/MapTemplates/fixed_stage_cluster.json` (legacy load compatibility)
- `ContentDefinitions/Statuses/poison.json`
- `ContentDefinitions/Statuses/bleed.json`
- `ContentDefinitions/Statuses/weakened.json`
- `ContentDefinitions/Rewards/combat_victory.json`
- `ContentDefinitions/Rewards/reward_node.json`
- `ContentDefinitions/EventTemplates/forest_shrine_echo.json`
- `ContentDefinitions/EventTemplates/ghost_lantern_bargain.json`
- `ContentDefinitions/EventTemplates/moss_waystone_tithe.json`
- `ContentDefinitions/EventTemplates/trickster_stump_feast.json`

Reference-only forward examples:
- none currently

Reference-only forward examples may show reserved-later schema direction.
They are not evidence that the current runtime already supports those patterns.

## Definition vs Instance

Definitions do not contain:
- current HP
- current durability
- current forge tier or `upgrade_level`
- active stacks
- current intent
- current owner slot

Those belong to runtime state.

## Tag Policy

- tags are controlled vocabulary
- tags are not a substitute for real mechanics
- tags should stay finite and reviewable
- current validator does not yet enforce a full tag vocabulary list

## Validation Expectations

Current validator actively checks:
- duplicate ID
- family/path mismatch
- stable ID/file-name mismatch
- required top-level fields
- `display.name`
- enemy `design_intent_question`
- optional `encounter_tier` enum
- reserved current-content fields such as `weight`
- current enemy rule-block shape for the prototype combat slice
- current narrow `apply_status(<dot_status_id>)` intent-effect shape
- current consumable `use_effect` shape for the prototype self-target heal/hunger slice
- current passive-item rule-block shape for the prototype level-up slice
- current `RunLoadouts.rules.weapon_definition_id` / `consumable_slots` shape for starter inventory setup
- current `MerchantStocks.rules.stock` shape for fixed merchant-node offer generation
- current `EventTemplates.rules.choices` shape for the dedicated event-node slice
- current `MapTemplates.rules.nodes` shape for the scaffold-based stage-local exploration template plus legacy fixed-template compatibility, including the dedicated `late_event` slot
- current `Statuses.rules.stats` shape for the combat-local mixed DoT/debuff pool
- current `Rewards.rules.offer_pool` / `present_count` / `selection_mode` shape for deterministic reward generation

Current validator does not yet fully validate:
- global tag vocabulary
- broad cross-family content references
- full generic trigger/effect/target support across all families
- reward/content-generation graphs
